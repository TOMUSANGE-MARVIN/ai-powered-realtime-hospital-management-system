import { useState } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import {
  getMedications,
  createMedication,
  updateMedication,
  deleteMedication,
} from "@/lib/api";
import type { Medication } from "@/types";
import { useForm } from "react-hook-form";
import { toast } from "sonner";
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
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
import GlobalSearch from "@/components/global/GlobalSearch";
import CustomPagination from "@/components/global/CustomPagination";
import Loader from "@/components/global/Loader";
import { Pill, Plus, AlertTriangle, Boxes, DollarSign } from "lucide-react";

export function meta() {
  return [{ title: "Pharmacy Inventory | Ask Musawo" }];
}

const emptyMed = {
  name: "",
  category: "",
  unit: "tablet",
  stock: 0,
  reorderLevel: 10,
  unitPrice: 0,
  supplier: "",
};

function MedicationModal({
  medication,
  onSaved,
}: {
  medication?: Medication;
  onSaved: () => void;
}) {
  const [open, setOpen] = useState(false);
  const form = useForm({
    defaultValues: medication
      ? {
          name: medication.name,
          category: medication.category,
          unit: medication.unit,
          stock: medication.stock,
          reorderLevel: medication.reorderLevel,
          unitPrice: medication.unitPrice / 100,
          supplier: medication.supplier || "",
        }
      : emptyMed,
  });

  const createMutation = useMutation({
    mutationFn: createMedication,
    onSuccess: () => {
      toast.success("Medication added to inventory");
      setOpen(false);
      form.reset(emptyMed);
      onSaved();
    },
    onError: (e: any) => toast.error(e.message || "Failed to add medication"),
  });

  const updateMutation = useMutation({
    mutationFn: updateMedication,
    onSuccess: () => {
      toast.success("Medication updated");
      setOpen(false);
      onSaved();
    },
    onError: (e: any) =>
      toast.error(e.message || "Failed to update medication"),
  });

  const onSubmit = (data: any) => {
    const payload = {
      ...data,
      stock: Number(data.stock),
      reorderLevel: Number(data.reorderLevel),
      unitPrice: Math.round(Number(data.unitPrice) * 100),
    };
    if (medication) {
      updateMutation.mutate({ id: medication._id, data: payload });
    } else {
      createMutation.mutate(payload);
    }
  };

  const isPending = createMutation.isPending || updateMutation.isPending;

  return (
    <Dialog open={open} onOpenChange={setOpen}>
      <DialogTrigger asChild>
        {medication ? (
          <Button variant="outline" size="sm">
            Edit
          </Button>
        ) : (
          <Button className="gap-2">
            <Plus size={16} /> Add Medication
          </Button>
        )}
      </DialogTrigger>
      <DialogContent className="sm:max-w-lg card">
        <DialogHeader>
          <DialogTitle>
            {medication ? "Edit Medication" : "Add Medication"}
          </DialogTitle>
        </DialogHeader>
        <form
          onSubmit={form.handleSubmit(onSubmit)}
          className="space-y-3 grid grid-cols-2 gap-3"
        >
          <div className="col-span-2">
            <CustomInput
              control={form.control}
              name="name"
              label="Name"
              placeholder="e.g. Amoxicillin 500mg"
              disabled={isPending}
            />
          </div>
          <CustomInput
            control={form.control}
            name="category"
            label="Category"
            placeholder="e.g. Antibiotic"
            disabled={isPending}
          />
          <CustomInput
            control={form.control}
            name="unit"
            label="Unit"
            placeholder="tablet, bottle..."
            disabled={isPending}
          />
          <CustomInput
            control={form.control}
            name="stock"
            label="Stock Quantity"
            type="number"
            disabled={isPending}
          />
          <CustomInput
            control={form.control}
            name="reorderLevel"
            label="Reorder Level"
            type="number"
            disabled={isPending}
          />
          <CustomInput
            control={form.control}
            name="unitPrice"
            label="Unit Price (UGX)"
            type="number"
            step="0.01"
            disabled={isPending}
          />
          <CustomInput
            control={form.control}
            name="supplier"
            label="Supplier"
            placeholder="Optional"
            disabled={isPending}
          />
          <Button type="submit" className="col-span-2" disabled={isPending}>
            {medication ? "Save Changes" : "Add to Inventory"}
          </Button>
        </form>
      </DialogContent>
    </Dialog>
  );
}

