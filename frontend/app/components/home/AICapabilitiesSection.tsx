import {
  Activity,
  AlertTriangle,
  BrainCircuit,
  FileText,
  ScanLine,
  SlidersHorizontal,
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
          {/* mockup AI insight panel */}
          <Reveal delay={100}>
            <div className="relative rounded-3xl border border-white/10 bg-white/[0.03] p-6 shadow-2xl backdrop-blur-sm">
              <div className="flex items-center justify-between">
                <span className="flex items-center gap-2 text-sm font-semibold text-white">
                  <BrainCircuit className="size-4 text-indigo-400" />
                  AI Insight
                </span>
                <span className="flex items-center gap-1.5 text-xs text-emerald-400">
                  <span className="relative flex size-2">
                    <span className="absolute inline-flex size-full animate-ping rounded-full bg-emerald-400 opacity-75" />
                    <span className="relative inline-flex size-2 rounded-full bg-emerald-400" />
                  </span>
                  Analyzing
                </span>
              </div>

              {/* mini vitals chart */}
              <div className="mt-6 rounded-2xl bg-black/20 p-4">
                <svg viewBox="0 0 300 80" className="h-20 w-full">
                  <polyline
                    points="0,55 30,52 60,58 90,45 120,50 150,20 180,28 210,15 240,22 270,18 300,25"
                    fill="none"
                    stroke="url(#lineGradient)"
                    strokeWidth="2.5"
                    strokeLinecap="round"
                    strokeLinejoin="round"
                  />
                  <circle cx="210" cy="15" r="5" fill="#f97316" />
                  <defs>
                    <linearGradient id="lineGradient" x1="0" y1="0" x2="1" y2="0">
                      <stop offset="0%" stopColor="#818cf8" />
                      <stop offset="100%" stopColor="#f97316" />
                    </linearGradient>
                  </defs>
                </svg>
              </div>

              <div className="mt-5">
                <p className="text-sm font-medium text-white">
                  Elevated heart rate trend detected
                </p>
                <p className="mt-1 text-xs text-slate-400">
                  Room 214 · Patient vitals, last 6 hours
                </p>

                <div className="mt-4 flex items-center gap-3">
                  <div className="h-1.5 flex-1 overflow-hidden rounded-full bg-white/10">
                    <div className="h-full w-[94%] rounded-full bg-gradient-to-r from-indigo-400 to-orange-400" />
                  </div>
                  <span className="text-xs font-semibold text-white">94%</span>
                </div>
                <p className="mt-1 text-[11px] text-slate-500">
                  Confidence score
                </p>
              </div>

              <div className="mt-5 flex items-center gap-2 rounded-xl bg-orange-500/10 px-4 py-3">
                <AlertTriangle className="size-4 shrink-0 text-orange-400" />
                <p className="text-xs text-orange-200">
                  Flagged for physician review
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
