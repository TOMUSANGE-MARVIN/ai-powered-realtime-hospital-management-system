import { prisma } from "./prisma";
import { formatVisit, notifyUser } from "./notify";

// One place that turns a booking request into an appointment, used both by
// the app's book call and by the server when Pesapal confirms a payment.

export interface BookingDetails {
  date: string;
  time?: string | null;
  reason?: string | null;
  consultationType?: string | null;
  department?: string | null;
  isEmergency?: boolean;
}

export async function insertAppointment(input: {
  patient: { id: string; name: string; email?: string | null };
  doctor: { id: string; name: string; department: string | null; consultationFee: number | null };
  details: BookingDetails;
  paymentId?: string | null;
}) {
  const { patient, doctor, details, paymentId } = input;
  // Emergencies need immediate attention — the date is always today.
  const date = details.isEmergency ? new Date() : new Date(details.date);
  const consultationType = details.consultationType ?? "video";
  const appointment = await prisma.appointment.create({
    data: {
      patientId: patient.id,
      patientName: patient.name,
      patientEmail: patient.email ?? undefined,
      doctorId: doctor.id,
      doctorName: doctor.name,
      department: details.department || doctor.department,
      date,
      time: details.time ?? undefined,
      reason: details.reason ?? undefined,
      consultationType,
      isVirtual: consultationType !== "in_person" && consultationType !== "physical",
      isEmergency: !!details.isEmergency,
      paymentId: paymentId ?? undefined,
      status: "requested",
      fee: doctor.consultationFee ?? undefined,
    },
  });
  const kind = consultationType === "physical" ? "in-person" : consultationType;
  await notifyUser(doctor.id, {
    type: "appointment",
    title: appointment.isEmergency ? "Emergency request" : "New appointment request",
    message: appointment.isEmergency
      ? `${patient.name} needs to be seen today (${kind}).`
      : `${patient.name} requested a ${kind} consultation on ${formatVisit(appointment.date, appointment.time)}.`,
    link: "/doctor-home/appointments",
  });
  if (appointment.isEmergency) {
    // Admins hear about every emergency straight away, so one can step in if
    // the doctor doesn't respond.
    const admins = await prisma.user.findMany({ where: { role: "admin" }, select: { id: true } });
    for (const admin of admins) {
      await notifyUser(admin.id, {
        type: "appointment",
        title: "Emergency request",
        message: `${patient.name} requested emergency care from ${doctor.name}.`,
      });
    }
  }
  return appointment;
}

/**
 * Books the appointment for a paid payment that carries booking details and
 * isn't linked to one yet. Safe to call repeatedly or concurrently:
 * `appointment.paymentId` is unique, so only one booking can ever win.
 * Returns the linked appointment, or null when there's nothing to book.
 */
export async function bookPaidPayment(paymentId: string) {
  const existing = await prisma.appointment.findUnique({ where: { paymentId } });
  if (existing) return existing;

  const payment = await prisma.payment.findUnique({ where: { id: paymentId } });
  if (!payment || payment.status !== "paid" || !payment.bookingDetails) return null;

  const [patient, doctor] = await Promise.all([
    prisma.user.findUnique({
      where: { id: payment.patientId },
      select: { id: true, name: true, email: true },
    }),
    prisma.user.findFirst({
      where: { id: payment.doctorId, role: "doctor" },
      select: { id: true, name: true, department: true, consultationFee: true },
    }),
  ]);
  if (!patient || !doctor) return null;

  try {
    return await insertAppointment({
      patient,
      doctor,
      details: payment.bookingDetails as unknown as BookingDetails,
      paymentId,
    });
  } catch (error: any) {
    // Another request booked it first.
    if (error?.code === "P2002") {
      return prisma.appointment.findUnique({ where: { paymentId } });
    }
    throw error;
  }
}
