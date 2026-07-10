import { useState } from "react";
import { useMutation, useQuery } from "@tanstack/react-query";
import {
  getPrescriptions,
  createPrescription,
  cancelPrescription,
  getUsers,
  getMedications,
} from "@/lib/api";
import { useForm, useFieldArray } from "react-hook-form";
import { toast } from "sonner";
import { authClient } from "@/lib/auth-client";
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
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { CustomInput } from "@/components/global/CustomInput";
import Loader from "@/components/global/Loader";
import { ClipboardList, Plus, Trash2, CheckCircle2, XCircle } from "lucide-react";

export function meta() {
  return [{ title: "Prescriptions | Ask Musawo" }];
}

function statusBadge(status: string) {
  switch (status) {
    case "dispensed":
      return (
        <Badge className="bg-emerald-100 text-emerald-700 border-emerald-200 dark:bg-emerald-900/30 dark:text-emerald-400 gap-1">
          <CheckCircle2 size={12} /> Dispensed
        </Badge>
      );
    case "cancelled":
      return (
        <Badge className="bg-red-50 text-red-700 border-red-200 dark:bg-red-900/30 dark:text-red-400 gap-1">
          <XCircle size={12} /> Cancelled
        </Badge>
      );
    default:
      return (
        <Badge className="bg-amber-100 text-amber-700 border-amber-200 dark:bg-amber-900/30 dark:text-amber-400">
          Pending
        </Badge>
      );
  }
}

function CreatePrescriptionModal({ onSaved }: { onSaved: () => void }) {
  const [open, setOpen] = useState(false);
  const form = useForm({
    defaultValues: {
      patient: "",
      notes: "",
      items: [{ medicationName: "", dosage: "", quantity: 1, instructions: "" }],
    },
  });
  const { fields, append, remove } = useFieldArray({
    control: form.control,
    name: "items",
  });

  const { data: patientsData } = useQuery({
    queryKey: ["users", "patient", "for-prescription"],
    queryFn: () => getUsers({ role: "patient", limit: 100 }),
    enabled: open,
  });
  const { data: medsData } = useQuery({
    queryKey: ["medications", "for-prescription"],
    queryFn: () => getMedications({ limit: 100 }),
    enabled: open,
  });

  const mutation = useMutation({
    mutationFn: createPrescription,
    onSuccess: () => {
      toast.success("Prescription created");
      setOpen(false);
      form.reset();
      onSaved();
    },
    onError: (e: any) => toast.error(e.message || "Failed to create prescription"),
  });

  const onSubmit = (data: any) => {
    const patient = patientsData?.res.find((p) => p.id === data.patient);
    if (!patient) return toast.error("Select a patient");
    mutation.mutate({
      patient: patient.id,
      patientName: patient.name,
      items: data.items,
      notes: data.notes,
    });
  };

  const medications = medsData?.res || [];

  return (
    <Dialog open={open} onOpenChange={setOpen}>
      <DialogTrigger asChild>
        <Button className="gap-2">
          <Plus size={16} /> New Prescription
        </Button>
      </DialogTrigger>
      <DialogContent className="sm:max-w-2xl card max-h-[85vh] overflow-y-auto">
        <DialogHeader>
          <DialogTitle>New Prescription</DialogTitle>
        </DialogHeader>
        <form onSubmit={form.handleSubmit(onSubmit)} className="space-y-4">
          <div className="space-y-1.5">
            <label className="text-xs font-bold text-slate-500 uppercase tracking-widest ml-1">
              Patient
            </label>
            <Select
              onValueChange={(v) => form.setValue("patient", v)}
              value={form.watch("patient")}
            >
              <SelectTrigger className="w-full">
                <SelectValue placeholder="Select patient" />
              </SelectTrigger>
              <SelectContent>
                {(patientsData?.res || []).map((p) => (
                  <SelectItem key={p.id} value={p.id}>
                    {p.name} — {p.email}
                  </SelectItem>
                ))}
              </SelectContent>
            </Select>
          </div>

          <div className="space-y-3">
            <div className="flex items-center justify-between">
              <label className="text-xs font-bold text-slate-500 uppercase tracking-widest ml-1">
                Items
              </label>
              <Button
                type="button"
                variant="outline"
                size="sm"
                onClick={() =>
                  append({ medicationName: "", dosage: "", quantity: 1, instructions: "" })
                }
              >
                <Plus size={14} className="mr-1" /> Add item
              </Button>
            </div>
            {fields.map((field, index) => (
              <div
                key={field.id}
                className="grid grid-cols-12 gap-2 items-end border rounded-lg p-3"
              >
                <div className="col-span-4 space-y-1.5">
                  <label className="text-[10px] font-bold text-slate-500 uppercase">
                    Medication
                  </label>
                  {medications.length > 0 ? (
                    <Select
                      onValueChange={(v) =>
                        form.setValue(`items.${index}.medicationName`, v)
                      }
                      value={form.watch(`items.${index}.medicationName`)}
                    >
                      <SelectTrigger className="w-full">
                        <SelectValue placeholder="Select" />
                      </SelectTrigger>
                      <SelectContent>
                        {medications.map((m) => (
                          <SelectItem key={m.id} value={m.name}>
                            {m.name}
                          </SelectItem>
                        ))}
                      </SelectContent>
                    </Select>
                  ) : (
                    <CustomInput
                      control={form.control}
                      name={`items.${index}.medicationName`}
                      label=""
                      placeholder="Medication name"
                    />
                  )}
                </div>
                <div className="col-span-3">
                  <CustomInput
                    control={form.control}
                    name={`items.${index}.dosage`}
                    label=""
                    placeholder="Dosage e.g. 500mg 2x/day"
                  />
                </div>
                <div className="col-span-2">
                  <CustomInput
                    control={form.control}
                    name={`items.${index}.quantity`}
                    label=""
                    type="number"
                    placeholder="Qty"
                  />
                </div>
                <div className="col-span-2">
                  <CustomInput
                    control={form.control}
                    name={`items.${index}.instructions`}
                    label=""
                    placeholder="Notes"
                  />
                </div>
                <div className="col-span-1">
                  <Button
                    type="button"
                    variant="ghost"
                    size="icon"
                    disabled={fields.length === 1}
                    onClick={() => remove(index)}
                  >
                    <Trash2 size={14} className="text-red-500" />
                  </Button>
                </div>
              </div>
            ))}
          </div>

          <CustomInput
            control={form.control}
            name="notes"
            label="Notes (optional)"
            placeholder="Additional instructions for pharmacy"
          />

          <Button type="submit" className="w-full" disabled={mutation.isPending}>
            Create Prescription
          </Button>
        </form>
      </DialogContent>
    </Dialog>
  );
}

