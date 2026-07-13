import { useMemo, useState } from "react";
import { useMutation, useQuery } from "@tanstack/react-query";
import {
  getCategories,
  getCategoryOptions,
  createCategory,
  updateCategory,
  deleteCategory,
} from "@/lib/api";
import type { Category } from "@/types";
import { useForm } from "react-hook-form";
import { toast } from "sonner";
import {
  Card,
  CardContent,
  CardHeader,
  CardTitle,
  CardDescription,
} from "@/components/ui/card";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
} from "@/components/ui/dialog";
import { CustomInput } from "@/components/global/CustomInput";
import { CustomSelect } from "@/components/global/CustomSelect";
import GlobalSearch from "@/components/global/GlobalSearch";
import Loader from "@/components/global/Loader";
import { Tag, Plus } from "lucide-react";

export function meta() {
  return [{ title: "Categories | Ask Musawo" }];
}

// Purely cosmetic preview so the admin can see roughly what a colorKey looks
// like in this table — mobile owns the real accent pairs (app_colors.dart).
const COLOR_PREVIEW: Record<string, string> = {
  blue: "bg-blue-100 text-blue-700",
  teal: "bg-teal-100 text-teal-700",
  orange: "bg-orange-100 text-orange-700",
  pink: "bg-pink-100 text-pink-700",
  purple: "bg-purple-100 text-purple-700",
  red: "bg-red-100 text-red-700",
  indigo: "bg-indigo-100 text-indigo-700",
  amber: "bg-amber-100 text-amber-700",
  lavender: "bg-violet-100 text-violet-700",
};

const emptyCategory = {
  name: "",
  iconKey: "general",
  colorKey: "lavender",
  department: "",
};

function CategoryModal({
  category,
  onSaved,
}: {
  category?: Category;
  onSaved: () => void;
}) {
  const [open, setOpen] = useState(false);
  const form = useForm({
    defaultValues: category
      ? {
          name: category.name,
          iconKey: category.iconKey,
          colorKey: category.colorKey,
          department: category.department || "",
        }
      : emptyCategory,
  });

  const { data: options, isLoading: optionsLoading } = useQuery({
    queryKey: ["categoryOptions"],
    queryFn: getCategoryOptions,
    enabled: open,
  });

  const createMutation = useMutation({
    mutationFn: createCategory,
    onSuccess: () => {
      toast.success("Category added");
      setOpen(false);
      form.reset(emptyCategory);
      onSaved();
    },
    onError: (e: any) => toast.error(e.message || "Failed to add category"),
  });

  const updateMutation = useMutation({
    mutationFn: updateCategory,
    onSuccess: () => {
      toast.success("Category updated");
      setOpen(false);
      onSaved();
    },
    onError: (e: any) => toast.error(e.message || "Failed to update category"),
  });

  const onSubmit = (data: any) => {
    if (category) {
      updateMutation.mutate({ id: category.id, data });
    } else {
      createMutation.mutate(data);
    }
  };

  const isPending = createMutation.isPending || updateMutation.isPending;

  return (
    <Dialog open={open} onOpenChange={setOpen}>
      <DialogTrigger asChild>
        {category ? (
          <Button variant="outline" size="sm">
            Edit
          </Button>
        ) : (
          <Button className="gap-2">
            <Plus size={16} /> Add Category
          </Button>
        )}
      </DialogTrigger>
      <DialogContent className="sm:max-w-lg card">
        <DialogHeader>
          <DialogTitle>
            {category ? "Edit Category" : "Add Category"}
          </DialogTitle>
        </DialogHeader>
        <form onSubmit={form.handleSubmit(onSubmit)} className="space-y-3">
          <CustomInput
            control={form.control}
            name="name"
            label="Name"
            placeholder="e.g. Cardiology"
            disabled={isPending}
          />
          <CustomSelect
            control={form.control}
            name="iconKey"
            label="Icon"
            placeholder="Select icon"
            options={options?.icons.map((i) => ({ label: i.label, value: i.key })) || []}
            loading={optionsLoading}
            disabled={isPending}
          />
          <CustomSelect
            control={form.control}
            name="colorKey"
            label="Color"
            placeholder="Select color"
            options={options?.colors.map((c) => ({ label: c.label, value: c.key })) || []}
            loading={optionsLoading}
            disabled={isPending}
          />
          <CustomInput
            control={form.control}
            name="department"
            label="Default Department"
            placeholder="Optional"
            disabled={isPending}
          />
          <Button type="submit" className="w-full" disabled={isPending}>
            {category ? "Save Changes" : "Add Category"}
          </Button>
        </form>
      </DialogContent>
    </Dialog>
  );
}

