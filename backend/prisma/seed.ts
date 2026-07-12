import { auth } from "../src/lib/auth";
import { prisma } from "../src/lib/prisma";

const ADMIN_EMAIL = "admin@askmusawo.co.ug";
const ADMIN_PASSWORD = "ChangeMe123!";
const SEED_PASSWORD = "DoctorPass123!";
const REVIEWER_PASSWORD = "PatientPass123!";

const DOCTORS = [
  {
    name: "Dr. Grace Nakato",
    email: "grace.nakato@askmusawo.co.ug",
    specialization: "Internal Medicine",
    department: "Internal Medicine",
    consultationFee: 30000,
    hospitalName: "Mulago National Referral Hospital",
    bio: "Internal medicine specialist with over 10 years of experience managing chronic conditions like hypertension and diabetes.",
  },
  {
    name: "Dr. Joseph Okello",
    email: "joseph.okello@askmusawo.co.ug",
    specialization: "Pediatrics",
    department: "Pediatrics",
    consultationFee: 25000,
    hospitalName: "Nsambya Hospital",
    bio: "Pediatrician passionate about child nutrition, immunization, and early childhood development.",
  },
  {
    name: "Dr. Patricia Namutebi",
    email: "patricia.namutebi@askmusawo.co.ug",
    specialization: "Orthopedic Surgery",
    department: "Orthopedics",
    consultationFee: 50000,
    hospitalName: "Case Hospital",
    bio: "Orthopedic surgeon specialising in sports injuries, fractures, and joint replacement.",
  },
  {
    name: "Dr. Ibrahim Wasswa",
    email: "ibrahim.wasswa@askmusawo.co.ug",
    specialization: "Cardiology",
    department: "Cardiology",
    consultationFee: 45000,
    hospitalName: "Uganda Heart Institute",
    bio: "Cardiologist focused on preventive heart care, hypertension, and cardiac rehabilitation.",
  },
  {
    name: "Dr. Susan Achieng",
    email: "susan.achieng@askmusawo.co.ug",
    specialization: "Obstetrics & Gynecology",
    department: "Maternity",
    consultationFee: 35000,
    hospitalName: "Mengo Hospital",
    bio: "OB/GYN dedicated to safe motherhood, antenatal care, and women's reproductive health.",
  },
  {
    name: "Dr. Sarah Nabwire",
    email: "sarah.nabwire@askmusawo.co.ug",
    specialization: "Emergency Medicine",
    department: "Emergency",
    consultationFee: 20000,
    hospitalName: "Mulago National Referral Hospital",
    bio: "Emergency physician experienced in acute care, trauma response, and urgent triage.",
  },
];

// Seed reviewers + per-doctor ratings so the featured carousel and review
// lists have real data on a fresh install.
const REVIEWERS = [
  { name: "Amina Kirabo", email: "amina.kirabo@example.com" },
  { name: "David Mugisha", email: "david.mugisha@example.com" },
  { name: "Esther Atim", email: "esther.atim@example.com" },
];

const REVIEW_TEXTS: Record<string, { rating: number; comment: string }[]> = {
  "grace.nakato@askmusawo.co.ug": [
    { rating: 5, comment: "Very thorough and patient. Explained my condition clearly." },
    { rating: 5, comment: "Best doctor I've consulted. Highly recommend." },
    { rating: 4, comment: "Helpful consultation, slight wait before she joined." },
  ],
  "joseph.okello@askmusawo.co.ug": [
    { rating: 5, comment: "Wonderful with my daughter. Calm and reassuring." },
    { rating: 4, comment: "Good advice on feeding and immunization schedule." },
  ],
  "patricia.namutebi@askmusawo.co.ug": [
    { rating: 4, comment: "Clear explanation of my knee injury and options." },
    { rating: 4, comment: "Professional and knowledgeable." },
  ],
  "ibrahim.wasswa@askmusawo.co.ug": [
    { rating: 5, comment: "Took time to review my ECG and history properly." },
    { rating: 3, comment: "Good doctor but the consultation felt rushed." },
  ],
  "susan.achieng@askmusawo.co.ug": [
    { rating: 5, comment: "Made my antenatal visit so comfortable. Thank you!" },
    { rating: 4, comment: "Very supportive and answered all my questions." },
  ],
  "sarah.nabwire@askmusawo.co.ug": [
    { rating: 4, comment: "Fast response when I needed urgent advice." },
  ],
};

