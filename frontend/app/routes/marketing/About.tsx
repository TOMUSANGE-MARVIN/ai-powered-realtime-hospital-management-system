import type { Route } from "./+types/About";
import { HeartHandshake, ShieldCheck, Sparkles, Target } from "lucide-react";
import PageHeader from "@/components/home/PageHeader";
import CtaBanner from "@/components/home/CtaBanner";

export function meta({}: Route.MetaArgs) {
  return [
    { title: "About Us — Ask Musawo" },
    {
      name: "description",
      content:
        "Ask Musawo pairs board-certified specialists with AI-assisted tools to deliver faster, safer, more coordinated care.",
    },
  ];
}

const VALUES = [
  {
    label: "Compassion",
    description: "Every patient is met with empathy, not just expertise.",
    icon: HeartHandshake,
    blob: "bg-rose-200",
  },
  {
    label: "Innovation",
    description: "AI-assisted tools sharpen, not replace, clinical judgment.",
    icon: Sparkles,
    blob: "bg-amber-200",
  },
  {
    label: "Integrity",
    description: "Transparent data and honest conversations, always.",
    icon: ShieldCheck,
    blob: "bg-sky-200",
  },
  {
    label: "Excellence",
    description: "We hold ourselves to outcomes, not just intentions.",
    icon: Target,
    blob: "bg-violet-200",
  },
];

const STATS = [
  { value: "12k+", label: "Patients served" },
  { value: "98%", label: "Satisfaction rate" },
  { value: "15+", label: "Years of care" },
  { value: "40+", label: "Specialists" },
];

export default function About() {
  return (
    <>
      <PageHeader
        eyebrow="Our story"
        title={
          <>
            Care built on trust,
            <br />
            driven by technology
          </>
        }
        description="Ask Musawo started with a simple idea: patients get better outcomes when their care team has the right information at the right moment. We built the platform we wished every hospital already had."
      />

      <section className="bg-white py-24">
        <div className="mx-auto grid max-w-6xl grid-cols-1 items-center gap-16 px-6 md:grid-cols-2 md:px-4">
          <div className="overflow-hidden rounded-[2.5rem] shadow-xl">
            <img
              src="https://images.unsplash.com/photo-1576091160399-112ba8d25d1d?w=600&q=80&auto=format&fit=crop"
              alt="Doctor reviewing patient data"
              className="h-96 w-full object-cover"
            />
          </div>
          <div>
            <span className="inline-flex items-center rounded-full border border-stone-300 px-4 py-1.5 text-[11px] font-semibold tracking-wider text-stone-600 uppercase">
              Our mission
            </span>
            <h2 className="font-display mt-6 text-4xl leading-[1.1] font-medium text-stone-900">
              Faster answers, calmer decisions
            </h2>
            <p className="mt-6 max-w-md text-[15px] leading-relaxed text-stone-600">
              From admission to discharge, Ask Musawo keeps every clinician,
              nurse, and specialist working off the same live picture of a
              patient's condition — vitals, lab results, imaging, and
              billing, all in one place.
            </p>
            <p className="mt-4 max-w-md text-[15px] leading-relaxed text-stone-600">
              Our AI-assisted tools flag what matters sooner, so your care
              team can spend less time hunting for information and more time
              with patients.
            </p>
          </div>
        </div>
      </section>

      <section className="bg-[#F5F0E6] py-24">
        <div className="mx-auto max-w-6xl px-6 text-center md:px-4">
          <span className="inline-flex items-center rounded-full border border-stone-300 px-4 py-1.5 text-[11px] font-semibold tracking-wider text-stone-600 uppercase">
            What we stand for
          </span>
          <h2 className="font-display mx-auto mt-6 max-w-xl text-4xl leading-[1.1] font-medium text-stone-900">
            Our values
          </h2>

          <div className="mt-16 grid grid-cols-2 gap-x-8 gap-y-14 md:grid-cols-4">
            {VALUES.map((value) => (
              <div key={value.label} className="flex flex-col items-center">
                <span
                  className={`flex size-20 items-center justify-center rounded-full ${value.blob}`}
                >
                  <value.icon
                    className="size-8 text-stone-800"
                    strokeWidth={1.5}
                  />
                </span>
                <span className="mt-5 text-sm font-semibold text-stone-900">
                  {value.label}
                </span>
                <p className="mt-2 max-w-[11rem] text-xs leading-relaxed text-stone-500">
                  {value.description}
                </p>
              </div>
            ))}
          </div>
        </div>
      </section>

      <section className="bg-white py-20">
        <div className="mx-auto grid max-w-4xl grid-cols-2 gap-10 px-6 text-center sm:grid-cols-4 md:px-4">
          {STATS.map((stat) => (
            <div key={stat.label}>
              <span className="font-display text-4xl font-medium text-stone-900 sm:text-5xl">
                {stat.value}
              </span>
              <p className="mt-2 text-xs text-stone-500">{stat.label}</p>
            </div>
          ))}
        </div>
      </section>

      <CtaBanner />
    </>
  );
}
