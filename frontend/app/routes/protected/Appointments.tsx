import { useState } from "react";
import { useMutation, useQuery } from "@tanstack/react-query";
import { getAppointments, updateAppointment, createAppointment } from "@/lib/api";
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
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { CustomInput } from "@/components/global/CustomInput";
import Loader from "@/components/global/Loader";
import { CalendarClock, Plus, Video } from "lucide-react";

export function meta() {
  return [{ title: "Appointments | Ask Musawo" }];
}

function statusBadge(status: string) {
  const map: Record<string, string> = {
    requested:
      "bg-slate-100 text-slate-700 border-slate-200 dark:bg-slate-800 dark:text-slate-300",
    scheduled:
      "bg-blue-100 text-blue-700 border-blue-200 dark:bg-blue-900/30 dark:text-blue-400",
    confirmed:
      "bg-emerald-100 text-emerald-700 border-emerald-200 dark:bg-emerald-900/30 dark:text-emerald-400",
    "in-progress":
      "bg-violet-100 text-violet-700 border-violet-200 dark:bg-violet-900/30 dark:text-violet-400",
    completed:
      "bg-teal-100 text-teal-700 border-teal-200 dark:bg-teal-900/30 dark:text-teal-400",
    cancelled:
      "bg-red-50 text-red-700 border-red-200 dark:bg-red-900/30 dark:text-red-400",
  };
  return (
    <Badge className={map[status] || map.requested}>
      {status.replace("-", " ")}
    </Badge>
  );
}

function NewAppointmentModal({ onSaved }: { onSaved: () => void }) {
  const [open, setOpen] = useState(false);
  const form = useForm({
    defaultValues: {
      patientName: "",
      doctorName: "",
      department: "",
      date: "",
      time: "",
      reason: "",
      isVirtual: false,
    },
  });

  const mutation = useMutation({
    mutationFn: createAppointment,
    onSuccess: () => {
      toast.success("Appointment scheduled");
      setOpen(false);
      form.reset();
      onSaved();
    },
    onError: (e: any) => toast.error(e.message || "Failed to schedule"),
  });

  const onSubmit = (data: any) => {
    if (!data.patientName || !data.date) {
      return toast.error("Patient name and date are required");
    }
    mutation.mutate({ ...data, status: "scheduled" });
  };

  return (
    <Dialog open={open} onOpenChange={setOpen}>
      <DialogTrigger asChild>
        <Button className="gap-2">
          <Plus size={16} /> New Appointment
        </Button>
      </DialogTrigger>
      <DialogContent className="sm:max-w-lg card">
        <DialogHeader>
          <DialogTitle>Schedule Appointment</DialogTitle>
        </DialogHeader>
        <form onSubmit={form.handleSubmit(onSubmit)} className="space-y-3">
          <CustomInput
            control={form.control}
            name="patientName"
            label="Patient Name"
            placeholder="Jane Nakato"
          />
          <CustomInput
            control={form.control}
            name="doctorName"
            label="Doctor"
            placeholder="Dr. Okello"
          />
          <CustomInput
            control={form.control}
            name="department"
            label="Department"
            placeholder="Internal Medicine"
          />
          <div className="grid grid-cols-2 gap-3">
            <CustomInput control={form.control} name="date" label="Date" type="date" />
            <CustomInput control={form.control} name="time" label="Time" type="time" />
          </div>
          <CustomInput
            control={form.control}
            name="reason"
            label="Reason"
            placeholder="Reason for visit"
          />
          <div className="flex items-center gap-2">
            <input
              type="checkbox"
              id="isVirtual"
              className="size-4"
              {...form.register("isVirtual")}
            />
            <label htmlFor="isVirtual" className="text-sm font-medium">
              Virtual / Telemedicine visit
            </label>
          </div>
          <Button type="submit" className="w-full" disabled={mutation.isPending}>
            Schedule
          </Button>
        </form>
      </DialogContent>
    </Dialog>
  );
}

