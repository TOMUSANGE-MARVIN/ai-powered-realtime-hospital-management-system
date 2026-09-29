import type { Route } from "./+types/Blog";
import PageHeader from "@/components/home/PageHeader";
import BlogCard, { blogCardClass } from "@/components/home/BlogCard";
import { getPublishedPosts } from "@/lib/api";

export async function loader() {
  try {
    return { posts: await getPublishedPosts(), failed: false };
  } catch {
    return { posts: [], failed: true };
  }
}

export function meta({}: Route.MetaArgs) {
  return [
    { title: "Blog — Ask Musawo" },
    {
      name: "description",
      content:
        "Health tips and updates from the Ask Musawo care team — nutrition, recovery, mental health, and preventive care.",
    },
  ];
}

export default function Blog({ loaderData }: Route.ComponentProps) {
  const { posts, failed } = loaderData;
  return (
    <>
      <PageHeader
        eyebrow="From the care team"
        title={
          <>
            The latest from
            <br />
            Ask Musawo
          </>
        }
        description="Practical, evidence-based health tips from our specialists — no jargon, just what actually helps."
      />

      <section className="bg-white pb-28">
        <div className="mx-auto grid max-w-6xl grid-cols-1 gap-6 px-6 sm:grid-cols-2 md:px-4 lg:grid-cols-3">
          {posts.length === 0 && (
            <p className="col-span-full py-16 text-center text-stone-500">
              {failed
                ? "The blog can't be loaded right now. Please try again shortly."
                : "New articles are on the way."}
            </p>
          )}
          {posts.map((post) => (
            <article key={post.slug} className={blogCardClass(post)}>
              <BlogCard post={post} showCategory />
            </article>
          ))}
        </div>
      </section>
    </>
  );
}
