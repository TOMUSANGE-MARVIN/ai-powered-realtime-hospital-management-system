import {
  Activity,
  AlertTriangle,
  BrainCircuit,
  FileText,
  ScanLine,
  SlidersHorizontal,
  Sparkles,
} from "lucide-react";
import Reveal from "@/components/home/Reveal";

const CAPABILITIES = [
  {
    title: "Imaging analysis",
    description:
      "AI flags abnormalities on X-rays and scans in seconds, for radiologists to confirm.",
    icon: ScanLine,
  },
  {
    title: "Predictive alerts",
    description:
      "Vitals trends are monitored continuously to catch deterioration before it becomes an emergency.",
    icon: Activity,
  },
  {
    title: "Smart triage",
    description:
      "Incoming cases are prioritized by urgency the moment they're logged.",
    icon: SlidersHorizontal,
  },
  {
    title: "Automated documentation",
    description:
      "Clinical notes are drafted from the visit, so your team spends less time typing.",
    icon: FileText,
  },
  {
    title: "Anomaly detection",
    description:
      "Lab results are compared against each patient's own baseline, not just a generic range.",
    icon: AlertTriangle,
  },
];

export default function AICapabilitiesSection() {
  return (
    <section className="rounded-t-[3rem] bg-[#0B1120] py-28">
      <div className="mx-auto max-w-6xl px-6 md:px-4">
        <Reveal className="mx-auto max-w-xl text-center">
          <span className="inline-flex items-center gap-1.5 rounded-full border border-indigo-400/30 bg-indigo-500/10 px-4 py-1.5 text-[11px] font-semibold tracking-wider text-indigo-300 uppercase">
            <BrainCircuit className="size-3.5" />
            Powered by AI
          </span>
          <h2 className="font-display mt-6 text-4xl leading-[1.1] font-medium text-white sm:text-5xl">
            Where AI meets clinical judgment
          </h2>
          <p className="mt-5 text-[15px] leading-relaxed text-slate-400">
            Our models don't replace your care team — they clear the noise so
            specialists can act faster, with more confidence, on every case.
          </p>
        </Reveal>

        <div className="mt-16 grid grid-cols-1 items-center gap-14 lg:grid-cols-2">
          {/* doctor photo with floating AI insight badges */}
          <Reveal delay={100} className="relative mx-auto w-full max-w-md">
            {/* ambient glow */}
            <div className="absolute inset-0 -z-10 rounded-[3rem] bg-gradient-to-br from-indigo-500/25 via-indigo-500/5 to-transparent blur-2xl" />

            {/* doodles */}
            <Sparkles
              className="absolute -top-5 right-8 size-6 rotate-12 text-indigo-300/60"
              strokeWidth={1.5}
            />
            <svg
              className="absolute -left-9 top-1/3 size-16 text-indigo-400/25"
              viewBox="0 0 60 60"
              fill="none"
            >
              <path
                d="M2 14c10 0 12 24 24 24s10-20 22-16"
                stroke="currentColor"
                strokeWidth="2"
                strokeLinecap="round"
              />
            </svg>
            <span className="absolute right-2 bottom-6 size-2.5 rounded-full bg-orange-400/70" />
            <span className="absolute top-1/2 -right-2 size-1.5 rounded-full bg-indigo-300/60" />

            {/* photo panel */}
            <div className="relative overflow-hidden rounded-[2.5rem] border border-white/10 bg-gradient-to-b from-indigo-950/60 to-slate-900/70 px-6 pt-8">
              <img
                src="/images/ai/doctor-ai-insight.png"
                alt="Physician reviewing AI-assisted patient insights"
                className="mx-auto h-[420px] w-auto object-contain drop-shadow-2xl"
              />
            </div>

            {/* floating badge: AI Insight mini card */}
            <div className="absolute -left-6 top-8 w-44 rounded-2xl border border-white/10 bg-white/[0.06] p-3 shadow-xl backdrop-blur-md">
              <div className="flex items-center justify-between">
                <span className="flex items-center gap-1.5 text-xs font-semibold text-white">
                  <BrainCircuit className="size-3.5 text-indigo-400" />
                  AI Insight
                </span>
                <span className="relative flex size-2">
                  <span className="absolute inline-flex size-full animate-ping rounded-full bg-emerald-400 opacity-75" />
                  <span className="relative inline-flex size-2 rounded-full bg-emerald-400" />
                </span>
              </div>
              <svg viewBox="0 0 100 30" className="mt-2 h-6 w-full">
                <polyline
                  points="0,20 15,18 30,22 45,10 60,14 75,5 90,9 100,6"
                  fill="none"
                  stroke="#818cf8"
                  strokeWidth="2"
                  strokeLinecap="round"
                  strokeLinejoin="round"
                />
              </svg>
              <p className="mt-1 text-[10px] leading-snug text-slate-400">
                Analyzing vitals in real time
              </p>
            </div>

            {/* floating badge: confidence score */}
            <div className="absolute -right-4 bottom-10 flex items-center gap-2.5 rounded-2xl border border-white/10 bg-white/[0.06] px-4 py-3 shadow-xl backdrop-blur-md">
              <span className="flex size-8 shrink-0 items-center justify-center rounded-full bg-emerald-500/20">
                <Activity className="size-4 text-emerald-400" />
              </span>
              <div>
                <p className="text-sm font-bold text-white">98%</p>
                <p className="text-[10px] text-slate-400">
                  Diagnostic accuracy
                </p>
              </div>
            </div>
          </Reveal>

          {/* capabilities list */}
          <div className="space-y-8">
            {CAPABILITIES.map((capability, i) => (
              <Reveal
                key={capability.title}
                delay={i * 90}
                className="flex items-start gap-4"
              >
                <span className="flex size-11 shrink-0 items-center justify-center rounded-xl border border-indigo-400/20 bg-indigo-500/10">
                  <capability.icon className="size-5 text-indigo-300" />
                </span>
                <div>
                  <h3 className="text-base font-semibold text-white">
                    {capability.title}
                  </h3>
                  <p className="mt-1 text-sm leading-relaxed text-slate-400">
                    {capability.description}
                  </p>
                </div>
              </Reveal>
            ))}
          </div>
        </div>
      </div>
    </section>
  );
}
