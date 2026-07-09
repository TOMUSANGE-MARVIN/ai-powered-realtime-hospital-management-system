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
  return [{ title: "General Settings | Ask Musawo" }];
}

export default function GeneralSettings() {
  const { data, isLoading } = useQuery({
    queryKey: ["settings", "general"],
    queryFn: () => getSetting("general"),
  });

  const form = useForm({
    defaultValues: {
      hospitalName: "",
      supportEmail: "",
      supportPhone: "",
      address: "",
      timezone: "",
    },
  });

  useEffect(() => {
    if (data?.data) form.reset(data.data);
  }, [data]);

  const mutation = useMutation({
    mutationFn: updateSetting,
    onSuccess: () => toast.success("General settings saved"),
    onError: (e: any) => toast.error(e.message || "Failed to save settings"),
  });

  const onSubmit = (values: any) => {
    mutation.mutate({ key: "general", data: values });
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
        <h1 className="text-3xl font-black tracking-tight">General Settings</h1>
        <p className="text-slate-500 font-medium">
          Hospital identity and contact information shown across the platform.
        </p>
      </div>

      <Card className="card shadow-sm max-w-2xl">
        <CardHeader>
          <CardTitle>Organization Details</CardTitle>
          <CardDescription>
            Used on invoices, notifications, and the public site.
          </CardDescription>
        </CardHeader>
        <CardContent>
          <form onSubmit={form.handleSubmit(onSubmit)} className="space-y-4">
            <CustomInput
              control={form.control}
              name="hospitalName"
              label="Hospital Name"
            />
            <div className="grid grid-cols-2 gap-4">
              <CustomInput
                control={form.control}
                name="supportEmail"
                label="Support Email"
                type="email"
              />
              <CustomInput
                control={form.control}
                name="supportPhone"
                label="Support Phone"
              />
            </div>
            <CustomInput control={form.control} name="address" label="Address" />
            <CustomInput
              control={form.control}
              name="timezone"
              label="Timezone"
              placeholder="Africa/Kampala"
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
