import { prisma } from "../lib/prisma";
import { inngest } from "./client";
import { NonRetriableError } from "inngest";
import { GoogleGenerativeAI } from "@google/generative-ai";
import { notifyUsers } from "./notifyUsers";

const genAI = new GoogleGenerativeAI(process.env.GEMINI_KEY!);

export const admitPatient = inngest.createFunction(
  { id: "admit-patient" },
  { event: "patient/admitted" },
  async ({ event, step }) => {
    // get data
    const { patientId, admissionReason } = event.data;

    //  setp1: Fetch data(patient, doctors, nurses(available))
    const data = await step.run("fetch-hospital-data", async () => {
      // patient
      const patient = await prisma.user.findUnique({ where: { id: patientId } });
      // doctors and nurses
      const doctors = await prisma.user.findMany({
        where: { role: "doctor", status: "active" },
      });
      const nurses = await prisma.user.findMany({
        where: { role: "nurse", status: "active" },
      });
      return { patient, doctors, nurses };
    });

    // throw error if no patient,doctor(s) and nurse(s) found
    if (
      !data.patient ||
      data.doctors.length === 0 ||
      data.nurses.length === 0
    ) {
      throw new NonRetriableError(
        "Missing patient or active staff to complete triage.",
      );
    }

    // step2: ask gemini ai to assign staff based on their roles/specialization
    const aiAssignment = await step.run("ai-triage", async () => {
      // model
      const model = genAI.getGenerativeModel({
        model: "gemini-3-flash-preview",
        generationConfig: { responseMimeType: "application/json" },
      });
      //  patient data
      const patientDataStr = `Age: ${data.patient!.age}, Gender: ${data.patient!.gender}, History: ${data.patient!.medicalHistory}. Issue: ${admissionReason}`;
      // doctor data
      const doctorDataStr = data.doctors
        .map(
          (d) =>
            `ID: ${d.id}, Name: ${d.name}, Spec: ${d.specialization}, Dept: ${d.department}`,
        )
        .join("\n");
      // nurse data
      const nurseDataStr = data.nurses
        .map((n) => `ID: ${n.id}, Name: ${n.name}, Dept: ${n.department}`)
        .join("\n");

      // prompt
      const prompt = `
        You are an expert Hospital Triage AI. Match this patient with the best Doctor and Nurse.
        PATIENT: ${patientDataStr}
        AVAILABLE DOCTORS: ${doctorDataStr}
        AVAILABLE NURSES: ${nurseDataStr}

        Respond ONLY with a valid JSON object:
        {
          "doctorId": "id",
          "doctorName": "name",
          "nurseId": "id",
          "nurseName": "name",
          "reasoning": "Clinical reasoning for this assignment."
        }
      `;
      // results
      const result = await model.generateContent(prompt);
      // result in text format
      const text = result.response.text();
      // Clean up markdown just in case Gemini adds ```json
      const cleanJson = text
        .replace(/```json/g, "")
        .replace(/```/g, "")
        .trim();
      return JSON.parse(cleanJson);
    });

    // step 3:update patient record with assigned doctor and nurse
    const updatedPatient = await step.run("update-database", async () => {
      // payload
      const updatePayload = {
        status: "admitted",
        admissionReason,
        assignedDoctorId: aiAssignment.doctorId,
        assignedDoctorName: aiAssignment.doctorName,
        assignedNurseId: aiAssignment.nurseId,
        assignedNurseName: aiAssignment.nurseName,
        triageReasoning: aiAssignment.reasoning,
      };
      return prisma.user.update({
        where: { id: patientId },
        data: updatePayload,
      });
    });

    // later we will notify doctor and nurse
    // create notification
    // for testing copy doctor and nurse id
    await step.run("send-notification", async () => {
      await notifyUsers(
        aiAssignment.doctorId,
        aiAssignment.nurseId,
        "Patient Assigned",
        `You have been assigned to a new patient: ${updatedPatient?.name}`,
        `/patient/${patientId}`,
        "assignment",
      );
    });
    return { success: true, aiAssignment, updatedPatient };
  },
);

