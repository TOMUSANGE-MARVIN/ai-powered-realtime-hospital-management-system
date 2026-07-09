import { Link } from "react-router";
import { ArrowRight, MessageCircle, Plus } from "lucide-react";
import { BLOG_POSTS } from "@/lib/blogPosts";
import Reveal from "@/components/home/Reveal";

export default function BlogSection() {
  const posts = BLOG_POSTS.slice(0, 3);

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
              className={`relative flex h-72 flex-col justify-between overflow-hidden rounded-3xl p-6 ${post.bg}`}
            >
              <div>
                <p className="text-xs font-medium text-stone-500">
                  {post.date}
                </p>
                <h3 className="font-display mt-3 max-w-[10rem] text-xl leading-snug font-medium text-stone-900">
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
