import { useState } from "react";
import type { Route } from "./+types/Contact";
import { toast } from "sonner";
import { AlertTriangle, Clock, Mail, MapPin, Phone } from "lucide-react";
import PageHeader from "@/components/home/PageHeader";

const fieldClass =
  "mt-1.5 w-full rounded-xl border border-stone-300 bg-white px-4 py-3 text-sm text-stone-900 placeholder:text-stone-400 outline-none transition-colors focus:border-stone-900 focus:ring-2 focus:ring-stone-900/10";

export function meta({}: Route.MetaArgs) {
  return [
    { title: "Contact — Ask Musawo" },
    {
      name: "description",
      content: "Get in touch with the Ask Musawo care team.",
    },
  ];
}

const INFO = [
  {
    icon: MapPin,
    label: "Address",
    value: "14 Acacia Avenue, Kololo, Kampala, Uganda",
  },
  { icon: Phone, label: "Phone", value: "+256 414 255 900" },
  { icon: Mail, label: "Email", value: "care@askmusawo.co.ug" },
  { icon: Clock, label: "Hours", value: "Open 24/7 for emergency care" },
];

export default function Contact() {
  const [submitted, setSubmitted] = useState(false);
  const [form, setForm] = useState({
    name: "",
    email: "",
    subject: "",
    message: "",
  });

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!form.name || !form.email || !form.message) return;
    setSubmitted(true);
    toast.success("Message sent — we'll get back to you shortly.");
  };

  return (
    <>
      <PageHeader
        eyebrow="Get in touch"
        title={
          <>
            We're here when
            <br />
            you need us
          </>
        }
        description="Questions about a visit, billing, or records? Send us a message and our care team will respond within one business day."
      />

      <section className="bg-white pb-28">
        <div className="mx-auto flex max-w-3xl items-start gap-3 rounded-2xl border border-rose-200 bg-rose-50 px-6 py-4 sm:px-4">
          <AlertTriangle className="mt-0.5 size-5 shrink-0 text-rose-600" />
          <p className="text-sm text-rose-700">
            For medical emergencies, call{" "}
            <span className="font-semibold">999</span> or{" "}
            <span className="font-semibold">112</span> immediately. This form
            is not monitored for urgent medical needs.
          </p>
        </div>

        <div className="mx-auto mt-16 grid max-w-6xl grid-cols-1 gap-16 px-6 md:grid-cols-2 md:px-4">
          {/* form */}
          <div>
            {submitted ? (
              <div className="rounded-3xl border border-stone-200 bg-stone-50 p-8 text-center">
                <h3 className="font-display text-2xl font-medium text-stone-900">
                  Message sent
                </h3>
                <p className="mt-2 text-sm text-stone-600">
                  Thanks, {form.name.split(" ")[0]} — our care team will reply
                  to {form.email} within one business day.
                </p>
              </div>
            ) : (
              <form onSubmit={handleSubmit} className="space-y-5">
                <div>
                  <label className="text-sm font-medium text-stone-700">
                    Name
                  </label>
                  <input
                    required
                    value={form.name}
                    onChange={(e) =>
                      setForm((f) => ({ ...f, name: e.target.value }))
                    }
                    placeholder="Jane Doe"
                    className={fieldClass}
                  />
                </div>
                <div>
                  <label className="text-sm font-medium text-stone-700">
                    Email
                  </label>
                  <input
                    required
                    type="email"
                    value={form.email}
                    onChange={(e) =>
                      setForm((f) => ({ ...f, email: e.target.value }))
                    }
                    placeholder="jane@example.com"
                    className={fieldClass}
                  />
                </div>
                <div>
                  <label className="text-sm font-medium text-stone-700">
                    Subject
                  </label>
                  <input
                    value={form.subject}
                    onChange={(e) =>
                      setForm((f) => ({ ...f, subject: e.target.value }))
                    }
                    placeholder="Billing question"
                    className={fieldClass}
                  />
                </div>
                <div>
                  <label className="text-sm font-medium text-stone-700">
                    Message
                  </label>
                  <textarea
                    required
                    value={form.message}
                    onChange={(e) =>
                      setForm((f) => ({ ...f, message: e.target.value }))
                    }
                    placeholder="How can we help?"
                    className={`${fieldClass} min-h-32 resize-none`}
                  />
                </div>
                <button
                  type="submit"
                  className="rounded-full bg-stone-950 px-6 py-3 text-sm font-semibold text-white shadow-sm transition-transform hover:scale-[1.03] active:scale-[0.98]"
                >
                  Send Message
                </button>
              </form>
            )}
          </div>

          {/* info */}
          <div className="grid grid-cols-1 gap-5 sm:grid-cols-2">
            {INFO.map((item) => (
              <div
                key={item.label}
                className="rounded-2xl bg-[#F5F0E6] p-6"
              >
                <span className="flex size-10 items-center justify-center rounded-full bg-white shadow-sm">
                  <item.icon className="size-4 text-stone-700" />
                </span>
                <p className="mt-4 text-xs font-semibold tracking-wide text-stone-500 uppercase">
                  {item.label}
                </p>
                <p className="mt-1 text-sm text-stone-800">{item.value}</p>
              </div>
            ))}
          </div>
        </div>
      </section>
    </>
  );
}
