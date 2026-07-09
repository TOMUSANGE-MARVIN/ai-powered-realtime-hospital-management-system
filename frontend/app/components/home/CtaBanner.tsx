import { Link } from "react-router";
import { ArrowRight } from "lucide-react";

export default function CtaBanner() {
  return (
    <section className="relative overflow-hidden rounded-t-[3rem] bg-[#0E3324] px-6 py-20 text-center md:px-4">
      <h2 className="font-display mx-auto max-w-xl text-4xl leading-[1.1] font-medium text-white sm:text-5xl">
        Ready to experience modern care?
      </h2>
      <p className="mx-auto mt-4 max-w-md text-[15px] text-emerald-100/70">
        Book an appointment in minutes or reach out to our care team with any
        questions.
      </p>
      <div className="mt-8 flex flex-wrap items-center justify-center gap-4">
        <Link
          to="/book-appointment"
          className="rounded-full bg-white px-6 py-3 text-sm font-semibold text-stone-900 shadow-sm transition-transform hover:scale-[1.03] active:scale-[0.98]"
        >
          Book Appointment
        </Link>
        <Link
          to="/contact"
          className="inline-flex items-center gap-2 rounded-full border border-white/30 px-6 py-3 text-sm font-semibold text-white transition-colors hover:bg-white/10"
        >
          Contact Us <ArrowRight className="size-4" />
        </Link>
      </div>
    </section>
  );
}