export default function Categories() {
  const [search, setSearch] = useState("");

  const { data, isLoading, isError, refetch } = useQuery({
    queryKey: ["categories", "admin"],
    queryFn: () => getCategories(true),
  });

  const deleteMutation = useMutation({
    mutationFn: deleteCategory,
    onSuccess: () => {
      toast.success("Category removed");
      refetch();
    },
    onError: (e: any) => toast.error(e.message || "Failed to remove"),
  });

  const categories = useMemo(() => {
    const all = data || [];
    if (!search.trim()) return all;
    const q = search.trim().toLowerCase();
    return all.filter((c) => c.name.toLowerCase().includes(q));
  }, [data, search]);

  if (isLoading) {
    return (
      <div className="flex justify-center items-center min-h-[60vh]">
        <Loader label="Loading Categories..." />
      </div>
    );
  }
  if (isError) {
    return (
      <div className="p-10 text-center text-red-500">
        Failed to load categories.
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-3xl font-black tracking-tight">Categories</h1>
        <p className="text-slate-500 font-medium">
          Manage the doctor specialties available across the web and mobile
          apps.
        </p>
      </div>

      <Card className="card shadow-sm">
        <CardHeader className="flex flex-row items-center justify-between">
          <div>
            <CardTitle>Specialties</CardTitle>
            <CardDescription>All categories doctors can be assigned to</CardDescription>
          </div>
          <div className="flex gap-2">
            <GlobalSearch search={search} setSearch={setSearch} title="categories" />
            <CategoryModal onSaved={refetch} />
          </div>
        </CardHeader>
        <CardContent>
          <div className="rounded-md border border-zinc-300 dark:border-zinc-700">
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>Name</TableHead>
                  <TableHead>Icon</TableHead>
                  <TableHead>Color</TableHead>
                  <TableHead>Department</TableHead>
                  <TableHead>Status</TableHead>
                  <TableHead className="text-right">Actions</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {categories.length === 0 ? (
                  <TableRow>
                    <TableCell
                      colSpan={6}
                      className="text-center h-24 text-muted-foreground"
                    >
                      No categories yet.
                    </TableCell>
                  </TableRow>
                ) : (
                  categories.map((cat) => (
                    <TableRow key={cat.id}>
                      <TableCell className="font-medium flex items-center gap-2">
                        <span
                          className={`p-1.5 rounded-lg ${COLOR_PREVIEW[cat.colorKey] || COLOR_PREVIEW.lavender}`}
                        >
                          <Tag size={14} />
                        </span>
                        {cat.name}
                      </TableCell>
                      <TableCell>
                        <Badge variant="secondary">{cat.iconKey}</Badge>
                      </TableCell>
                      <TableCell>
                        <Badge
                          className={COLOR_PREVIEW[cat.colorKey] || COLOR_PREVIEW.lavender}
                        >
                          {cat.colorKey}
                        </Badge>
                      </TableCell>
                      <TableCell>{cat.department || "N/A"}</TableCell>
                      <TableCell>
                        {cat.isActive ? (
                          <Badge className="bg-emerald-100 text-emerald-700">
                            Active
                          </Badge>
                        ) : (
                          <Badge variant="secondary">Inactive</Badge>
                        )}
                      </TableCell>
                      <TableCell className="text-right">
                        <div className="flex justify-end gap-2">
                          <CategoryModal category={cat} onSaved={refetch} />
                          {cat.isActive && (
                            <Button
                              variant="destructive"
                              size="sm"
                              disabled={deleteMutation.isPending}
                              onClick={() => deleteMutation.mutate(cat.id)}
                            >
                              Deactivate
                            </Button>
                          )}
                        </div>
                      </TableCell>
                    </TableRow>
                  ))
                )}
              </TableBody>
            </Table>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}
