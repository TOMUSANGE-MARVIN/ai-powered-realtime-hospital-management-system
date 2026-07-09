import { useState } from "react";
import { useMutation, useQuery } from "@tanstack/react-query";
import { getAllLabResults, createLabResult, getUsers } from "@/lib/api";
import { useForm } from "react-hook-form";
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
import { FlaskConical, Plus } from "lucide-react";

export function meta() {
  return [{ title: "Test Requests | Ask Musawo" }];
}

const TEST_TYPES = ["X-Ray", "Blood Test", "Urinalysis", "MRI", "CT Scan", "Other"];

function NewRequestModal({ onSaved }: { onSaved: () => void }) {
  const [open, setOpen] = useState(false);
  const [testType, setTestType] = useState("Blood Test");
  const form = useForm({ defaultValues: { patient: "", bodyPart: "" } });

  const { data: patientsData } = useQuery({
    queryKey: ["users", "patient", "for-lab-request"],
    queryFn: () => getUsers({ role: "patient", limit: 100 }),
    enabled: open,
  });

  const mutation = useMutation({
    mutationFn: createLabResult,
    onSuccess: () => {
      toast.success("Test request submitted");
      setOpen(false);
      form.reset();
      onSaved();
    },
    onError: (e: any) => toast.error(e.message || "Failed to submit request"),
  });

  const onSubmit = (data: any) => {
    const patient = patientsData?.res.find((p) => p._id === data.patient);
    if (!patient) return toast.error("Select a patient");
    mutation.mutate({
      patientId: patient._id,
      testType,
      bodyPart: data.bodyPart,
      imageUrl: "",
    });
  };

  return (
    <Dialog open={open} onOpenChange={setOpen}>
      <DialogTrigger asChild>
        <Button className="gap-2">
          <Plus size={16} /> New Test Request
        </Button>
      </DialogTrigger>
      <DialogContent className="sm:max-w-lg card">
        <DialogHeader>
          <DialogTitle>Request a Lab Test</DialogTitle>
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
                  <SelectItem key={p._id} value={p._id}>
                    {p.name} — {p.email}
                  </SelectItem>
                ))}
              </SelectContent>
            </Select>
          </div>
          <div className="space-y-1.5">
            <label className="text-xs font-bold text-slate-500 uppercase tracking-widest ml-1">
              Test Type
            </label>
            <Select value={testType} onValueChange={setTestType}>
              <SelectTrigger className="w-full">
                <SelectValue />
              </SelectTrigger>
              <SelectContent>
                {TEST_TYPES.map((t) => (
                  <SelectItem key={t} value={t}>
                    {t}
                  </SelectItem>
                ))}
              </SelectContent>
            </Select>
          </div>
          <CustomInput
            control={form.control}
            name="bodyPart"
            label="Body Part / Notes"
            placeholder="e.g. Left Knee, or reason for test"
          />
          <Button type="submit" className="w-full" disabled={mutation.isPending}>
            Submit Request
          </Button>
        </form>
      </DialogContent>
    </Dialog>
  );
}

export default function LabRequests() {
  const { data: session } = authClient.useSession();
  const canCreate = ["admin", "doctor"].includes(session?.user?.role || "");

  const { data, isLoading, isError, refetch } = useQuery({
    queryKey: ["lab-results", "pending"],
    queryFn: () => getAllLabResults({ status: "pending", limit: 50 }),
    refetchInterval: 15000,
  });

  if (isLoading) {
    return (
      <div className="flex justify-center items-center min-h-[60vh]">
        <Loader label="Loading Test Requests..." />
      </div>
    );
  }
  if (isError) {
    return (
      <div className="p-10 text-center text-red-500">
        Failed to load test requests.
      </div>
    );
  }

  const requests = data?.res || [];

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-black tracking-tight">Test Requests</h1>
          <p className="text-slate-500 font-medium">
            Pending lab tests awaiting sample collection and analysis.
          </p>
        </div>
        {canCreate && <NewRequestModal onSaved={refetch} />}
      </div>

      <Card className="card shadow-sm">
        <CardHeader>
          <CardTitle>Pending Requests</CardTitle>
          <CardDescription>{requests.length} awaiting analysis</CardDescription>
        </CardHeader>
        <CardContent>
          <div className="rounded-md border border-zinc-300 dark:border-zinc-700">
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>Patient</TableHead>
                  <TableHead>Test Type</TableHead>
                  <TableHead>Body Part / Notes</TableHead>
                  <TableHead>Requested</TableHead>
                  <TableHead>Status</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {requests.length === 0 ? (
                  <TableRow>
                    <TableCell
                      colSpan={5}
                      className="text-center h-24 text-muted-foreground"
                    >
                      No pending test requests.
                    </TableCell>
                  </TableRow>
                ) : (
                  requests.map((r) => (
                    <TableRow key={r._id}>
                      <TableCell className="font-medium flex items-center gap-2">
                        <FlaskConical size={14} className="text-slate-400" />
                        {r.patientName}
                      </TableCell>
                      <TableCell>
                        <Badge variant="secondary">{r.testType}</Badge>
                      </TableCell>
                      <TableCell>{r.bodyPart || "N/A"}</TableCell>
                      <TableCell className="text-sm text-slate-500">
                        {new Date(r.createdAt).toLocaleDateString()}
                      </TableCell>
                      <TableCell>
                        <Badge className="bg-amber-100 text-amber-700 border-amber-200 dark:bg-amber-900/30 dark:text-amber-400">
                          Pending
                        </Badge>
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
