import { Link } from "react-router";
import type { Route } from "./+types/Blog";
import { MessageCircle, Plus } from "lucide-react";
import PageHeader from "@/components/home/PageHeader";
import { BLOG_POSTS } from "@/lib/blogPosts";

export function meta({}: Route.MetaArgs) {
  return [
    { title: "Blog — MedFlow AI" },
    {
      name: "description",
      content:
        "Health tips and updates from the MedFlow AI care team — nutrition, recovery, mental health, and preventive care.",
    },
  ];
}

export default function Blog() {
  return (
    <>
      <PageHeader
        eyebrow="From the care team"
        title={
          <>
            The latest from
            <br />
            MedFlow AI
          </>
        }
        description="Practical, evidence-based health tips from our specialists — no jargon, just what actually helps."
      />

      <section className="bg-white pb-28">
        <div className="mx-auto grid max-w-6xl grid-cols-1 gap-6 px-6 sm:grid-cols-2 md:px-4 lg:grid-cols-3">
          {BLOG_POSTS.map((post) => (
            <article
              key={post.slug}
              className={`relative flex h-72 flex-col justify-between overflow-hidden rounded-3xl p-6 ${post.bg}`}
            >
              <div>
                <p className="text-xs font-medium text-stone-500">
                  {post.date} · {post.category}
                </p>
                <h3 className="font-display mt-3 max-w-[12rem] text-xl leading-snug font-medium text-stone-900">
                  {post.title}
                </h3>
                <div className="mt-3 flex items-center gap-1.5 text-xs text-stone-500">
                  <MessageCircle className="size-3.5" />
                  {post.comments}
                </div>
              </div>

              <Link
                to={`/blog/${post.slug}`}
                className="inline-flex w-fit items-center gap-1.5 rounded-full bg-white px-4 py-2 text-xs font-semibold text-stone-900 shadow-sm transition-transform hover:scale-[1.03] active:scale-[0.98]"
              >
                Read More <Plus className="size-3.5" />
              </Link>

              <div className="absolute -right-4 -bottom-4 size-28 overflow-hidden rounded-full border-4 border-white/60 shadow-lg">
                <img
                  src={post.image}
                  alt=""
                  className="h-full w-full object-cover"
                />
              </div>
            </article>
          ))}
        </div>
      </section>
    </>
  );
}
