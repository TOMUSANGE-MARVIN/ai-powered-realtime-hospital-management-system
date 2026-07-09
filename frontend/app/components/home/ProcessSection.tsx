import { CalendarCheck, ClipboardCheck, Stethoscope } from "lucide-react";
import Reveal from "@/components/home/Reveal";

const STEPS = [
  {
    number: "01",
    label: "Book",
    description: "Choose a department and a time that works for you.",
    icon: CalendarCheck,
  },
  {
    number: "02",
    label: "Visit",
    description: "See your specialist in person or over telehealth.",
    icon: Stethoscope,
  },
  {
    number: "03",
    label: "Follow up",
    description: "Track results and next steps in your patient portal.",
    icon: ClipboardCheck,
  },
];

export default function ProcessSection() {
  return (
    <section className="bg-[#F5F0E6] py-24">
      <div className="mx-auto max-w-6xl px-6 text-center md:px-4">
        <Reveal>
          <span className="inline-flex items-center rounded-full border border-stone-300 px-4 py-1.5 text-[11px] font-semibold tracking-wider text-stone-600 uppercase">
            Getting started
          </span>
          <h2 className="font-display mx-auto mt-6 max-w-xl text-4xl leading-[1.1] font-medium text-stone-900">
            How it works
          </h2>
        </Reveal>

        <div className="relative mt-16 grid grid-cols-1 gap-12 sm:grid-cols-3">
          <div className="absolute top-7 right-[16.5%] left-[16.5%] hidden border-t border-dashed border-stone-300 sm:block" />
          {STEPS.map((step, i) => (
            <Reveal
              key={step.label}
              delay={i * 120}
              className="relative flex flex-col items-center"
            >
              <span className="relative z-10 flex size-14 items-center justify-center rounded-full bg-stone-950 text-sm font-semibold text-white">
                {step.number}
              </span>
              <step.icon
                className="mt-5 size-6 text-stone-700"
                strokeWidth={1.5}
              />
              <span className="mt-3 text-base font-semibold text-stone-900">
                {step.label}
              </span>
              <p className="mt-2 max-w-[14rem] text-sm leading-relaxed text-stone-500">
                {step.description}
              </p>
            </Reveal>
          ))}
        </div>
      </div>
    </section>
  );
}
