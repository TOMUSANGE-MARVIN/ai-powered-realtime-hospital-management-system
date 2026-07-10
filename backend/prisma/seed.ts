import { auth } from "../src/lib/auth";
import { prisma } from "../src/lib/prisma";

const ADMIN_EMAIL = "admin@askmusawo.co.ug";
const ADMIN_PASSWORD = "ChangeMe123!";
const SEED_PASSWORD = "DoctorPass123!";

const DOCTORS = [
  {
    name: "Dr. Grace Nakato",
    email: "grace.nakato@askmusawo.co.ug",
    specialization: "Internal Medicine",
    department: "Internal Medicine",
  },
  {
    name: "Dr. Joseph Okello",
    email: "joseph.okello@askmusawo.co.ug",
    specialization: "Pediatrics",
    department: "Pediatrics",
  },
  {
    name: "Dr. Patricia Namutebi",
    email: "patricia.namutebi@askmusawo.co.ug",
    specialization: "Orthopedic Surgery",
    department: "Orthopedics",
  },
  {
    name: "Dr. Ibrahim Wasswa",
    email: "ibrahim.wasswa@askmusawo.co.ug",
    specialization: "Cardiology",
    department: "Cardiology",
  },
  {
    name: "Dr. Susan Achieng",
    email: "susan.achieng@askmusawo.co.ug",
    specialization: "Obstetrics & Gynecology",
    department: "Maternity",
  },
  {
    name: "Dr. Sarah Nabwire",
    email: "sarah.nabwire@askmusawo.co.ug",
    specialization: "Emergency Medicine",
    department: "Emergency",
  },
];

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
  for (const doctor of DOCTORS) {
    const user = await upsertAuthUser(doctor.name, doctor.email, SEED_PASSWORD);
    await prisma.user.update({
      where: { id: user.id },
      data: {
        role: "doctor",
        status: "active",
        specialization: doctor.specialization,
        department: doctor.department,
      },
    });
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
