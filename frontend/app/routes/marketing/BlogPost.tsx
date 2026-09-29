import { Link } from "react-router";
import type { Route } from "./+types/BlogPost";
import { ArrowLeft, Clock } from "lucide-react";
import CtaBanner from "@/components/home/CtaBanner";
import { getPublishedPost } from "@/lib/api";
import { paragraphs, postDate, readingMinutes } from "@/lib/blog";

export async function loader({ params }: Route.LoaderArgs) {
  try {
    return { post: await getPublishedPost(params.slug) };
  } catch {
    return { post: null };
  }
}

export function meta({ data }: Route.MetaArgs) {
  const post = data?.post;
  return [
    { title: post ? `${post.title} — Ask Musawo` : "Blog — Ask Musawo" },
    { name: "description", content: post?.excerpt ?? "" },
  ];
}

export default function BlogPost({ loaderData }: Route.ComponentProps) {
  const { post } = loaderData;

  if (!post) {
    return (
      <section className="bg-white px-6 py-32 text-center">
        <h1 className="font-display text-3xl font-medium text-stone-900">
          Post not found
        </h1>
        <Link
          to="/blog"
          className="mt-6 inline-flex items-center gap-2 text-sm font-semibold text-stone-900 underline underline-offset-4"
        >
          <ArrowLeft className="size-4" /> Back to blog
        </Link>
      </section>
    );
  }

  return (
    <>
      <section className="px-6 pt-16 pb-12 md:px-4 md:pt-20">
        <div className="mx-auto max-w-2xl">
          <Link
            to="/blog"
            className="inline-flex items-center gap-2 text-sm font-semibold text-stone-600 hover:text-stone-900"
          >
            <ArrowLeft className="size-4" /> Back to blog
          </Link>

          <p className="mt-8 text-xs font-semibold tracking-wider text-stone-500 uppercase">
            {postDate(post)} · {post.category}
          </p>
          <h1 className="font-display mt-3 text-4xl leading-[1.1] font-medium text-stone-900 sm:text-5xl">
            {post.title}
          </h1>
          <div className="mt-4 flex items-center gap-1.5 text-sm text-stone-500">
            <Clock className="size-4" />
            {readingMinutes(post.content)} min read
            {post.authorName ? ` · ${post.authorName}` : ""}
          </div>
        </div>
      </section>

      <section className="bg-white pb-24">
        <div className="mx-auto max-w-2xl px-6 md:px-4">
          {post.image && (
            <div className="h-72 overflow-hidden rounded-[2rem] sm:h-96">
              <img
                src={post.image}
                alt={post.title}
                className="h-full w-full object-cover"
              />
            </div>
          )}

          <div className="mt-10 space-y-5">
            {paragraphs(post.content).map((paragraph, i) => (
              <p
                key={i}
                className="text-[15px] leading-relaxed text-stone-600"
              >
                {paragraph}
              </p>
            ))}
          </div>
        </div>
      </section>

      <CtaBanner />
    </>
  );
}
