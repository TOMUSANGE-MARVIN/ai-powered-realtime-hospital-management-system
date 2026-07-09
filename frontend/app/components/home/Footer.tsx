import { useState } from "react";
import { Link } from "react-router";
import { Activity, Instagram, Linkedin, Mail, Twitter } from "lucide-react";

const FOOTER_LINKS = [
  { label: "About", href: "/about" },
  { label: "Services", href: "/services" },
  { label: "Doctors", href: "/team" },
  { label: "Blog", href: "/blog" },
  { label: "Contact", href: "/contact" },
  { label: "FAQ", href: "/faq" },
  { label: "Careers", href: "/careers" },
];

export default function Footer() {
  const [email, setEmail] = useState("");
  const [subscribed, setSubscribed] = useState(false);

  return (
    <footer className="bg-[#1B140F] pt-20 pb-8 text-stone-300">
      <div className="mx-auto max-w-6xl px-6 md:px-4">
        <div className="grid grid-cols-1 gap-14 border-b border-white/10 pb-14 md:grid-cols-2">
          {/* left */}
          <div>
            <nav className="flex flex-wrap items-center gap-x-6 gap-y-2">
              {FOOTER_LINKS.map((link) => (
                <Link
                  key={link.label}
                  to={link.href}
                  className="text-sm font-medium text-stone-300 hover:text-white"
                >
                  {link.label}
                </Link>
              ))}
            </nav>

            <div className="mt-16 flex items-baseline gap-14">
              <div>
                <span className="font-display text-5xl text-white">
                  12<span className="text-2xl">k+</span>
                </span>
                <p className="mt-1 text-xs text-stone-400">Patients served</p>
              </div>
              <div>
                <span className="font-display text-5xl text-white">
                  98<span className="text-2xl">%</span>
                </span>
                <p className="mt-1 text-xs text-stone-400">
                  Satisfaction rate
                </p>
              </div>
            </div>
          </div>

          {/* right */}
          <div>
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

            <p className="mt-6 text-sm font-semibold text-white">
              Subscribe to our newsletter!
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
          </div>
        </div>

        <div className="flex flex-col items-center gap-6 pt-8 sm:flex-row sm:justify-between">
          <div className="flex items-center gap-5">
            <a href="#" aria-label="Twitter" className="hover:text-white">
              <Twitter className="size-4" />
            </a>
            <a href="#" aria-label="Instagram" className="hover:text-white">
              <Instagram className="size-4" />
            </a>
            <a href="#" aria-label="LinkedIn" className="hover:text-white">
              <Linkedin className="size-4" />
            </a>
          </div>
          <p className="text-xs text-stone-500">
            © 2026 Ask Musawo. All Rights Reserved
          </p>
          <div className="flex items-center gap-5 text-xs text-stone-500">
            <a href="#" className="hover:text-white">
              Privacy
            </a>
            <a href="#" className="hover:text-white">
              Sitemap
            </a>
          </div>
        </div>
      </div>

      <div className="mt-8 h-1 w-full bg-linear-to-r from-rose-500 via-orange-400 to-amber-300" />
    </footer>
  );
}
