import { useEffect, useState } from "react";
import { Leaf } from "lucide-react";
import Reveal from "@/components/home/Reveal";

const SLIDES = [
  {
    src: "https://images.unsplash.com/photo-1470116945706-e6bf5d5a53ca?w=500&q=80&auto=format&fit=crop",
    alt: "Parent holding a newborn's hand",
  },
  {
    src: "https://images.unsplash.com/photo-1631217868264-e5b90bb7e133?w=500&q=80&auto=format&fit=crop",
    alt: "Doctor consulting a patient warmly",
  },
  {
    src: "https://images.unsplash.com/photo-1581056771107-24ca5f033842?w=500&q=80&auto=format&fit=crop",
    alt: "Doctor reviewing care with a senior patient",
  },
];

export default function ConfidenceSection() {
  const [active, setActive] = useState(0);

  useEffect(() => {
    const timer = setTimeout(() => {
      setActive((current) => (current + 1) % SLIDES.length);
    }, 4500);
    return () => clearTimeout(timer);
  }, [active]);

  return (
    <section
      id="confidence"
      className="relative overflow-hidden rounded-t-[3rem] bg-[#0E3324] py-24"
    >
      <Leaf
        className="absolute top-10 left-6 size-10 -rotate-12 text-emerald-500/40 md:left-16"
        strokeWidth={1.2}
      />

      <div className="mx-auto grid max-w-6xl grid-cols-1 items-center gap-16 px-6 md:grid-cols-2 md:px-4">
        {/* content */}
        <Reveal>
          <span className="inline-flex items-center rounded-full border border-white/20 px-4 py-1.5 text-[11px] font-semibold tracking-wider text-emerald-100 uppercase">
            Caring is always here
          </span>

          <h2 className="font-display mt-6 text-5xl leading-[1.05] font-medium text-white">
            We help you feel
            <br />
            safe at every age
          </h2>

          <p className="mt-6 max-w-md text-[15px] leading-relaxed text-emerald-100/70">
            From newborn checkups to senior care, our specialists tailor
            treatment plans backed by continuous vitals monitoring and
            AI-flagged alerts.
          </p>
        </Reveal>

        {/* photo slider */}
        <Reveal
          delay={150}
          className="mx-auto flex w-full max-w-sm items-center gap-4"
        >
          {/* vertical carousel indicators */}
          <div className="flex flex-col items-center gap-2.5">
            {SLIDES.map((slide, i) => (
              <button
                key={slide.src}
                type="button"
                onClick={() => setActive(i)}
                aria-label={`Show slide ${i + 1}`}
                aria-current={i === active}
                className={`w-1 rounded-full transition-all duration-300 ${
                  i === active ? "h-10 bg-white" : "h-5 bg-white/25 hover:bg-white/40"
                }`}
              />
            ))}
          </div>

          <div className="relative h-72 flex-1 overflow-hidden rounded-3xl shadow-2xl">
            {SLIDES.map((slide, i) => (
              <img
                key={slide.src}
                src={slide.src}
                alt={slide.alt}
                className={`absolute inset-0 h-full w-full object-cover transition-opacity duration-700 ${
                  i === active ? "opacity-100" : "opacity-0"
                }`}
              />
            ))}
          </div>
        </Reveal>
      </div>
    </section>
  );
}