export default function PharmacyInventory() {
  const [page, setPage] = useState(1);
  const [search, setSearch] = useState("");
  const queryClient = useQueryClient();

  const { data, isLoading, isError, refetch } = useQuery({
    queryKey: ["medications", page, search],
    queryFn: () => getMedications({ page, limit: 10, search }),
    placeholderData: (prev) => prev,
  });

  const deleteMutation = useMutation({
    mutationFn: deleteMedication,
    onSuccess: () => {
      toast.success("Medication removed");
      refetch();
    },
    onError: (e: any) => toast.error(e.message || "Failed to remove"),
  });

  if (isLoading) {
    return (
      <div className="flex justify-center items-center min-h-[60vh]">
        <Loader label="Loading Inventory..." />
      </div>
    );
  }
  if (isError) {
    return (
      <div className="p-10 text-center text-red-500">
        Failed to load inventory.
      </div>
    );
  }

  const medications = data?.res || [];
  const pagination = data?.pagination;
  const lowStock = medications.filter((m) => m.stock <= m.reorderLevel);
  const totalValue = medications.reduce(
    (sum, m) => sum + m.stock * m.unitPrice,
    0,
  );

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-3xl font-black tracking-tight">
          Pharmacy Inventory
        </h1>
        <p className="text-slate-500 font-medium">
          Track stock levels and manage medication supply.
        </p>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        <Card className="card shadow-sm">
          <CardContent className="p-6 flex items-center justify-between">
            <div>
              <p className="text-sm text-slate-500 font-medium">
                Total Items
              </p>
              <h3 className="text-2xl font-black mt-1">
                {pagination?.totalData ?? medications.length}
              </h3>
            </div>
            <div className="p-3 rounded-2xl bg-blue-100 dark:bg-blue-900/30 text-blue-600 dark:text-blue-400">
              <Boxes size={20} />
            </div>
          </CardContent>
        </Card>
        <Card className="card shadow-sm">
          <CardContent className="p-6 flex items-center justify-between">
            <div>
              <p className="text-sm text-slate-500 font-medium">Low Stock</p>
              <h3 className="text-2xl font-black mt-1">{lowStock.length}</h3>
            </div>
            <div className="p-3 rounded-2xl bg-amber-100 dark:bg-amber-900/30 text-amber-600 dark:text-amber-400">
              <AlertTriangle size={20} />
            </div>
          </CardContent>
        </Card>
        <Card className="card shadow-sm">
          <CardContent className="p-6 flex items-center justify-between">
            <div>
              <p className="text-sm text-slate-500 font-medium">
                Inventory Value (page)
              </p>
              <h3 className="text-2xl font-black mt-1">
                UGX {(totalValue / 100).toLocaleString()}
              </h3>
            </div>
            <div className="p-3 rounded-2xl bg-emerald-100 dark:bg-emerald-900/30 text-emerald-600 dark:text-emerald-400">
              <DollarSign size={20} />
            </div>
          </CardContent>
        </Card>
      </div>

      <Card className="card shadow-sm">
        <CardHeader className="flex flex-row items-center justify-between">
          <div>
            <CardTitle>Medications</CardTitle>
            <CardDescription>All items currently tracked</CardDescription>
          </div>
          <div className="flex gap-2">
            <GlobalSearch search={search} setSearch={setSearch} title="medications" />
            <MedicationModal onSaved={refetch} />
          </div>
        </CardHeader>
        <CardContent>
          <div className="rounded-md border border-zinc-300 dark:border-zinc-700">
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>Name</TableHead>
                  <TableHead>Category</TableHead>
                  <TableHead>Stock</TableHead>
                  <TableHead>Unit Price</TableHead>
                  <TableHead>Supplier</TableHead>
                  <TableHead className="text-right">Actions</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {medications.length === 0 ? (
                  <TableRow>
                    <TableCell
                      colSpan={6}
                      className="text-center h-24 text-muted-foreground"
                    >
                      No medications in inventory yet.
                    </TableCell>
                  </TableRow>
                ) : (
                  medications.map((med) => (
                    <TableRow key={med._id}>
                      <TableCell className="font-medium flex items-center gap-2">
                        <Pill size={14} className="text-slate-400" />
                        {med.name}
                      </TableCell>
                      <TableCell>
                        <Badge variant="secondary">{med.category}</Badge>
                      </TableCell>
                      <TableCell>
                        <span
                          className={
                            med.stock <= med.reorderLevel
                              ? "text-amber-600 dark:text-amber-400 font-bold"
                              : ""
                          }
                        >
                          {med.stock} {med.unit}
                          {med.stock <= med.reorderLevel && " (Low)"}
                        </span>
                      </TableCell>
                      <TableCell>
                        UGX {(med.unitPrice / 100).toLocaleString()}
                      </TableCell>
                      <TableCell>{med.supplier || "N/A"}</TableCell>
                      <TableCell className="text-right">
                        <div className="flex justify-end gap-2">
                          <MedicationModal medication={med} onSaved={refetch} />
                          <Button
                            variant="destructive"
                            size="sm"
                            disabled={deleteMutation.isPending}
                            onClick={() => deleteMutation.mutate(med._id)}
                          >
                            Delete
                          </Button>
                        </div>
                      </TableCell>
                    </TableRow>
                  ))
                )}
              </TableBody>
            </Table>
            <CustomPagination
              loading={isLoading}
              totalPages={pagination?.totalPages || 0}
              currentPage={pagination?.currentPage || 0}
              setPage={setPage}
            />
          </div>
        </CardContent>
      </Card>
    </div>
  );
}
