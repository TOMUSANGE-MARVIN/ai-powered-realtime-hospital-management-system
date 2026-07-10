import { useMutation, useQuery } from "@tanstack/react-query";
import { getPrescriptions, dispensePrescription } from "@/lib/api";
import { toast } from "sonner";
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import Loader from "@/components/global/Loader";
import { PackageCheck, ClipboardList, PillBottle } from "lucide-react";

export function meta() {
  return [{ title: "Dispense Medication | Ask Musawo" }];
}

export default function Dispense() {
  const { data, isLoading, isError, refetch } = useQuery({
    queryKey: ["prescriptions", "pending"],
    queryFn: () => getPrescriptions({ status: "pending", limit: 50 }),
    refetchInterval: 15000,
  });

  const dispenseMutation = useMutation({
    mutationFn: dispensePrescription,
    onSuccess: () => {
      toast.success("Medication dispensed and stock updated");
      refetch();
    },
    onError: (e: any) => toast.error(e.message || "Failed to dispense"),
  });

  if (isLoading) {
    return (
      <div className="flex justify-center items-center min-h-[60vh]">
        <Loader label="Loading Dispense Queue..." />
      </div>
    );
  }
  if (isError) {
    return (
      <div className="p-10 text-center text-red-500">
        Failed to load dispense queue.
      </div>
    );
  }

  const pending = data?.res || [];

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-black tracking-tight">
            Dispense Queue
          </h1>
          <p className="text-slate-500 font-medium">
            Prescriptions awaiting medication handout.
          </p>
        </div>
        <Badge className="bg-amber-100 text-amber-700 border-amber-200 dark:bg-amber-900/30 dark:text-amber-400 text-sm px-3 py-1">
          {pending.length} pending
        </Badge>
      </div>

      {pending.length === 0 ? (
        <Card className="card shadow-sm">
          <CardContent className="p-16 flex flex-col items-center justify-center text-center gap-3">
            <PackageCheck size={40} className="text-emerald-500" />
            <p className="text-slate-500 font-medium">
              All caught up — no prescriptions waiting to be dispensed.
            </p>
          </CardContent>
        </Card>
      ) : (
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
          {pending.map((p) => (
            <Card key={p.id} className="card shadow-sm">
              <CardHeader className="flex flex-row items-start justify-between">
                <div>
                  <CardTitle className="text-base flex items-center gap-2">
                    <ClipboardList size={16} className="text-slate-400" />
                    {p.patientName}
                  </CardTitle>
                  <CardDescription>
                    Prescribed by {p.doctorName} •{" "}
                    {new Date(p.createdAt).toLocaleDateString()}
                  </CardDescription>
                </div>
              </CardHeader>
              <CardContent className="space-y-3">
                <div className="space-y-2">
                  {p.items.map((item, idx) => (
                    <div
                      key={idx}
                      className="flex items-center justify-between text-sm rounded-lg border border-zinc-200 dark:border-zinc-800 p-2"
                    >
                      <div className="flex items-center gap-2">
                        <PillBottle size={14} className="text-slate-400" />
                        <div>
                          <p className="font-medium">{item.medicationName}</p>
                          <p className="text-xs text-slate-500">
                            {item.dosage}
                            {item.instructions ? ` • ${item.instructions}` : ""}
                          </p>
                        </div>
                      </div>
                      <Badge variant="secondary">x{item.quantity}</Badge>
                    </div>
                  ))}
                </div>
                {p.notes && (
                  <p className="text-xs italic text-slate-500">
                    Note: {p.notes}
                  </p>
                )}
                <Button
                  className="w-full gap-2"
                  disabled={dispenseMutation.isPending}
                  onClick={() => dispenseMutation.mutate(p.id)}
                >
                  <PackageCheck size={16} /> Mark as Dispensed
                </Button>
              </CardContent>
            </Card>
          ))}
        </div>
      )}
    </div>
  );
}
