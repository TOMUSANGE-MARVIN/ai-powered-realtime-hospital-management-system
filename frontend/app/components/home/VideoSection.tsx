import { Link } from "react-router";
import { ArrowRight } from "lucide-react";
import Reveal from "@/components/home/Reveal";

export default function VideoSection() {
  return (
    <section className="relative">
      {/* fixed video backdrop — pinned to the viewport at all times. Sections
          before and after this one are wrapped in their own `relative z-10`
          stacking context (see home.tsx) so they paint above this video
          regardless of scroll position; this div stays at the base z-index
          so it's only ever visible through this section's own transparent
          content, with no extra height or scroll range needed. Note: a
          negative z-index here would tuck it behind the page's own opaque
          background instead of just behind the surrounding sections. */}
      <div className="fixed inset-0 overflow-hidden">
        <video
          className="motion-reduce:hidden absolute inset-0 h-full w-full object-cover"
          src="/videos/healthcare-explainer.mp4"
          poster="/images/healthcare-explainer-poster.jpg"
          autoPlay
          muted
          loop
          playsInline
        />
        <img
          src="/images/healthcare-explainer-poster.jpg"
          alt=""
          className="motion-safe:hidden absolute inset-0 h-full w-full object-cover"
        />
        {/* This explainer video has a near-white background (unlike the
            previous dark footage), so the overlay only needs to lighten it
            further for legibility, not darken it — text/buttons below are
            dark instead of white to read against that light backdrop. */}
        <div className="absolute inset-0 bg-white/50" />
      </div>

      <div className="relative z-10 flex min-h-[560px] items-center justify-center px-6 md:px-4">
        <Reveal className="mx-auto max-w-2xl text-center">
          <span className="inline-flex items-center rounded-full border border-stone-900/15 bg-white/60 px-4 py-1.5 text-[11px] font-semibold tracking-wider text-emerald-900 uppercase">
            Take a look inside
          </span>
          <h2 className="font-display mt-6 text-4xl leading-[1.1] font-medium text-stone-900 sm:text-5xl">
            Care in motion
          </h2>
          <p className="mx-auto mt-5 max-w-md text-[15px] leading-relaxed text-stone-700">
            From triage to recovery, every hallway, every handoff, every
            moment is coordinated in real time — so nothing falls through the
            cracks.
          </p>
          <div className="mt-8 flex flex-wrap items-center justify-center gap-4">
            <Link
              to="/book-appointment"
              className="rounded-full bg-stone-900 px-6 py-3 text-sm font-semibold text-white shadow-sm transition-transform hover:scale-[1.03] active:scale-[0.98]"
            >
              Book Appointment
            </Link>
            <Link
              to="/about"
              className="inline-flex items-center gap-2 rounded-full border border-stone-900/25 px-6 py-3 text-sm font-semibold text-stone-900 transition-colors hover:bg-stone-900/5"
            >
              Our Story <ArrowRight className="size-4" />
            </Link>
          </div>
        </Reveal>
      </div>
    </section>
  );
}
