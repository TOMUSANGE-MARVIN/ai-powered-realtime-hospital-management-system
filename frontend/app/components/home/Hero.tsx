import { Link } from "react-router";
import {
  ArrowDown,
  ArrowRight,
  CheckCheck,
  Heart,
  Sparkles,
} from "lucide-react";

export default function Hero() {
  return (
    <section className="relative overflow-hidden pt-14 pb-24">
      <div className="mx-auto grid max-w-6xl grid-cols-1 items-center gap-16 px-6 md:grid-cols-2 md:px-4">
        {/* left column */}
        <div>
          <span className="inline-flex items-center rounded-full border border-stone-300 bg-white/70 px-4 py-1.5 text-[11px] font-semibold tracking-wider text-stone-600 uppercase">
            AI-Powered Healthcare
          </span>

          <h1 className="font-display mt-6 text-6xl leading-[0.95] font-medium text-stone-900 sm:text-7xl">
            <span className="block">Smarter</span>
            <span className="block">care starts</span>
            <span className="block">here.</span>
          </h1>

          <div className="mt-8 flex flex-wrap items-center gap-4">
            <Link
              to="/book-appointment"
              className="inline-flex items-center gap-2 rounded-full bg-stone-950 px-6 py-3 text-sm font-semibold text-white shadow-sm transition-transform hover:scale-[1.03] active:scale-[0.98]"
            >
              Book Appointment <ArrowRight className="size-4" />
            </Link>
            <Link
              to="/services"
              className="inline-flex items-center gap-2 rounded-full border border-stone-300 bg-white/60 px-6 py-3 text-sm font-semibold text-stone-800 transition-colors hover:bg-white"
            >
              Our Services
            </Link>
          </div>

          <div className="mt-8 flex items-start gap-4">
            <span className="flex size-11 shrink-0 items-center justify-center rounded-full border border-stone-200 bg-white shadow-sm">
              <ArrowDown className="size-4 text-stone-700" />
            </span>
            <p className="max-w-[19rem] pt-2 text-sm leading-relaxed text-stone-600">
              To give every patient the fastest, safest care possible, we
              pair real-time monitoring with AI-assisted diagnostics.
            </p>
          </div>
        </div>

        {/* right column - photo collage */}
        <div className="relative mx-auto hidden h-[520px] w-full max-w-lg md:block">
          {/* sparkles + arrows */}
          <Sparkles
            className="absolute top-2 left-[46%] size-6 rotate-6 text-orange-500"
            strokeWidth={1.5}
          />
          <svg
            className="absolute top-[300px] left-[210px] size-10 text-stone-800"
            viewBox="0 0 40 40"
            fill="none"
          >
            <path
              d="M2 8c8 0 10 18 20 18s8-14 16-10"
              stroke="currentColor"
              strokeWidth="1.5"
              strokeLinecap="round"
            />
          </svg>

          {/* Trusted badge */}
          <span className="absolute top-6 left-0 z-20 -rotate-3 rounded-full bg-amber-300 px-4 py-1.5 text-xs font-semibold text-stone-900 shadow-md">
            Trusted
          </span>

          {/* photo A - woman, amber */}
          <div className="absolute top-0 right-4 z-10 h-56 w-44 -rotate-2 overflow-hidden rounded-[2rem] bg-amber-200 p-1.5 shadow-xl">
            <img
              src="https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=400&q=80&auto=format&fit=crop"
              alt="Smiling patient"
              className="h-full w-full rounded-[1.5rem] object-cover"
            />
          </div>

          {/* Calm badge */}
          <span className="absolute top-[228px] right-2 z-20 rotate-3 rounded-full bg-lime-200 px-4 py-1.5 text-xs font-semibold text-stone-900 shadow-md">
            Calm
          </span>

          {/* photo B - woman, violet */}
          <div className="absolute top-44 left-0 z-10 h-60 w-48 rotate-2 overflow-hidden rounded-[2rem] bg-violet-200 p-1.5 shadow-xl">
            <img
              src="https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=400&q=80&auto=format&fit=crop"
              alt="Content patient"
              className="h-full w-full rounded-[1.5rem] object-cover"
            />
            <span className="absolute -right-3 -bottom-3 flex size-9 items-center justify-center rounded-full bg-white shadow-md">
              <Heart className="size-4 fill-rose-500 text-rose-500" />
            </span>
          </div>

          {/* photo C - man, lime */}
          <div className="absolute top-64 right-0 z-10 h-52 w-40 -rotate-3 overflow-hidden rounded-[2rem] bg-lime-200 p-1.5 shadow-xl">
            <img
              src="https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=400&q=80&auto=format&fit=crop"
              alt="Reassured patient"
              className="h-full w-full rounded-[1.5rem] object-cover"
            />
          </div>

          {/* approved / AI card */}
          <div className="absolute bottom-6 left-48 z-20 flex w-36 items-center gap-2 rounded-2xl bg-orange-500 p-3 shadow-lg">
            <span className="flex size-8 shrink-0 items-center justify-center rounded-full bg-white/25">
              <CheckCheck className="size-4 text-white" />
            </span>
            <div className="flex flex-col gap-1">
              <span className="h-1.5 w-14 rounded-full bg-white/70" />
              <span className="h-1.5 w-10 rounded-full bg-white/50" />
            </div>
          </div>

          {/* Positive badge */}
          <span className="absolute bottom-2 left-0 z-20 rounded-full bg-violet-200 px-4 py-1.5 text-xs font-semibold text-stone-900 shadow-md">
            Positive
          </span>
        </div>

        {/* mobile fallback images */}
        <div className="mx-auto flex items-center justify-center gap-3 md:hidden">
          <div className="h-56 w-44 overflow-hidden rounded-[2rem] bg-amber-200 p-1.5 shadow-xl">
            <img
              src="https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=400&q=80&auto=format&fit=crop"
              alt="Smiling patient"
              className="h-full w-full rounded-[1.5rem] object-cover"
            />
          </div>
          <div className="flex flex-col gap-3">
            <div className="h-24 w-24 overflow-hidden rounded-[1.5rem] bg-violet-200 p-1.5 shadow-xl">
              <img
                src="https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=300&q=80&auto=format&fit=crop"
                alt="Content patient"
                className="h-full w-full rounded-[1.2rem] object-cover"
              />
            </div>
            <div className="h-24 w-24 overflow-hidden rounded-[1.5rem] bg-lime-200 p-1.5 shadow-xl">
              <img
                src="https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=300&q=80&auto=format&fit=crop"
                alt="Reassured patient"
                className="h-full w-full rounded-[1.2rem] object-cover"
              />
            </div>
          </div>
        </div>
      </div>
    </section>
  );
}