export default function Appointments() {
  const [status, setStatus] = useState("all");

  const { data, isLoading, isError, refetch } = useQuery({
    queryKey: ["appointments", status],
    queryFn: () => getAppointments({ status, limit: 50 }),
    refetchInterval: 20000,
  });

  const updateMutation = useMutation({
    mutationFn: updateAppointment,
    onSuccess: () => {
      toast.success("Appointment updated");
      refetch();
    },
    onError: (e: any) => toast.error(e.message || "Failed to update"),
  });

  if (isLoading) {
    return (
      <div className="flex justify-center items-center min-h-[60vh]">
        <Loader label="Loading Appointments..." />
      </div>
    );
  }
  if (isError) {
    return (
      <div className="p-10 text-center text-red-500">
        Failed to load appointments.
      </div>
    );
  }

  const appointments = data?.res || [];

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-3xl font-black tracking-tight">Appointments</h1>
        <p className="text-slate-500 font-medium">
          Manage scheduling requests from the website and walk-ins.
        </p>
      </div>

      <Card className="card shadow-sm">
        <CardHeader className="flex flex-row items-center justify-between">
          <div>
            <CardTitle>All Appointments</CardTitle>
            <CardDescription>{appointments.length} record(s)</CardDescription>
          </div>
          <div className="flex gap-2">
            <Select value={status} onValueChange={setStatus}>
              <SelectTrigger className="w-40">
                <SelectValue />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="all">All statuses</SelectItem>
                <SelectItem value="requested">Requested</SelectItem>
                <SelectItem value="scheduled">Scheduled</SelectItem>
                <SelectItem value="confirmed">Confirmed</SelectItem>
                <SelectItem value="completed">Completed</SelectItem>
                <SelectItem value="cancelled">Cancelled</SelectItem>
              </SelectContent>
            </Select>
            <NewAppointmentModal onSaved={refetch} />
          </div>
        </CardHeader>
        <CardContent>
          <div className="rounded-md border border-zinc-300 dark:border-zinc-700">
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>Patient</TableHead>
                  <TableHead>Doctor / Dept.</TableHead>
                  <TableHead>Date</TableHead>
                  <TableHead>Type</TableHead>
                  <TableHead>Status</TableHead>
                  <TableHead className="text-right">Actions</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {appointments.length === 0 ? (
                  <TableRow>
                    <TableCell
                      colSpan={6}
                      className="text-center h-24 text-muted-foreground"
                    >
                      No appointments found.
                    </TableCell>
                  </TableRow>
                ) : (
                  appointments.map((a) => (
                    <TableRow key={a._id}>
                      <TableCell className="font-medium">
                        <div className="flex items-center gap-2">
                          <CalendarClock size={14} className="text-slate-400" />
                          <div>
                            <p>{a.patientName}</p>
                            <p className="text-xs text-slate-500">
                              {a.patientEmail}
                            </p>
                          </div>
                        </div>
                      </TableCell>
                      <TableCell>
                        {a.doctorName || a.department || "Unassigned"}
                      </TableCell>
                      <TableCell className="text-sm text-slate-500">
                        {new Date(a.date).toLocaleDateString()}
                        {a.time ? ` • ${a.time}` : ""}
                      </TableCell>
                      <TableCell>
                        {a.isVirtual ? (
                          <Badge variant="secondary" className="gap-1">
                            <Video size={12} /> Virtual
                          </Badge>
                        ) : (
                          <Badge variant="secondary">In-person</Badge>
                        )}
                      </TableCell>
                      <TableCell>{statusBadge(a.status)}</TableCell>
                      <TableCell className="text-right">
                        <div className="flex justify-end gap-2">
                          {["requested", "scheduled"].includes(a.status) && (
                            <Button
                              size="sm"
                              variant="outline"
                              disabled={updateMutation.isPending}
                              onClick={() =>
                                updateMutation.mutate({
                                  id: a._id,
                                  data: { status: "confirmed" },
                                })
                              }
                            >
                              Confirm
                            </Button>
                          )}
                          {a.status !== "cancelled" &&
                            a.status !== "completed" && (
                              <Button
                                size="sm"
                                variant="destructive"
                                disabled={updateMutation.isPending}
                                onClick={() =>
                                  updateMutation.mutate({
                                    id: a._id,
                                    data: { status: "cancelled" },
                                  })
                                }
                              >
                                Cancel
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
