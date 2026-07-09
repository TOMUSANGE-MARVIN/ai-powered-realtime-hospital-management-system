import { useState } from "react";
import type { Route } from "./+types/FAQ";
import { ChevronDown } from "lucide-react";
import PageHeader from "@/components/home/PageHeader";
import CtaBanner from "@/components/home/CtaBanner";

export function meta({}: Route.MetaArgs) {
  return [
    { title: "FAQ — Ask Musawo" },
    {
      name: "description",
      content: "Answers to common questions about visiting Ask Musawo.",
    },
  ];
}

const FAQS = [
  {
    question: "How do I book an appointment?",
    answer:
      "Use the Book Appointment page to request a visit with your preferred department and time. Our scheduling team confirms every request within one business day.",
  },
  {
    question: "What insurance do you accept?",
    answer:
      "We work with most major insurance providers. Bring your insurance card to your visit, or contact us beforehand to confirm your specific plan is in network.",
  },
  {
    question: "Do I need an appointment for emergency care?",
    answer:
      "No. Our Emergency department is open 24/7 and accepts walk-ins. For life-threatening emergencies, call 999 or 112 immediately.",
  },
  {
    question: "Can I have a telehealth visit instead?",
    answer:
      "Many follow-up and consultation visits are eligible for telehealth. Select the department when booking and our team will let you know if a virtual visit is available.",
  },
  {
    question: "How do I access my lab results?",
    answer:
      "Lab results are posted to your patient account as soon as they're reviewed by your care team. Sign in to the patient portal to view them alongside your doctor's notes.",
  },
  {
    question: "What are your visiting hours?",
    answer:
      "General visiting hours run from 8am to 8pm daily. Maternity and ICU units have their own schedules — check with the front desk when you arrive.",
  },
];

export default function FAQ() {
  const [open, setOpen] = useState<number | null>(0);

  return (
    <>
      <PageHeader
        eyebrow="Questions & answers"
        title="Frequently asked questions"
        description="Can't find what you're looking for? Reach out to our care team and we'll get back to you directly."
      />

      <section className="bg-white pb-28">
        <div className="mx-auto max-w-2xl px-6 md:px-4">
          <div className="divide-y divide-stone-200 rounded-3xl border border-stone-200">
            {FAQS.map((faq, i) => {
              const isOpen = open === i;
              return (
                <div key={faq.question} className="px-6">
                  <button
                    type="button"
                    onClick={() => setOpen(isOpen ? null : i)}
                    aria-expanded={isOpen}
                    className="flex w-full items-center justify-between gap-4 py-5 text-left"
                  >
                    <span className="font-display text-lg font-medium text-stone-900">
                      {faq.question}
                    </span>
                    <ChevronDown
                      className={`size-5 shrink-0 text-stone-500 transition-transform ${
                        isOpen ? "rotate-180" : ""
                      }`}
                    />
                  </button>
                  {isOpen && (
                    <p className="pb-5 text-sm leading-relaxed text-stone-600">
                      {faq.answer}
                    </p>
                  )}
                </div>
              );
            })}
          </div>
        </div>
      </section>

      <CtaBanner />
    </>
  );
}
