import type { Route } from "./+types/Careers";
import {
  GraduationCap,
  HeartPulse,
  Laptop,
  MapPin,
  Timer,
} from "lucide-react";
import PageHeader from "@/components/home/PageHeader";

export function meta({}: Route.MetaArgs) {
  return [
    { title: "Careers — MedFlow AI" },
    {
      name: "description",
      content: "Open roles at MedFlow AI — build the future of healthcare with us.",
    },
  ];
}

const PERKS = [
  {
    label: "Health Coverage",
    description: "Full medical, dental, and vision from day one.",
    icon: HeartPulse,
    blob: "bg-rose-200",
  },
  {
    label: "Growth & Training",
    description: "Continuing education and certification support.",
    icon: GraduationCap,
    blob: "bg-amber-200",
  },
  {
    label: "Flexible Schedules",
    description: "Shift options built around your life outside work.",
    icon: Timer,
    blob: "bg-sky-200",
  },
  {
    label: "Modern Tools",
    description: "Spend less time on paperwork, more time on care.",
    icon: Laptop,
    blob: "bg-violet-200",
  },
];

const ROLES = [
  {
    title: "Registered Nurse — ICU",
    department: "Nursing",
    location: "Kampala Campus",
    type: "Full-time",
  },
  {
    title: "Emergency Physician",
    department: "Emergency",
    location: "Kampala Campus",
    type: "Full-time",
  },
  {
    title: "Radiologic Technologist",
    department: "Diagnostic Imaging",
    location: "Kampala Campus",
    type: "Full-time",
  },
  {
    title: "Patient Care Coordinator",
    department: "Patient Support",
    location: "Remote / Hybrid",
    type: "Full-time",
  },
  {
    title: "Clinical Data Analyst",
    department: "AI & Data",
    location: "Remote",
    type: "Contract",
  },
];

export default function Careers() {
  return (
    <>
      <PageHeader
        eyebrow="Join our team"
        title={
          <>
            Build the future of
            <br />
            healthcare with us
          </>
        }
        description="We're looking for people who care as much about patients as they do about doing great work."
      />

      <section className="bg-white py-24">
        <div className="mx-auto max-w-6xl px-6 md:px-4">
          <div className="grid grid-cols-2 gap-x-8 gap-y-14 md:grid-cols-4">
            {PERKS.map((perk) => (
              <div key={perk.label} className="flex flex-col items-center text-center">
                <span
                  className={`flex size-20 items-center justify-center rounded-full ${perk.blob}`}
                >
                  <perk.icon
                    className="size-8 text-stone-800"
                    strokeWidth={1.5}
                  />
                </span>
                <span className="mt-5 text-sm font-semibold text-stone-900">
                  {perk.label}
                </span>
                <p className="mt-2 max-w-[11rem] text-xs leading-relaxed text-stone-500">
                  {perk.description}
                </p>
              </div>
            ))}
          </div>
        </div>
      </section>

      <section className="rounded-t-[3rem] bg-[#F5F0E6] pt-4 pb-28">
        <div className="mx-auto max-w-4xl px-6 md:px-4">
          <h2 className="font-display text-3xl font-medium text-stone-900">
            Open positions
          </h2>

          <div className="mt-8 space-y-4">
            {ROLES.map((role) => (
              <div
                key={role.title}
                className="flex flex-col gap-4 rounded-2xl bg-white p-6 shadow-sm sm:flex-row sm:items-center sm:justify-between"
              >
                <div>
                  <h3 className="font-display text-lg font-medium text-stone-900">
                    {role.title}
                  </h3>
                  <div className="mt-1.5 flex flex-wrap items-center gap-x-4 gap-y-1 text-xs text-stone-500">
                    <span>{role.department}</span>
                    <span className="flex items-center gap-1">
                      <MapPin className="size-3.5" />
                      {role.location}
                    </span>
                    <span>{role.type}</span>
                  </div>
                </div>
                <a
                  href="mailto:careers@medflow.co.ug"
                  className="inline-flex shrink-0 items-center justify-center rounded-full bg-stone-950 px-5 py-2.5 text-sm font-semibold text-white transition-transform hover:scale-[1.03] active:scale-[0.98]"
                >
                  Apply
                </a>
              </div>
            ))}
          </div>

          <p className="mt-10 text-center text-sm text-stone-600">
            Don't see the right role?{" "}
            <a
              href="mailto:careers@medflow.co.ug"
              className="font-semibold text-stone-900 underline underline-offset-4"
            >
              Reach out anyway
            </a>
            .
          </p>
        </div>
      </section>
    </>
  );
}
