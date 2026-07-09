import { Link } from "react-router";
import { ArrowRight, BrainCircuit, Sparkles, Stethoscope } from "lucide-react";
import Reveal from "@/components/home/Reveal";

export default function HelpSection() {
  return (
    <section id="services" className="pb-28">
      <div className="mx-auto grid max-w-6xl grid-cols-1 items-center gap-16 px-6 md:grid-cols-2 md:px-4">
        {/* illustration */}
        <Reveal className="relative mx-auto h-[420px] w-full max-w-sm">
          <div className="absolute inset-0 -rotate-2 rounded-[2.5rem] bg-amber-200/50" />

          <span className="absolute top-0 left-6 z-20 -rotate-3 rounded-full bg-sky-200 px-4 py-1.5 text-xs font-semibold text-stone-900 shadow-md">
            Doctor
          </span>

          <svg
            className="absolute top-2 right-8 z-20 size-10 text-stone-800"
            viewBox="0 0 40 40"
            fill="none"
          >
            <path
              d="M4 30c6-14 14-4 20-14"
              stroke="currentColor"
              strokeWidth="1.5"
              strokeLinecap="round"
            />
          </svg>

          {/* doctor photo - transparent background, no frame */}
          <img
            src="/images/doctor-photo.png"
            alt="Smiling nurse with stethoscope"
            className="absolute bottom-0 left-1/2 z-10 h-[380px] w-auto -translate-x-1/2 object-contain"
          />

          <span className="absolute top-24 left-0 z-20 flex size-14 -rotate-6 items-center justify-center rounded-2xl bg-amber-300 shadow-lg">
            <Stethoscope className="size-7 text-stone-800" strokeWidth={1.5} />
          </span>

          <div className="absolute right-0 bottom-4 z-20 w-44 rounded-3xl bg-white p-4 shadow-xl">
            <div className="mb-2 flex items-center gap-2">
              <BrainCircuit className="size-5 text-violet-600" />
              <span className="text-xs font-semibold text-stone-800">
                AI Insight
              </span>
            </div>
            <span className="block h-1.5 w-full rounded-full bg-stone-100" />
            <span className="mt-1.5 block h-1.5 w-3/4 rounded-full bg-stone-100" />
          </div>
        </Reveal>

        {/* content */}
        <Reveal delay={120}>
          <h2 className="font-display text-5xl leading-[1.05] font-medium text-stone-900">
            How can we
            <br />
            help you{" "}
            <Sparkles className="ml-1 inline size-8 text-orange-500 align-middle" />
          </h2>
          <p className="mt-6 max-w-md text-[15px] leading-relaxed text-stone-600">
            We pair board-certified specialists with AI-assisted tools to
            deliver faster diagnoses, real-time monitoring, and coordinated
            care across every department.
          </p>
          <p className="mt-4 max-w-md text-[15px] leading-relaxed text-stone-600">
            Every decision, from triage to discharge, is backed by live
            patient data.
          </p>
          <Link
            to="/login"
            className="mt-8 inline-flex items-center gap-2 rounded-full bg-stone-950 px-6 py-3 text-sm font-semibold text-white shadow-sm transition-transform hover:scale-[1.03] active:scale-[0.98]"
          >
            Get Care <ArrowRight className="size-4" />
          </Link>
        </Reveal>
      </div>
    </section>
  );
}
