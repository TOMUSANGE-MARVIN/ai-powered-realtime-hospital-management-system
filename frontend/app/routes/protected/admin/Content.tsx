import { useState } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { toast } from "sonner";
import { ExternalLink, FilePlus2, Pencil, Trash2 } from "lucide-react";
import { authClient } from "@/lib/auth-client";
import { createPost, deletePost, getAllPosts, updatePost } from "@/lib/api";
import { BLOG_ACCENTS, accentClass, paragraphs, postDate, readingMinutes } from "@/lib/blog";
import { UploadButton } from "@/lib/uploadthing";
import type { BlogAccent, BlogPost } from "@/types";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
import {
  Dialog,
  DialogContent,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import { Textarea } from "@/components/ui/textarea";
import Loader from "@/components/global/Loader";

export function meta() {
  return [{ title: "Content Management | Ask Musawo" }];
}

type Draft = {
  title: string;
  slug: string;
  excerpt: string;
  category: string;
  image: string;
  accent: BlogAccent;
  content: string;
};

const EMPTY: Draft = {
  title: "",
  slug: "",
  excerpt: "",
  category: "",
  image: "",
  accent: "sky",
  content: "",
};

const slugify = (text: string) =>
  text
    .toLowerCase()
    .normalize("NFKD")
    .replace(/[^\w\s-]/g, "")
    .trim()
    .replace(/[\s_-]+/g, "-")
    .replace(/^-+|-+$/g, "")
    .slice(0, 80);

function Editor({
  post,
  onDone,
}: {
  post: BlogPost | null;
  onDone: () => void;
}) {
  const queryClient = useQueryClient();
  const [draft, setDraft] = useState<Draft>(
    post
      ? {
          title: post.title,
          slug: post.slug,
          excerpt: post.excerpt,
          category: post.category,
          image: post.image ?? "",
          accent: post.accent,
          content: post.content,
        }
      : EMPTY,
  );
  const [slugTouched, setSlugTouched] = useState(!!post);
  const set = <K extends keyof Draft>(k: K, v: Draft[K]) =>
    setDraft((d) => ({
      ...d,
      [k]: v,
      ...(k === "title" && !slugTouched ? { slug: slugify(String(v)) } : {}),
    }));

  const save = useMutation({
    mutationFn: (publish?: boolean) => {
      const data = {
        ...draft,
        image: draft.image.trim() || null,
        ...(publish === undefined ? {} : { published: publish }),
      } as Partial<BlogPost>;
      return post ? updatePost({ id: post.id, data }) : createPost(data);
    },
    onSuccess: (saved) => {
      toast.success(saved.published ? "Saved and published" : "Saved as draft");
      queryClient.invalidateQueries({ queryKey: ["blog-admin"] });
      onDone();
    },
    onError: (e: any) => toast.error(e.message),
  });

  const ready =
    draft.title.trim() && draft.excerpt.trim() && draft.category.trim() && draft.content.trim();
  const body = paragraphs(draft.content);

  return (
    <div className="grid grid-cols-1 xl:grid-cols-2 gap-6">
      <Card className="card shadow-sm">
        <CardHeader>
          <CardTitle>{post ? "Edit post" : "New post"}</CardTitle>
          <CardDescription>
            {post?.published ? "This post is live on the website." : "Drafts are only visible here."}
          </CardDescription>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="space-y-2">
            <Label htmlFor="post-title">Title</Label>
            <Input id="post-title" value={draft.title} onChange={(e) => set("title", e.target.value)} />
          </div>
          <div className="space-y-2">
            <Label htmlFor="post-slug">Web address</Label>
            <div className="flex items-center gap-1 text-sm text-muted-foreground">
              /blog/
              <Input
                id="post-slug"
                value={draft.slug}
                onChange={(e) => {
                  setSlugTouched(true);
                  set("slug", slugify(e.target.value));
                }}
              />
            </div>
            {post?.published && draft.slug !== post.slug && (
              <p className="text-xs text-amber-600">
                Changing the address breaks links people already shared.
              </p>
            )}
          </div>
          <div className="grid grid-cols-2 gap-4">
            <div className="space-y-2">
              <Label htmlFor="post-category">Category</Label>
              <Input
                id="post-category"
                placeholder="e.g. Wellness"
                value={draft.category}
                onChange={(e) => set("category", e.target.value)}
              />
            </div>
            <div className="space-y-2">
              <Label>Card colour</Label>
              <div className="flex gap-2 pt-1">
                {BLOG_ACCENTS.map((a) => (
                  <button
                    key={a}
                    type="button"
                    title={a}
                    aria-label={a}
                    onClick={() => set("accent", a)}
                    className={`size-7 rounded-full border ${accentClass(a)} ${draft.accent === a ? "ring-2 ring-primary ring-offset-2 ring-offset-background" : ""}`}
                  />
                ))}
              </div>
            </div>
          </div>
          <div className="space-y-2">
            <Label htmlFor="post-excerpt">Summary</Label>
            <Textarea
              id="post-excerpt"
              rows={2}
              maxLength={300}
              value={draft.excerpt}
              onChange={(e) => set("excerpt", e.target.value)}
            />
          </div>
          <div className="space-y-2">
            <Label htmlFor="post-image">Cover image</Label>
            <div className="flex gap-2">
              <Input
                id="post-image"
                placeholder="https://…"
                value={draft.image}
                onChange={(e) => set("image", e.target.value)}
              />
              <UploadButton
                endpoint="imageUploader"
                headers={async () => {
                  const session = await authClient.getSession();
                  return { Authorization: `Bearer ${session.data?.session.token}` };
                }}
                onClientUploadComplete={(res) => {
                  set("image", res[0].ufsUrl);
                  toast.success("Image uploaded");
                }}
                onUploadError={(e: Error) => {
                  toast.error(e.message);
                }}
                appearance={{
                  button: "h-9 px-3 text-sm bg-primary text-primary-foreground rounded-md",
                  allowedContent: "hidden",
                }}
                content={{ button: "Upload" }}
              />
            </div>
          </div>
          <div className="space-y-2">
            <Label htmlFor="post-content">Article</Label>
            <Textarea
              id="post-content"
              rows={14}
              placeholder="Write the article. Leave a blank line between paragraphs."
              value={draft.content}
              onChange={(e) => set("content", e.target.value)}
            />
            <p className="text-xs text-muted-foreground">
              {body.length} paragraph{body.length === 1 ? "" : "s"} · about{" "}
              {readingMinutes(draft.content || " ")} min read
            </p>
          </div>
          <div className="flex flex-wrap gap-2 pt-2">
            <Button variant="outline" onClick={onDone}>
              Cancel
            </Button>
            <Button
              variant="outline"
              disabled={!ready || save.isPending}
              onClick={() => save.mutate(post ? undefined : false)}
            >
              {post ? "Save changes" : "Save draft"}
            </Button>
            {!post?.published && (
              <Button disabled={!ready || save.isPending} onClick={() => save.mutate(true)}>
                Save and publish
              </Button>
            )}
          </div>
        </CardContent>
      </Card>

      <div className="space-y-4">
        <h3 className="text-sm font-bold uppercase tracking-wide text-muted-foreground">
          Preview
        </h3>
        <div
          className={`relative flex h-72 flex-col justify-between overflow-hidden rounded-3xl p-6 ${accentClass(draft.accent)}`}
        >
          {draft.image && (
            <img
              src={draft.image}
              alt=""
              className="absolute inset-0 h-full w-full object-cover opacity-30"
            />
          )}
          <div className="relative flex items-center gap-2 text-xs text-slate-700">
            <span className="rounded-full bg-white/70 px-2 py-0.5 font-semibold">
              {draft.category || "Category"}
            </span>
            {readingMinutes(draft.content || " ")} min read
          </div>
          <div className="relative space-y-2">
            <h4 className="text-xl font-bold text-slate-900">{draft.title || "Post title"}</h4>
            <p className="text-sm text-slate-700 line-clamp-3">
              {draft.excerpt || "The summary shows on the blog card."}
            </p>
          </div>
        </div>
        <article className="card rounded-xl p-6 shadow-sm space-y-3 max-h-[480px] overflow-y-auto">
          {body.length === 0 ? (
            <p className="text-sm text-muted-foreground">The article body previews here.</p>
          ) : (
            body.map((p, i) => (
              <p key={i} className="leading-relaxed">
                {p}
              </p>
            ))
          )}
        </article>
      </div>
    </div>
  );
}

export default function Content() {
  const queryClient = useQueryClient();
  const [editing, setEditing] = useState<BlogPost | "new" | null>(null);
  const [deleting, setDeleting] = useState<BlogPost | null>(null);

  const { data, isLoading, isError } = useQuery({
    queryKey: ["blog-admin"],
    queryFn: getAllPosts,
  });

  const togglePublish = useMutation({
    mutationFn: (post: BlogPost) => updatePost({ id: post.id, data: { published: !post.published } }),
    onSuccess: (post) => {
      toast.success(post.published ? "Published" : "Moved back to drafts");
      queryClient.invalidateQueries({ queryKey: ["blog-admin"] });
    },
    onError: (e: any) => toast.error(e.message),
  });
  const remove = useMutation({
    mutationFn: (post: BlogPost) => deletePost(post.id),
    onSuccess: () => {
      toast.success("Post deleted");
      setDeleting(null);
      queryClient.invalidateQueries({ queryKey: ["blog-admin"] });
    },
    onError: (e: any) => toast.error(e.message),
  });

  if (editing) {
    return (
      <div className="space-y-6">
        <h1 className="text-3xl font-black tracking-tight">Content Management</h1>
        <Editor
          key={editing === "new" ? "new" : editing.id}
          post={editing === "new" ? null : editing}
          onDone={() => setEditing(null)}
        />
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <div className="flex flex-col md:flex-row md:items-end justify-between gap-4">
        <div>
          <h1 className="text-3xl font-black tracking-tight">Content Management</h1>
          <p className="text-slate-500 font-medium">
            Write and publish the health articles on the website's blog.
          </p>
        </div>
        <Button className="gap-2" onClick={() => setEditing("new")}>
          <FilePlus2 size={16} /> New post
        </Button>
      </div>

      <Card className="card shadow-sm">
        <CardHeader>
          <CardTitle>Blog posts</CardTitle>
          <CardDescription>
            {data
              ? (() => {
                  const drafts = data.filter((p) => !p.published).length;
                  return `${data.length - drafts} published · ${drafts} draft${drafts === 1 ? "" : "s"}`;
                })()
              : " "}
          </CardDescription>
        </CardHeader>
        <CardContent className="p-0">
          {isLoading ? (
            <div className="flex justify-center py-12">
              <Loader label="Loading posts..." />
            </div>
          ) : isError || !data ? (
            <div className="p-10 text-center text-red-500">Failed to load posts.</div>
          ) : (
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead className="pl-6">Post</TableHead>
                  <TableHead>Category</TableHead>
                  <TableHead>Status</TableHead>
                  <TableHead>Date</TableHead>
                  <TableHead className="text-right pr-6">Actions</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {data.length === 0 ? (
                  <TableRow>
                    <TableCell colSpan={5} className="text-center h-24 text-muted-foreground">
                      No posts yet.
                    </TableCell>
                  </TableRow>
                ) : (
                  data.map((post) => (
                    <TableRow key={post.id}>
                      <TableCell className="pl-6">
                        <div className="flex items-center gap-3">
                          <span className={`size-10 shrink-0 rounded-lg ${accentClass(post.accent)} overflow-hidden`}>
                            {post.image && (
                              <img src={post.image} alt="" className="h-full w-full object-cover" />
                            )}
                          </span>
                          <div className="min-w-0">
                            <div className="font-semibold truncate max-w-md">{post.title}</div>
                            <div className="text-xs text-muted-foreground">/blog/{post.slug}</div>
                          </div>
                        </div>
                      </TableCell>
                      <TableCell>{post.category}</TableCell>
                      <TableCell>
                        {post.published ? (
                          <Badge className="bg-emerald-100 text-emerald-700 dark:bg-emerald-900/30 dark:text-emerald-400">
                            Published
                          </Badge>
                        ) : (
                          <Badge variant="secondary">Draft</Badge>
                        )}
                      </TableCell>
                      <TableCell className="text-sm">
                        {post.published ? postDate(post) : `Edited ${new Date(post.updatedAt).toLocaleDateString()}`}
                      </TableCell>
                      <TableCell className="pr-6">
                        <div className="flex justify-end gap-1">
                          {post.published && (
                            <Button variant="ghost" size="icon" asChild title="View on website">
                              <a href={`/blog/${post.slug}`} target="_blank" rel="noreferrer">
                                <ExternalLink size={16} />
                              </a>
                            </Button>
                          )}
                          <Button variant="ghost" size="icon" title="Edit" onClick={() => setEditing(post)}>
                            <Pencil size={16} />
                          </Button>
                          <Button
                            variant="outline"
                            size="sm"
                            disabled={togglePublish.isPending}
                            onClick={() => togglePublish.mutate(post)}
                          >
                            {post.published ? "Unpublish" : "Publish"}
                          </Button>
                          <Button
                            variant="ghost"
                            size="icon"
                            title="Delete"
                            className="text-destructive"
                            onClick={() => setDeleting(post)}
                          >
                            <Trash2 size={16} />
                          </Button>
                        </div>
                      </TableCell>
                    </TableRow>
                  ))
                )}
              </TableBody>
            </Table>
          )}
        </CardContent>
      </Card>

      <Dialog open={!!deleting} onOpenChange={(open) => !open && setDeleting(null)}>
        <DialogContent className="card sm:max-w-md">
          <DialogHeader>
            <DialogTitle>Delete “{deleting?.title}”?</DialogTitle>
          </DialogHeader>
          <p className="text-sm text-muted-foreground">
            This removes the post permanently. To take it off the website but keep it,
            unpublish it instead.
          </p>
          <DialogFooter>
            <Button variant="outline" onClick={() => setDeleting(null)}>
              Cancel
            </Button>
            <Button
              variant="destructive"
              disabled={remove.isPending}
              onClick={() => deleting && remove.mutate(deleting)}
            >
              Delete post
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
}
