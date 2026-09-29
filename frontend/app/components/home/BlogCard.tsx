import { Link } from "react-router";
import { Clock, Plus } from "lucide-react";
import type { BlogPost } from "@/types";
import { accentClass, postDate, readingMinutes } from "@/lib/blog";

export default function BlogCard({
  post,
  showCategory = false,
  titleWidth = "max-w-[12rem]",
}: {
  post: BlogPost;
  showCategory?: boolean;
  titleWidth?: string;
}) {
  return (
    <>
      <div>
        <p className="text-xs font-medium text-stone-500">
          {postDate(post)}
          {showCategory ? ` · ${post.category}` : ""}
        </p>
        <h3
          className={`font-display mt-3 ${titleWidth} text-xl leading-snug font-medium text-stone-900`}
        >
          {post.title}
        </h3>
        <div className="mt-3 flex items-center gap-1.5 text-xs text-stone-500">
          <Clock className="size-3.5" />
          {readingMinutes(post.content)} min read
        </div>
      </div>

      <Link
        to={`/blog/${post.slug}`}
        className="inline-flex w-fit items-center gap-1.5 rounded-full bg-white px-4 py-2 text-xs font-semibold text-stone-900 shadow-sm transition-transform hover:scale-[1.03] active:scale-[0.98]"
      >
        Read More <Plus className="size-3.5" />
      </Link>

      {post.image && (
        <div className="absolute -right-4 -bottom-4 size-28 overflow-hidden rounded-full border-4 border-white/60 shadow-lg">
          <img src={post.image} alt="" className="h-full w-full object-cover" />
        </div>
      )}
    </>
  );
}

export const blogCardClass = (post: BlogPost) =>
  `relative flex h-72 flex-col justify-between overflow-hidden rounded-3xl p-6 ${accentClass(post.accent)}`;
