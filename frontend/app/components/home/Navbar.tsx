import { useState } from "react";
import { Link } from "react-router";
import { Activity, Menu } from "lucide-react";
import {
  Sheet,
  SheetContent,
  SheetHeader,
  SheetTitle,
  SheetTrigger,
} from "@/components/ui/sheet";

const NAV_LINKS = [
  { label: "About", href: "/about" },
  { label: "Services", href: "/services" },
  { label: "Doctors", href: "/team" },
  { label: "Blog", href: "/blog" },
  { label: "Contact", href: "/contact" },
];

export default function Navbar() {
  const [open, setOpen] = useState(false);

  return (
    <header className="sticky top-4 z-50 mx-auto w-full max-w-6xl px-4">
      <div className="flex items-center justify-between gap-4 rounded-full border border-black/5 bg-white/90 px-5 py-3 shadow-[0_8px_30px_-12px_rgba(0,0,0,0.15)] backdrop-blur-md">
        <Link to="/" className="flex items-center gap-2">
          <span className="flex size-8 items-center justify-center rounded-full bg-linear-to-tr from-blue-600 to-indigo-600 shadow-lg shadow-blue-500/30">
            <Activity className="size-4 text-white" strokeWidth={2.5} />
          </span>
          <span className="font-display text-lg font-semibold tracking-tight text-stone-900">
            Ask Musawo
          </span>
        </Link>

        <nav className="hidden items-center gap-8 md:flex">
          {NAV_LINKS.map((link) => (
            <Link
              key={link.label}
              to={link.href}
              className="text-sm font-medium text-stone-600 transition-colors hover:text-stone-950"
            >
              {link.label}
            </Link>
          ))}
        </nav>

        <div className="flex items-center gap-3">
          <Link
            to="/login"
            className="hidden text-sm font-medium text-stone-600 hover:text-stone-950 sm:inline-flex"
          >
            Sign In
          </Link>
          <div className="hidden h-5 w-px bg-stone-200 sm:block" />
          <Link
            to="/book-appointment"
            className="hidden rounded-full bg-stone-950 px-5 py-2.5 text-sm font-semibold text-white shadow-sm transition-transform hover:scale-[1.03] active:scale-[0.98] md:inline-flex"
          >
            Book Appointment
          </Link>

          <Sheet open={open} onOpenChange={setOpen}>
            <SheetTrigger asChild>
              <button
                className="inline-flex text-stone-600 hover:text-stone-950 md:hidden"
                aria-label="Open menu"
              >
                <Menu className="size-5" />
              </button>
            </SheetTrigger>
            <SheetContent side="right">
              <SheetHeader>
                <SheetTitle className="font-display">Ask Musawo</SheetTitle>
              </SheetHeader>
              <nav className="flex flex-col gap-1 px-4">
                {NAV_LINKS.map((link) => (
                  <Link
                    key={link.label}
                    to={link.href}
                    onClick={() => setOpen(false)}
                    className="rounded-lg px-3 py-2.5 text-sm font-medium text-stone-700 hover:bg-stone-100"
                  >
                    {link.label}
                  </Link>
                ))}
                <Link
                  to="/login"
                  onClick={() => setOpen(false)}
                  className="mt-3 rounded-lg px-3 py-2.5 text-sm font-medium text-stone-700 hover:bg-stone-100"
                >
                  Sign In
                </Link>
                <Link
                  to="/book-appointment"
                  onClick={() => setOpen(false)}
                  className="mt-2 rounded-full bg-stone-950 px-4 py-2.5 text-center text-sm font-semibold text-white"
                >
                  Book Appointment
                </Link>
              </nav>
            </SheetContent>
          </Sheet>
        </div>
      </div>
    </header>
  );
}
