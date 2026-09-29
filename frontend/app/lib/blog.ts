import type { BlogAccent, BlogPost } from "@/types";

// Literal class names so Tailwind keeps them in the build.
export const ACCENT_CLASS: Record<BlogAccent, string> = {
  lime: "bg-lime-100",
  sky: "bg-sky-100",
  amber: "bg-amber-100",
  orange: "bg-orange-100",
  rose: "bg-rose-100",
  violet: "bg-violet-100",
};

export const BLOG_ACCENTS = Object.keys(ACCENT_CLASS) as BlogAccent[];

export const accentClass = (accent: string) =>
  ACCENT_CLASS[accent as BlogAccent] ?? ACCENT_CLASS.sky;

export const paragraphs = (content: string) =>
  content
    .split(/\n\s*\n/)
    .map((p) => p.trim())
    .filter(Boolean);

/** Rough reading time at ~200 words a minute, never under a minute. */
export const readingMinutes = (content: string) =>
  Math.max(1, Math.round(content.trim().split(/\s+/).length / 200));

export const postDate = (post: Pick<BlogPost, "publishedAt" | "createdAt">) =>
  new Date(post.publishedAt ?? post.createdAt).toLocaleDateString("en-GB", {
    day: "numeric",
    month: "short",
    year: "numeric",
  });
