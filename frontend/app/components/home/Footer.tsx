import { useState } from "react";
import { Link } from "react-router";
import {
  Activity,
  Instagram,
  Linkedin,
  Mail,
  MapPin,
  Phone,
  X,
} from "lucide-react";

const QUICK_LINKS = [
  { label: "About", href: "/about" },
  { label: "Services", href: "/services" },
  { label: "Doctors", href: "/team" },
  { label: "Blog", href: "/blog" },
  { label: "Contact", href: "/contact" },
  { label: "FAQ", href: "/faq" },
  { label: "Careers", href: "/careers" },
  { label: "Book Appointment", href: "/book-appointment" },
];

const SERVICE_LINKS = [
  "Emergency Care",
  "Inpatient Care",
  "Diagnostic Imaging",
  "Laboratory Services",
  "Maternity & Newborn",
  "Outpatient Clinics",
  "Telehealth Visits",
  "Pharmacy",
];

export default function Footer() {
  const [email, setEmail] = useState("");
  const [subscribed, setSubscribed] = useState(false);

  return (
    <footer className="bg-[#1B140F] pt-20 pb-8 text-stone-300">
      <div className="mx-auto max-w-6xl px-6 md:px-4">
        <div className="grid grid-cols-1 gap-12 border-b border-white/10 pb-14 sm:grid-cols-2 lg:grid-cols-5">
          {/* brand */}
          <div className="lg:col-span-2">
            <Link to="/" className="flex items-center gap-2">
              <span className="flex size-8 items-center justify-center rounded-full bg-linear-to-tr from-blue-600 to-indigo-600">
                <Activity className="size-4 text-white" strokeWidth={2.5} />
              </span>
              <span className="font-display text-lg font-semibold text-white">
                Ask Musawo
              </span>
            </Link>

            <span className="mt-6 inline-flex items-center rounded-full border border-white/20 px-4 py-1.5 text-[11px] font-semibold tracking-wider text-stone-300 uppercase">
              AI-powered care
            </span>

            <p className="mt-5 max-w-xs text-sm leading-relaxed text-stone-400">
              Real-time patient monitoring and AI-assisted diagnostics for
              modern hospitals — coordinated care from triage to recovery.
            </p>

            <ul className="mt-6 space-y-3 text-sm text-stone-400">
              <li className="flex items-start gap-2.5">
                <MapPin className="mt-0.5 size-4 shrink-0 text-stone-500" />
                14 Acacia Avenue, Kololo, Kampala, Uganda
              </li>
              <li className="flex items-center gap-2.5">
                <Phone className="size-4 shrink-0 text-stone-500" />
                <a href="tel:+256414255900" className="hover:text-white">
                  +256 414 255 900
                </a>
              </li>
              <li className="flex items-center gap-2.5">
                <Mail className="size-4 shrink-0 text-stone-500" />
                <a
                  href="mailto:care@askmusawo.co.ug"
                  className="hover:text-white"
                >
                  care@askmusawo.co.ug
                </a>
              </li>
            </ul>

            <div className="mt-8 flex items-baseline gap-10">
              <div>
                <span className="font-display text-4xl text-white">
                  12<span className="text-xl">k+</span>
                </span>
                <p className="mt-1 text-xs text-stone-400">Patients served</p>
              </div>
              <div>
                <span className="font-display text-4xl text-white">
                  98<span className="text-xl">%</span>
                </span>
                <p className="mt-1 text-xs text-stone-400">
                  Satisfaction rate
                </p>
              </div>
            </div>
          </div>

          {/* quick links */}
          <div>
            <h3 className="text-xs font-semibold tracking-widest text-white uppercase">
              Quick Links
            </h3>
            <ul className="mt-5 space-y-3">
              {QUICK_LINKS.map((link) => (
                <li key={link.label}>
                  <Link
                    to={link.href}
                    className="text-sm font-medium text-stone-400 hover:text-white"
                  >
                    {link.label}
                  </Link>
                </li>
              ))}
            </ul>
          </div>

          {/* services */}
          <div>
            <h3 className="text-xs font-semibold tracking-widest text-white uppercase">
              Services
            </h3>
            <ul className="mt-5 space-y-3">
              {SERVICE_LINKS.map((service) => (
                <li key={service}>
                  <Link
                    to="/services"
                    className="text-sm font-medium text-stone-400 hover:text-white"
                  >
                    {service}
                  </Link>
                </li>
              ))}
            </ul>
          </div>

          {/* newsletter */}
          <div>
            <h3 className="text-xs font-semibold tracking-widest text-white uppercase">
              Stay Updated
            </h3>
            <p className="mt-5 text-sm font-medium text-stone-400">
              Health tips and hospital news, straight to your inbox.
            </p>

            {subscribed ? (
              <p className="mt-4 text-sm text-emerald-400">
                Thanks — you're on the list.
              </p>
            ) : (
              <form
                onSubmit={(e) => {
                  e.preventDefault();
                  if (email.trim()) setSubscribed(true);
                }}
                className="mt-4 flex max-w-sm items-center gap-2 rounded-full border border-white/15 bg-white/5 p-1.5 pl-4"
              >
                <input
                  type="email"
                  required
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  placeholder="Email address"
                  className="w-full bg-transparent text-sm text-white placeholder:text-stone-500 focus:outline-none"
                />
                <button
                  type="submit"
                  aria-label="Subscribe"
                  className="flex size-9 shrink-0 items-center justify-center rounded-full bg-amber-400 text-stone-900 transition-transform hover:scale-105 active:scale-95"
                >
                  <Mail className="size-4" />
                </button>
              </form>
            )}

            <div className="mt-8 flex items-center gap-4">
              <a
                href="#"
                aria-label="X (Twitter)"
                className="flex size-9 items-center justify-center rounded-full border border-white/15 text-stone-300 hover:border-white/30 hover:text-white"
              >
                <X className="size-4" />
              </a>
              <a
                href="#"
                aria-label="Instagram"
                className="flex size-9 items-center justify-center rounded-full border border-white/15 text-stone-300 hover:border-white/30 hover:text-white"
              >
                <Instagram className="size-4" />
              </a>
              <a
                href="#"
                aria-label="LinkedIn"
                className="flex size-9 items-center justify-center rounded-full border border-white/15 text-stone-300 hover:border-white/30 hover:text-white"
              >
                <Linkedin className="size-4" />
              </a>
            </div>
          </div>
        </div>

        <div className="flex flex-col items-center gap-4 pt-8 sm:flex-row sm:justify-between">
          <p className="text-xs text-stone-500">
            © 2026 Ask Musawo. All Rights Reserved
          </p>
          <div className="flex items-center gap-5 text-xs text-stone-500">
            <a href="#" className="hover:text-white">
              Privacy
            </a>
            <a href="#" className="hover:text-white">
              Terms
            </a>
            <a href="#" className="hover:text-white">
              Sitemap
            </a>
          </div>
        </div>
      </div>
    </footer>
  );
}
