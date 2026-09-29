import { Link } from "react-router";
import { ArrowRight } from "lucide-react";
import type { BlogPost } from "@/types";
import Reveal from "@/components/home/Reveal";
import BlogCard, { blogCardClass } from "@/components/home/BlogCard";

export default function BlogSection({ posts }: { posts: BlogPost[] }) {
  if (posts.length === 0) return null;

  return (
    <section className="bg-white pb-28">
      <div className="mx-auto max-w-6xl px-6 md:px-4">
        <Reveal className="flex items-end justify-between">
          <h2 className="font-display text-4xl font-medium text-stone-900">
            The latest from{" "}
            <span className="text-orange-600">Ask Musawo</span>
          </h2>
          <Link
            to="/blog"
            className="hidden items-center gap-1.5 text-sm font-semibold text-stone-900 underline underline-offset-4 sm:flex"
          >
            Read All Blog <ArrowRight className="size-4" />
          </Link>
        </Reveal>

        <div className="mt-12 grid grid-cols-1 gap-6 sm:grid-cols-3">
          {posts.map((post, i) => (
            <Reveal
              as="article"
              key={post.slug}
              delay={i * 100}
              className={blogCardClass(post)}
            >
              <BlogCard post={post} titleWidth="max-w-[10rem]" />
            </Reveal>
          ))}
        </div>

        <Link
          to="/blog"
          className="mt-10 flex items-center justify-center gap-1.5 text-sm font-semibold text-stone-900 underline underline-offset-4 sm:hidden"
        >
          Read All Blog <ArrowRight className="size-4" />
        </Link>
      </div>
    </section>
  );
}
