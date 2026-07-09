import { Link } from "react-router";
import { ArrowRight } from "lucide-react";
import Reveal from "@/components/home/Reveal";

export default function VideoSection() {
  return (
    <section className="relative overflow-hidden rounded-t-[3rem] py-0">
      <div className="relative flex min-h-[560px] items-center justify-center">
        <video
          className="motion-reduce:hidden absolute inset-0 h-full w-full object-cover"
          src="/videos/hospital-hallway.mp4"
          poster="/images/hospital-hallway-poster.jpg"
          autoPlay
          muted
          loop
          playsInline
        />
        <img
          src="/images/hospital-hallway-poster.jpg"
          alt=""
          className="motion-safe:hidden absolute inset-0 h-full w-full object-cover"
        />

        <div className="absolute inset-0 bg-gradient-to-t from-black/80 via-black/40 to-black/30" />

        <Reveal className="relative z-10 mx-auto max-w-2xl px-6 py-24 text-center md:px-4">
          <span className="inline-flex items-center rounded-full border border-white/30 px-4 py-1.5 text-[11px] font-semibold tracking-wider text-white/80 uppercase">
            Take a look inside
          </span>
          <h2 className="font-display mt-6 text-4xl leading-[1.1] font-medium text-white sm:text-5xl">
            Care in motion
          </h2>
          <p className="mx-auto mt-5 max-w-md text-[15px] leading-relaxed text-white/70">
            From triage to recovery, every hallway, every handoff, every
            moment is coordinated in real time — so nothing falls through the
            cracks.
          </p>
          <div className="mt-8 flex flex-wrap items-center justify-center gap-4">
            <Link
              to="/book-appointment"
              className="rounded-full bg-white px-6 py-3 text-sm font-semibold text-stone-900 shadow-sm transition-transform hover:scale-[1.03] active:scale-[0.98]"
            >
              Book Appointment
            </Link>
            <Link
              to="/about"
              className="inline-flex items-center gap-2 rounded-full border border-white/30 px-6 py-3 text-sm font-semibold text-white transition-colors hover:bg-white/10"
            >
              Our Story <ArrowRight className="size-4" />
            </Link>
          </div>
        </Reveal>
      </div>
    </section>
  );
}
