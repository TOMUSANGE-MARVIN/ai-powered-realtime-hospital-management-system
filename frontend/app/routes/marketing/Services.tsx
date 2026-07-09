import type { Route } from "./+types/Services";
import {
  Ambulance,
  BedDouble,
  Video,
  FlaskConical,
  ScanLine,
  Baby,
  Stethoscope,
  Pill,
} from "lucide-react";
import PageHeader from "@/components/home/PageHeader";
import CtaBanner from "@/components/home/CtaBanner";

export function meta({}: Route.MetaArgs) {
  return [
    { title: "Services — Ask Musawo" },
    {
      name: "description",
      content:
        "Emergency care, diagnostics, maternity, telehealth and more — comprehensive care backed by real-time monitoring and AI-assisted tools.",
    },
  ];
}

const SERVICES = [
  {
    title: "Emergency Care",
    description: "24/7 trauma and emergency response with rapid triage.",
    icon: Ambulance,
    blob: "bg-rose-200",
  },
  {
    title: "Inpatient Care",
    description: "Continuous vitals monitoring for every admitted patient.",
    icon: BedDouble,
    blob: "bg-sky-200",
  },
  {
    title: "Diagnostic Imaging",
    description: "X-ray, CT, and MRI with AI-assisted analysis.",
    icon: ScanLine,
    blob: "bg-amber-200",
  },
  {
    title: "Laboratory Services",
    description: "Fast, accurate lab results delivered straight to your chart.",
    icon: FlaskConical,
    blob: "bg-lime-200",
  },
  {
    title: "Maternity & Newborn",
    description: "Prenatal through postpartum care for parent and baby.",
    icon: Baby,
    blob: "bg-violet-200",
  },
  {
    title: "Outpatient Clinics",
    description: "Specialist consultations without the overnight stay.",
    icon: Stethoscope,
    blob: "bg-orange-200",
  },
  {
    title: "Telehealth Visits",
    description: "See a specialist from home for eligible appointments.",
    icon: Video,
    blob: "bg-teal-200",
  },
  {
    title: "Pharmacy",
    description: "On-site prescriptions with automatic refill reminders.",
    icon: Pill,
    blob: "bg-fuchsia-200",
  },
];

export default function Services() {
  return (
    <>
      <PageHeader
        eyebrow="What we offer"
        title={
          <>
            Comprehensive care,
            <br />
            all in one place
          </>
        }
        description="Every department runs on the same real-time platform, so your care team is always working from the latest information — not yesterday's chart."
      />

      <section className="bg-white pb-28">
        <div className="mx-auto grid max-w-6xl grid-cols-1 gap-6 px-6 sm:grid-cols-2 md:px-4 lg:grid-cols-4">
          {SERVICES.map((service) => (
            <div
              key={service.title}
              className="rounded-3xl border border-stone-200 p-6 transition-shadow hover:shadow-lg"
            >
              <span
                className={`flex size-14 items-center justify-center rounded-2xl ${service.blob}`}
              >
                <service.icon
                  className="size-6 text-stone-800"
                  strokeWidth={1.5}
                />
              </span>
              <h3 className="font-display mt-5 text-xl font-medium text-stone-900">
                {service.title}
              </h3>
              <p className="mt-2 text-sm leading-relaxed text-stone-500">
                {service.description}
              </p>
            </div>
          ))}
        </div>
      </section>

      <CtaBanner />
    </>
  );
}
