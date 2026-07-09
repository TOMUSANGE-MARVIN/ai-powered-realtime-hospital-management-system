import { Leaf, Quote } from "lucide-react";
import Reveal from "@/components/home/Reveal";

export default function TestimonialSection() {
  return (
    <section id="testimonial" className="relative bg-[#F5F0E6] py-24">
      <div className="mx-auto grid max-w-6xl grid-cols-1 gap-10 px-6 md:grid-cols-2 md:px-4">
        <Reveal className="relative overflow-hidden rounded-[2.5rem] bg-stone-900 p-6">
          <div className="h-72 overflow-hidden rounded-[1.75rem] sm:h-96">
            <img
              src="https://images.unsplash.com/photo-1559839734-2b71ea197ec2?w=500&q=80&auto=format&fit=crop"
              alt="Dr. Grace Nakato"
              className="h-full w-full object-cover"
            />
          </div>
          <div className="mt-4">
            <p className="text-sm font-semibold text-white">
              Dr. Grace Nakato
            </p>
            <p className="text-xs text-stone-400">
              Head of Internal Medicine
            </p>
          </div>
        </Reveal>

        <Reveal
          delay={150}
          className="relative flex flex-col justify-center rounded-[2.5rem] bg-white p-10 shadow-sm sm:p-12"
        >
          <Quote className="size-8 text-stone-300" strokeWidth={1.5} />
          <h3 className="font-display mt-4 text-4xl leading-[1.1] font-medium text-stone-900">
            Felt truly{" "}
            <span className="text-orange-600 italic underline decoration-orange-300 underline-offset-4">
              cared for
            </span>
          </h3>

          <div className="mt-6 flex items-center gap-3">
            <img
              src="https://i.pravatar.cc/80?img=32"
              alt="Moses Kato"
              className="size-11 rounded-full object-cover"
            />
            <div>
              <p className="text-sm font-semibold text-stone-900">
                Moses Kato
              </p>
              <p className="text-xs text-stone-500">Recovered ICU Patient</p>
            </div>
          </div>

          <p className="mt-6 max-w-md text-sm leading-relaxed text-stone-600">
            The real-time updates and quick response from the care team gave
            my family peace of mind through the entire stay. I always knew
            exactly what was happening and why.
          </p>

          <Leaf
            className="pointer-events-none absolute right-8 bottom-6 size-10 rotate-12 text-stone-200"
            strokeWidth={1.2}
          />
        </Reveal>
      </div>
    </section>
  );
}