export const analyzeXRayJob = inngest.createFunction(
  { id: "analyze-xray" },
  { event: "labResult/created" },
  async ({ event, step }) => {
    const { labResultId, imageUrl, bodyPart } = event.data;

    // STEP 1: Download the image and convert to Base64 (Gemini requires this)
    const imageBase64 = await step.run("fetch-image", async () => {
      const response = await fetch(imageUrl);
      const arrayBuffer = await response.arrayBuffer();
      return Buffer.from(arrayBuffer).toString("base64");
    });

    // STEP 2: Call Google Gemini Vision
    const aiAnalysis = await step.run("call-gemini", async () => {
      // gemini-1.5-flash is fast and excellent at multimodal (image) tasks
      const model = genAI.getGenerativeModel({
        model: "gemini-3-flash-preview",
      });

      const prompt = `You are an expert AI radiologist. Analyze this ${bodyPart} x-ray image. Provide a structured response: \n1. Key Findings\n2. Potential Abnormalities\n3. Summary.\nKeep it clinical, concise, and end with a disclaimer.`;

      const imageParts = [
        {
          inlineData: {
            data: imageBase64,
            mimeType: "image/jpeg", // Assuming JPEG/PNG
          },
        },
      ];

      const result = await model.generateContent([prompt, ...imageParts]);
      return result.response.text();
    });

    // STEP 3: Update the Database
    const updatedLab = await step.run("update-db", async () => {
      const updatedLabResult = await prisma.labResult
        .update({
          where: { id: labResultId },
          data: { aiAnalysis, status: "analyzed" },
        })
        .catch(() => null);

      if (!updatedLabResult) {
        throw new NonRetriableError("Lab result not found");
      }

      // 2. Manually fetch the Patient
      const patient = await prisma.user.findUnique({
        where: { id: updatedLabResult.patient },
        omit: { emailVerified: true },
      });

      // 3. Attach the patient data to the result (mimicking populate)
      return {
        ...updatedLabResult,
        patient: patient || null, // Replace the ID with the actual user object
      };
    });

    // STEP 4: Notify Frontend & Assigned Staff
    await step.run("send-notification", async () => {
      await notifyUsers(
        (updatedLab?.patient as any)?.assignedDoctorId?.toString() || "",
        (updatedLab?.patient as any)?.assignedNurseId?.toString() || "",
        "Lab Result Analyzed",
        `Your lab result for ${updatedLab?.testType} has been analyzed.`,
        `/patients`,
        "lab_result",
      );
    });
    // later socket.io
  },
);

export const addChargeToInvoice = inngest.createFunction(
  { id: "add-medical-charge" },
  { event: "billing/charge.added" },
  async ({ event, step }) => {
    const { patientId, description, priceInCents } = event.data;
    if (!patientId || !priceInCents) {
      throw new NonRetriableError("Missing required charge information.");
    }

    const invoiceId = await step.run("create-invoice", async () => {
      // 1. Find the active draft invoice or create a new one
      const existing = await prisma.invoice.findFirst({
        where: { patientId, status: "draft" },
      });

      if (existing) {
        await prisma.$transaction([
          prisma.invoiceItem.create({
            data: {
              invoiceId: existing.id,
              description,
              quantity: 1,
              unitPrice: priceInCents,
              totalPrice: priceInCents,
            },
          }),
          prisma.invoice.update({
            where: { id: existing.id },
            data: { totalAmount: { increment: priceInCents } },
          }),
        ]);
        return existing.id;
      }

      const created = await prisma.invoice.create({
        data: {
          patientId,
          totalAmount: priceInCents,
          items: {
            create: [
              {
                description,
                quantity: 1,
                unitPrice: priceInCents,
                totalPrice: priceInCents,
              },
            ],
          },
        },
      });
      return created.id;
    });

    return { success: true, invoiceId };
  },
);