export default function Prescriptions() {
  const [status, setStatus] = useState("all");
  const { data: session } = authClient.useSession();
  const canCreate = ["admin", "doctor"].includes(session?.user?.role || "");
  const canCancel = ["admin", "doctor", "pharmacist"].includes(
    session?.user?.role || "",
  );

  const { data, isLoading, isError, refetch } = useQuery({
    queryKey: ["prescriptions", status],
    queryFn: () => getPrescriptions({ status, limit: 50 }),
  });

  const cancelMutation = useMutation({
    mutationFn: cancelPrescription,
    onSuccess: () => {
      toast.success("Prescription cancelled");
      refetch();
    },
    onError: (e: any) => toast.error(e.message || "Failed to cancel"),
  });

  if (isLoading) {
    return (
      <div className="flex justify-center items-center min-h-[60vh]">
        <Loader label="Loading Prescriptions..." />
      </div>
    );
  }
  if (isError) {
    return (
      <div className="p-10 text-center text-red-500">
        Failed to load prescriptions.
      </div>
    );
  }

  const prescriptions = data?.res || [];

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-3xl font-black tracking-tight">Prescriptions</h1>
        <p className="text-slate-500 font-medium">
          Manage prescriptions written for patients.
        </p>
      </div>

      <Card className="card shadow-sm">
        <CardHeader className="flex flex-row items-center justify-between">
          <div>
            <CardTitle>All Prescriptions</CardTitle>
            <CardDescription>
              {prescriptions.length} record(s) found
            </CardDescription>
          </div>
          <div className="flex gap-2">
            <Select value={status} onValueChange={setStatus}>
              <SelectTrigger className="w-40">
                <SelectValue />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="all">All statuses</SelectItem>
                <SelectItem value="pending">Pending</SelectItem>
                <SelectItem value="dispensed">Dispensed</SelectItem>
                <SelectItem value="cancelled">Cancelled</SelectItem>
              </SelectContent>
            </Select>
            {canCreate && <CreatePrescriptionModal onSaved={refetch} />}
          </div>
        </CardHeader>
        <CardContent>
          <div className="rounded-md border border-zinc-300 dark:border-zinc-700">
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>Patient</TableHead>
                  <TableHead>Doctor</TableHead>
                  <TableHead>Items</TableHead>
                  <TableHead>Status</TableHead>
                  <TableHead>Date</TableHead>
                  <TableHead className="text-right">Actions</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {prescriptions.length === 0 ? (
                  <TableRow>
                    <TableCell
                      colSpan={6}
                      className="text-center h-24 text-muted-foreground"
                    >
                      No prescriptions found.
                    </TableCell>
                  </TableRow>
                ) : (
                  prescriptions.map((p) => (
                    <TableRow key={p.id}>
                      <TableCell className="font-medium flex items-center gap-2">
                        <ClipboardList size={14} className="text-slate-400" />
                        {p.patientName}
                      </TableCell>
                      <TableCell>{p.doctorName}</TableCell>
                      <TableCell className="max-w-64">
                        <span className="text-sm text-slate-600 dark:text-slate-300">
                          {p.items
                            .map((i) => `${i.medicationName} (${i.quantity})`)
                            .join(", ")}
                        </span>
                      </TableCell>
                      <TableCell>{statusBadge(p.status)}</TableCell>
                      <TableCell className="text-sm text-slate-500">
                        {new Date(p.createdAt).toLocaleDateString()}
                      </TableCell>
                      <TableCell className="text-right">
                        {p.status === "pending" && canCancel && (
                          <Button
                            variant="destructive"
                            size="sm"
                            disabled={cancelMutation.isPending}
                            onClick={() => cancelMutation.mutate(p.id)}
                          >
                            Cancel
                          </Button>
                        )}
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
