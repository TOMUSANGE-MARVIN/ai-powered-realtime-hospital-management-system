import { BellRing, FileText, Receipt, ScanLine } from "lucide-react";
import Reveal from "@/components/home/Reveal";

const FEATURES = [
  {
    label: "Patient Records",
    description: "Secure, unified charts accessible to your whole care team.",
    icon: FileText,
    blob: "bg-sky-200",
    underline: "bg-sky-500",
  },
  {
    label: "AI Lab Analysis",
    description: "Faster, more accurate reads on X-rays and lab results.",
    icon: ScanLine,
    blob: "bg-orange-200",
    underline: "bg-orange-500",
  },
  {
    label: "Real-time Alerts",
    description: "Instant notifications the moment something needs attention.",
    icon: BellRing,
    blob: "bg-lime-200",
    underline: "bg-lime-600",
  },
  {
    label: "Simple Billing",
    description: "Transparent invoices and hassle-free online payments.",
    icon: Receipt,
    blob: "bg-violet-200",
    underline: "bg-violet-500",
  },
];

export default function FeaturesSection() {
  return (
    <section className="bg-white py-28">
      <div className="mx-auto max-w-6xl px-6 text-center md:px-4">
        <Reveal>
          <span className="inline-flex items-center rounded-full border border-stone-300 px-4 py-1.5 text-[11px] font-semibold tracking-wider text-stone-600 uppercase">
            Our commitment
          </span>

          <h2 className="font-display mx-auto mt-6 max-w-xl text-5xl leading-[1.05] font-medium text-stone-900">
            Care built around{" "}
            <span className="relative inline-block px-1">
              you
              <svg
                className="pointer-events-none absolute -inset-x-2 -inset-y-1.5 text-orange-500"
                viewBox="0 0 120 60"
                fill="none"
                preserveAspectRatio="none"
              >
                <ellipse
                  cx="60"
                  cy="30"
                  rx="55"
                  ry="25"
                  stroke="currentColor"
                  strokeWidth="2.5"
                  transform="rotate(-3 60 30)"
                />
              </svg>
            </span>
          </h2>
        </Reveal>

        <div className="mt-20 grid grid-cols-2 gap-x-8 gap-y-14 md:grid-cols-4">
          {FEATURES.map((feature, i) => (
            <Reveal
              key={feature.label}
              delay={i * 100}
              className="flex flex-col items-center"
            >
              <span
                className={`flex size-24 items-center justify-center rounded-full ${feature.blob}`}
              >
                <feature.icon
                  className="size-9 text-stone-800"
                  strokeWidth={1.5}
                />
              </span>
              <span className="mt-5 text-sm font-semibold text-stone-900">
                {feature.label}
              </span>
              <span
                className={`mt-1.5 h-0.5 w-8 rounded-full ${feature.underline}`}
              />
              <p className="mt-3 max-w-[11rem] text-xs leading-relaxed text-stone-500">
                {feature.description}
              </p>
            </Reveal>
          ))}
        </div>
      </div>
    </section>
  );
}
