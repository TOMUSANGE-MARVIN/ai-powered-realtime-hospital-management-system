import { useState } from "react";
import { useMutation, useQuery } from "@tanstack/react-query";
import { useForm } from "react-hook-form";
import { toast } from "sonner";
import { Plus } from "lucide-react";
import { createVoucher, getVouchers, updateVoucher } from "@/lib/api";
import type { Voucher } from "@/types";
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
import { CustomSelect } from "@/components/global/CustomSelect";
import Loader from "@/components/global/Loader";

export function meta() {
  return [{ title: "Vouchers | Ask Musawo" }];
}

const emptyVoucher = {
  code: "",
  discountType: "percent",
  value: "",
  expiresAt: "",
  maxUses: "",
};

function VoucherModal({ onSaved }: { onSaved: () => void }) {
  const [open, setOpen] = useState(false);
  const form = useForm({ defaultValues: emptyVoucher });

  const createMutation = useMutation({
    mutationFn: createVoucher,
    onSuccess: () => {
      toast.success("Voucher created");
      setOpen(false);
      form.reset(emptyVoucher);
      onSaved();
    },
    onError: (e: any) => toast.error(e.message || "Failed to create voucher"),
  });

  const onSubmit = (data: typeof emptyVoucher) => {
    createMutation.mutate({
      code: data.code,
      discountType: data.discountType as Voucher["discountType"],
      value: Number(data.value),
      expiresAt: data.expiresAt || null,
      maxUses: data.maxUses ? Number(data.maxUses) : null,
    });
  };

  return (
    <Dialog open={open} onOpenChange={setOpen}>
      <DialogTrigger asChild>
        <Button className="gap-2">
          <Plus size={16} /> New Voucher
        </Button>
      </DialogTrigger>
      <DialogContent className="sm:max-w-lg card">
        <DialogHeader>
          <DialogTitle>New Voucher</DialogTitle>
        </DialogHeader>
        <form onSubmit={form.handleSubmit(onSubmit)} className="space-y-3">
          <CustomInput
            control={form.control}
            name="code"
            label="Code"
            placeholder="e.g. WELCOME10"
            disabled={createMutation.isPending}
          />
          <CustomSelect
            control={form.control}
            name="discountType"
            label="Discount type"
            options={[
              { label: "Percent off", value: "percent" },
              { label: "Fixed amount off (UGX)", value: "fixed" },
            ]}
            disabled={createMutation.isPending}
          />
          <CustomInput
            control={form.control}
            name="value"
            label="Value"
            type="number"
            placeholder="10 for 10%, or 5000 for UGX 5,000"
            disabled={createMutation.isPending}
          />
          <CustomInput
            control={form.control}
            name="expiresAt"
            label="Expires on (optional)"
            type="date"
            disabled={createMutation.isPending}
          />
          <CustomInput
            control={form.control}
            name="maxUses"
            label="Maximum uses (optional)"
            type="number"
            disabled={createMutation.isPending}
          />
          <Button
            type="submit"
            className="w-full"
            disabled={createMutation.isPending}
          >
            Create Voucher
          </Button>
        </form>
      </DialogContent>
    </Dialog>
  );
}

const describe = (v: Voucher) =>
  v.discountType === "percent"
    ? `${v.value}% off`
    : `UGX ${v.value.toLocaleString()} off`;

export default function Vouchers() {
  const { data, isLoading, isError, refetch } = useQuery({
    queryKey: ["vouchers"],
    queryFn: getVouchers,
  });

  const toggleMutation = useMutation({
    mutationFn: updateVoucher,
    onSuccess: () => refetch(),
    onError: (e: any) => toast.error(e.message || "Failed to update voucher"),
  });

  if (isLoading) {
    return (
      <div className="flex justify-center items-center min-h-[60vh]">
        <Loader label="Loading Vouchers..." />
      </div>
    );
  }
  if (isError) {
    return (
      <div className="p-10 text-center text-red-500">
        Failed to load vouchers.
      </div>
    );
  }

  const vouchers = data || [];

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-3xl font-black tracking-tight">Vouchers</h1>
        <p className="text-slate-500 font-medium">
          Discount codes patients can apply when booking a paid consultation.
          A voucher never takes a payment below UGX 1,000.
        </p>
      </div>

      <Card className="card shadow-sm">
        <CardHeader className="flex flex-row items-center justify-between">
          <div>
            <CardTitle>Codes</CardTitle>
            <CardDescription>
              Uses count only once the patient's payment succeeds
            </CardDescription>
          </div>
          <VoucherModal onSaved={refetch} />
        </CardHeader>
        <CardContent>
          <div className="rounded-md border border-zinc-300 dark:border-zinc-700">
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>Code</TableHead>
                  <TableHead>Discount</TableHead>
                  <TableHead>Expires</TableHead>
                  <TableHead>Uses</TableHead>
                  <TableHead>Status</TableHead>
                  <TableHead className="text-right">Actions</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {vouchers.length === 0 ? (
                  <TableRow>
                    <TableCell
                      colSpan={6}
                      className="text-center h-24 text-muted-foreground"
                    >
                      No vouchers yet.
                    </TableCell>
                  </TableRow>
                ) : (
                  vouchers.map((v) => {
                    const expired =
                      !!v.expiresAt && new Date(v.expiresAt) < new Date();
                    return (
                      <TableRow key={v.id}>
                        <TableCell className="font-mono font-semibold">
                          {v.code}
                        </TableCell>
                        <TableCell>{describe(v)}</TableCell>
                        <TableCell>
                          {v.expiresAt
                            ? new Date(v.expiresAt).toLocaleDateString()
                            : "Never"}
                        </TableCell>
                        <TableCell>
                          {v.usedCount}
                          {v.maxUses != null ? ` / ${v.maxUses}` : ""}
                        </TableCell>
                        <TableCell>
                          {!v.active ? (
                            <Badge variant="secondary">Disabled</Badge>
                          ) : expired ? (
                            <Badge variant="secondary">Expired</Badge>
                          ) : (
                            <Badge className="bg-emerald-100 text-emerald-700">
                              Active
                            </Badge>
                          )}
                        </TableCell>
                        <TableCell className="text-right">
                          <Button
                            variant={v.active ? "destructive" : "outline"}
                            size="sm"
                            disabled={toggleMutation.isPending}
                            onClick={() =>
                              toggleMutation.mutate({
                                id: v.id,
                                data: { active: !v.active },
                              })
                            }
                          >
                            {v.active ? "Disable" : "Enable"}
                          </Button>
                        </TableCell>
                      </TableRow>
                    );
                  })
                )}
              </TableBody>
            </Table>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}
