import { useState } from "react";
import type { Route } from "./+types/BookAppointment";
import { toast } from "sonner";
import { CalendarCheck, ChevronDown } from "lucide-react";
import PageHeader from "@/components/home/PageHeader";
import { useMutation } from "@tanstack/react-query";
import { requestAppointment } from "@/lib/api";

export function meta({}: Route.MetaArgs) {
  return [
    { title: "Book Appointment — Ask Musawo" },
    {
      name: "description",
      content: "Schedule a visit with a Ask Musawo specialist.",
    },
  ];
}

const DEPARTMENTS = [
  "Internal Medicine",
  "Pediatrics",
  "Emergency",
  "Orthopedics",
  "Cardiology",
  "Maternity",
];

const emptyForm = {
  name: "",
  email: "",
  phone: "",
  department: "",
  date: "",
  time: "",
  notes: "",
};

const fieldClass =
  "mt-1.5 w-full rounded-xl border border-stone-300 bg-white px-4 py-3 text-sm text-stone-900 placeholder:text-stone-400 outline-none transition-colors focus:border-stone-900 focus:ring-2 focus:ring-stone-900/10";

export default function BookAppointment() {
  const [form, setForm] = useState(emptyForm);
  const [submitted, setSubmitted] = useState(false);

  const mutation = useMutation({
    mutationFn: requestAppointment,
    onSuccess: () => {
      setSubmitted(true);
      toast.success("Appointment request received.");
    },
    onError: () => {
      toast.error("Failed to submit request. Please try again.");
    },
  });

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!form.name || !form.email || !form.department || !form.date) return;
    mutation.mutate({
      patientName: form.name,
      patientEmail: form.email,
      patientPhone: form.phone,
      department: form.department,
      date: form.date,
      time: form.time,
      reason: form.notes,
    });
  };

  return (
    <>
      <PageHeader
        eyebrow="Schedule a visit"
        title={
          <>
            Book your
            <br />
            appointment
          </>
        }
        description="Tell us a bit about what you need and pick a time that works — our scheduling team will confirm within one business day."
      />

      <section className="bg-white pb-28">
        <div className="mx-auto max-w-xl px-6 md:px-4">
          {submitted ? (
            <div className="rounded-3xl border border-stone-200 bg-stone-50 p-10 text-center">
              <span className="mx-auto flex size-14 items-center justify-center rounded-full bg-emerald-100">
                <CalendarCheck className="size-6 text-emerald-700" />
              </span>
              <h3 className="font-display mt-5 text-2xl font-medium text-stone-900">
                Request received
              </h3>
              <p className="mt-2 text-sm leading-relaxed text-stone-600">
                Thanks, {form.name.split(" ")[0]}. We'll confirm your{" "}
                {form.department} appointment for {form.date}
                {form.time && ` at ${form.time}`} by email at {form.email}.
              </p>
              <button
                type="button"
                onClick={() => {
                  setForm(emptyForm);
                  setSubmitted(false);
                }}
                className="mt-6 rounded-full bg-stone-950 px-6 py-2.5 text-sm font-semibold text-white"
              >
                Book another
              </button>
            </div>
          ) : (
            <form onSubmit={handleSubmit} className="space-y-5">
              <div className="grid grid-cols-1 gap-5 sm:grid-cols-2">
                <div>
                  <label className="text-sm font-medium text-stone-700">
                    Full name
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
                    Phone
                  </label>
                  <input
                    type="tel"
                    value={form.phone}
                    onChange={(e) =>
                      setForm((f) => ({ ...f, phone: e.target.value }))
                    }
                    placeholder="+256 772 123 456"
                    className={fieldClass}
                  />
                </div>
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
                  Department
                </label>
                <div className="relative">
                  <select
                    required
                    value={form.department}
                    onChange={(e) =>
                      setForm((f) => ({ ...f, department: e.target.value }))
                    }
                    className={`${fieldClass} appearance-none pr-10 ${
                      form.department ? "" : "text-stone-400"
                    }`}
                  >
                    <option value="" disabled>
                      Select a department
                    </option>
                    {DEPARTMENTS.map((dept) => (
                      <option key={dept} value={dept} className="text-stone-900">
                        {dept}
                      </option>
                    ))}
                  </select>
                  <ChevronDown className="pointer-events-none absolute top-1/2 right-4 size-4 -translate-y-1/2 text-stone-400" />
                </div>
              </div>

              <div className="grid grid-cols-1 gap-5 sm:grid-cols-2">
                <div>
                  <label className="text-sm font-medium text-stone-700">
                    Preferred date
                  </label>
                  <input
                    required
                    type="date"
                    value={form.date}
                    onChange={(e) =>
                      setForm((f) => ({ ...f, date: e.target.value }))
                    }
                    className={fieldClass}
                  />
                </div>
                <div>
                  <label className="text-sm font-medium text-stone-700">
                    Preferred time
                  </label>
                  <input
                    type="time"
                    value={form.time}
                    onChange={(e) =>
                      setForm((f) => ({ ...f, time: e.target.value }))
                    }
                    className={fieldClass}
                  />
                </div>
              </div>

              <div>
                <label className="text-sm font-medium text-stone-700">
                  Notes (optional)
                </label>
                <textarea
                  value={form.notes}
                  onChange={(e) =>
                    setForm((f) => ({ ...f, notes: e.target.value }))
                  }
                  placeholder="Reason for visit, symptoms, or anything else we should know"
                  className={`${fieldClass} min-h-28 resize-none`}
                />
              </div>

              <button
                type="submit"
                disabled={mutation.isPending}
                className="w-full rounded-full bg-stone-950 px-6 py-3 text-sm font-semibold text-white shadow-sm transition-transform hover:scale-[1.02] active:scale-[0.98] disabled:opacity-60"
              >
                {mutation.isPending ? "Submitting..." : "Request Appointment"}
              </button>
            </form>
          )}
        </div>
      </section>
    </>
  );
}
