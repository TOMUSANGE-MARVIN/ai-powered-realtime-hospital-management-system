import { useEffect } from "react";
import { useMutation, useQuery } from "@tanstack/react-query";
import { getSetting, updateSetting } from "@/lib/api";
import { useForm } from "react-hook-form";
import { toast } from "sonner";
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { CustomInput } from "@/components/global/CustomInput";
import Loader from "@/components/global/Loader";

export function meta() {
  return [{ title: "Billing Settings | Ask Musawo" }];
}

export default function BillingSettings() {
  const { data, isLoading } = useQuery({
    queryKey: ["settings", "billing"],
    queryFn: () => getSetting("billing"),
  });

  const form = useForm({
    defaultValues: {
      currency: "UGX",
      taxRatePercent: 0,
      paymentTerms: "",
      invoiceFooter: "",
    },
  });

  useEffect(() => {
    if (data?.data) form.reset(data.data);
  }, [data]);

  const mutation = useMutation({
    mutationFn: updateSetting,
    onSuccess: () => toast.success("Billing settings saved"),
    onError: (e: any) => toast.error(e.message || "Failed to save settings"),
  });

  const onSubmit = (values: any) => {
    mutation.mutate({
      key: "billing",
      data: { ...values, taxRatePercent: Number(values.taxRatePercent) },
    });
  };

  if (isLoading) {
    return (
      <div className="flex justify-center items-center min-h-[60vh]">
        <Loader label="Loading Settings..." />
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-3xl font-black tracking-tight">Billing Settings</h1>
        <p className="text-slate-500 font-medium">
          Defaults applied to new invoices and financial records.
        </p>
      </div>

      <Card className="card shadow-sm max-w-2xl">
        <CardHeader>
          <CardTitle>Invoice Defaults</CardTitle>
          <CardDescription>
            Payment processing itself is configured via environment secrets;
            this only controls invoice presentation.
          </CardDescription>
        </CardHeader>
        <CardContent>
          <form onSubmit={form.handleSubmit(onSubmit)} className="space-y-4">
            <div className="grid grid-cols-2 gap-4">
              <CustomInput control={form.control} name="currency" label="Currency" />
              <CustomInput
                control={form.control}
                name="taxRatePercent"
                label="Tax Rate (%)"
                type="number"
                step="0.01"
              />
            </div>
            <CustomInput
              control={form.control}
              name="paymentTerms"
              label="Payment Terms"
              placeholder="Due on receipt"
            />
            <CustomInput
              control={form.control}
              name="invoiceFooter"
              label="Invoice Footer Note"
            />
            <Button type="submit" disabled={mutation.isPending}>
              Save Changes
            </Button>
          </form>
        </CardContent>
      </Card>
    </div>
  );
}
