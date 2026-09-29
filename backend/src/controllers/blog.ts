import type { Request, Response } from "express";
import { prisma } from "../lib/prisma";

// Marketing-site blog. Public readers only ever see published posts;
// admins manage everything from Settings → Content Management.

const ACCENTS = ["lime", "sky", "amber", "orange", "rose", "violet"];

const slugify = (text: string) =>
  text
    .toLowerCase()
    .normalize("NFKD")
    .replace(/[^\w\s-]/g, "")
    .trim()
    .replace(/[\s_-]+/g, "-")
    .replace(/^-+|-+$/g, "")
    .slice(0, 80);

export const listPublishedPosts = async (req: Request, res: Response) => {
  try {
    const limit = Math.min(50, Math.max(1, parseInt(req.query.limit as string) || 50));
    const posts = await prisma.blogPost.findMany({
      where: { published: true, publishedAt: { lte: new Date() } },
      orderBy: { publishedAt: "desc" },
      take: limit,
    });
    res.json(posts);
  } catch (error) {
    console.error("Error listing blog posts:", error);
    res.status(500).json({ message: "Server error" });
  }
};

export const getPublishedPost = async (req: Request, res: Response) => {
  try {
    const post = await prisma.blogPost.findFirst({
      where: { slug: req.params.slug as string, published: true, publishedAt: { lte: new Date() } },
    });
    if (!post) return res.status(404).json({ message: "Post not found" });
    res.json(post);
  } catch (error) {
    console.error("Error fetching blog post:", error);
    res.status(500).json({ message: "Server error" });
  }
};

export const listAllPosts = async (_req: Request, res: Response) => {
  try {
    res.json(await prisma.blogPost.findMany({ orderBy: { updatedAt: "desc" } }));
  } catch (error) {
    console.error("Error listing all blog posts:", error);
    res.status(500).json({ message: "Server error" });
  }
};

function parseBody(body: any, requireAll: boolean) {
  const data: Record<string, unknown> = {};
  const text = (k: string) => (typeof body[k] === "string" ? body[k].trim() : undefined);
  for (const k of ["title", "excerpt", "content", "category"]) {
    const v = text(k);
    if (v !== undefined) {
      if (!v) throw new Error(`${k} can't be empty`);
      data[k] = v;
    } else if (requireAll) {
      throw new Error(`${k} is required`);
    }
  }
  if (body.slug !== undefined || requireAll) {
    const slug = slugify(text("slug") || (data.title as string) || "");
    if (!slug) throw new Error("slug is required");
    data.slug = slug;
  }
  if (body.image !== undefined) {
    const image = text("image") || null;
    if (image && !/^https?:\/\//.test(image)) throw new Error("image must be an http(s) URL");
    data.image = image;
  }
  if (body.accent !== undefined) {
    if (!ACCENTS.includes(body.accent)) throw new Error(`accent must be one of ${ACCENTS.join(", ")}`);
    data.accent = body.accent;
  }
  if (body.authorName !== undefined) data.authorName = text("authorName") || null;
  return data;
}

export const createPost = async (req: Request, res: Response) => {
  try {
    const data = parseBody(req.body, true);
    if (await prisma.blogPost.findUnique({ where: { slug: data.slug as string } })) {
      return res.status(409).json({ message: "Another post already uses this slug" });
    }
    const publish = req.body.published === true;
    const post = await prisma.blogPost.create({
      data: {
        ...(data as any),
        authorName: (data.authorName as string) ?? (req as any).user.name,
        published: publish,
        publishedAt: publish ? new Date() : null,
      },
    });
    res.status(201).json(post);
  } catch (error: any) {
    if (error instanceof Error && !("code" in error)) {
      return res.status(400).json({ message: error.message });
    }
    console.error("Error creating blog post:", error);
    res.status(500).json({ message: "Server error" });
  }
};

export const updatePost = async (req: Request, res: Response) => {
  try {
    const id = req.params.id as string;
    const existing = await prisma.blogPost.findUnique({ where: { id } });
    if (!existing) return res.status(404).json({ message: "Post not found" });
    const data = parseBody(req.body, false);
    if (data.slug && data.slug !== existing.slug) {
      if (await prisma.blogPost.findUnique({ where: { slug: data.slug as string } })) {
        return res.status(409).json({ message: "Another post already uses this slug" });
      }
    }
    if (typeof req.body.published === "boolean") {
      data.published = req.body.published;
      // Keep the original publish date when re-publishing.
      data.publishedAt = req.body.published ? (existing.publishedAt ?? new Date()) : existing.publishedAt;
    }
    res.json(await prisma.blogPost.update({ where: { id }, data }));
  } catch (error: any) {
    if (error instanceof Error && !("code" in error)) {
      return res.status(400).json({ message: error.message });
    }
    console.error("Error updating blog post:", error);
    res.status(500).json({ message: "Server error" });
  }
};

export const deletePost = async (req: Request, res: Response) => {
  try {
    await prisma.blogPost.delete({ where: { id: req.params.id as string } });
    res.status(204).end();
  } catch (error: any) {
    if (error?.code === "P2025") return res.status(404).json({ message: "Post not found" });
    console.error("Error deleting blog post:", error);
    res.status(500).json({ message: "Server error" });
  }
};
