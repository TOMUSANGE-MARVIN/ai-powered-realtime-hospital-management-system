import type { ReactNode } from "react";

export default function PageHeader({
  eyebrow,
  title,
  description,
}: {
  eyebrow: string;
  title: ReactNode;
  description?: string;
}) {
  return (
    <section className="px-6 pt-16 pb-16 text-center md:px-4 md:pt-20">
      <div className="mx-auto max-w-2xl">
        <span className="inline-flex items-center rounded-full border border-stone-300 bg-white/70 px-4 py-1.5 text-[11px] font-semibold tracking-wider text-stone-600 uppercase">
          {eyebrow}
        </span>
        <h1 className="font-display mt-6 text-5xl leading-[1.05] font-medium text-stone-900 sm:text-6xl">
          {title}
        </h1>
        {description && (
          <p className="mt-6 text-[15px] leading-relaxed text-stone-600">
            {description}
          </p>
        )}
      </div>
    </section>
  );
}