const MEDICATIONS = [
  { name: "Paracetamol 500mg", category: "Analgesic", unit: "tablet", stock: 500, reorderLevel: 100, unitPrice: 50 },
  { name: "Amoxicillin 250mg", category: "Antibiotic", unit: "capsule", stock: 300, reorderLevel: 80, unitPrice: 150 },
  { name: "Ibuprofen 400mg", category: "Analgesic", unit: "tablet", stock: 400, reorderLevel: 100, unitPrice: 80 },
  { name: "Oral Rehydration Salts", category: "General", unit: "sachet", stock: 200, reorderLevel: 50, unitPrice: 100 },
  { name: "Vitamin C 1000mg", category: "Supplement", unit: "tablet", stock: 250, reorderLevel: 60, unitPrice: 60 },
  { name: "Metformin 500mg", category: "Antidiabetic", unit: "tablet", stock: 180, reorderLevel: 40, unitPrice: 120 },
];

async function upsertAuthUser(name: string, email: string, password: string) {
  const existing = await prisma.user.findUnique({ where: { email } });
  if (existing) return existing;

  const result = await auth.api.signUpEmail({
    body: { name, email, password },
  });
  return prisma.user.findUniqueOrThrow({ where: { id: result.user.id } });
}

async function main() {
  console.log("Seeding admin...");
  const admin = await upsertAuthUser("Admin", ADMIN_EMAIL, ADMIN_PASSWORD);
  await prisma.user.update({ where: { id: admin.id }, data: { role: "admin", status: "active" } });

  console.log("Seeding doctors...");
  const doctorsByEmail = new Map<string, { id: string; name: string }>();
  for (const doctor of DOCTORS) {
    const user = await upsertAuthUser(doctor.name, doctor.email, SEED_PASSWORD);
    await prisma.user.update({
      where: { id: user.id },
      data: {
        role: "doctor",
        status: "active",
        specialization: doctor.specialization,
        department: doctor.department,
        consultationFee: doctor.consultationFee,
        hospitalName: doctor.hospitalName,
        bio: doctor.bio,
      },
    });
    doctorsByEmail.set(doctor.email, { id: user.id, name: doctor.name });
  }

  console.log("Seeding reviewers...");
  const reviewers: { id: string; name: string }[] = [];
  for (const reviewer of REVIEWERS) {
    const user = await upsertAuthUser(reviewer.name, reviewer.email, REVIEWER_PASSWORD);
    reviewers.push({ id: user.id, name: reviewer.name });
  }

  console.log("Seeding completed appointments + reviews...");
  for (const [doctorEmail, reviews] of Object.entries(REVIEW_TEXTS)) {
    const doctor = doctorsByEmail.get(doctorEmail);
    if (!doctor) continue;
    for (let i = 0; i < reviews.length; i++) {
      const reviewer = reviewers[i % reviewers.length]!;
      const review = reviews[i]!;

      const existing = await prisma.review.findFirst({
        where: { doctorId: doctor.id, patientId: reviewer.id, comment: review.comment },
      });
      if (existing) continue;

      const daysAgo = 7 + i * 5;
      const appointment = await prisma.appointment.create({
        data: {
          patientId: reviewer.id,
          patientName: reviewer.name,
          doctorId: doctor.id,
          doctorName: doctor.name,
          date: new Date(Date.now() - daysAgo * 24 * 60 * 60 * 1000),
          status: "completed",
          consultationType: i % 2 === 0 ? "video" : "physical",
          isVirtual: i % 2 === 0,
        },
      });
      await prisma.review.create({
        data: {
          appointmentId: appointment.id,
          patientId: reviewer.id,
          patientName: reviewer.name,
          doctorId: doctor.id,
          rating: review.rating,
          comment: review.comment,
        },
      });
    }
  }

  console.log("Seeding medications...");
  for (const medication of MEDICATIONS) {
    const existing = await prisma.medication.findFirst({ where: { name: medication.name } });
    if (!existing) {
      await prisma.medication.create({ data: medication });
    }
  }

  console.log("\nSeed complete.");
  console.log(`Admin login:  ${ADMIN_EMAIL} / ${ADMIN_PASSWORD}`);
  console.log(`Doctor login: <any doctor email above> / ${SEED_PASSWORD}`);
  console.log("Change these passwords after first login.");
}

main()
  .catch((error) => {
    console.error("Seed failed:", error);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
