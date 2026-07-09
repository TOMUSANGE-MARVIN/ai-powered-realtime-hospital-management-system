import { useMutation, useQuery } from "@tanstack/react-query";
import { getAppointments, updateAppointment } from "@/lib/api";
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
import { Video, Copy, PhoneCall, CheckCircle2 } from "lucide-react";

export function meta() {
  return [{ title: "Telemedicine | Ask Musawo" }];
}

export default function Telemedicine() {
  const { data, isLoading, isError, refetch } = useQuery({
    queryKey: ["appointments", "virtual"],
    queryFn: () => getAppointments({ isVirtual: true, limit: 50 }),
    refetchInterval: 15000,
  });

  const updateMutation = useMutation({
    mutationFn: updateAppointment,
    onSuccess: () => refetch(),
    onError: (e: any) => toast.error(e.message || "Failed to update session"),
  });

  if (isLoading) {
    return (
      <div className="flex justify-center items-center min-h-[60vh]">
        <Loader label="Loading Telemedicine Queue..." />
      </div>
    );
  }
  if (isError) {
    return (
      <div className="p-10 text-center text-red-500">
        Failed to load virtual visits.
      </div>
    );
  }

  const visits = (data?.res || []).filter((a) => a.status !== "cancelled");

  const copyMeetingId = (id: string) => {
    navigator.clipboard.writeText(id);
    toast.success("Meeting ID copied to clipboard");
  };

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-3xl font-black tracking-tight">Telemedicine</h1>
        <p className="text-slate-500 font-medium">
          Manage the queue of scheduled virtual consultations.
        </p>
      </div>

      {visits.length === 0 ? (
        <Card className="card shadow-sm">
          <CardContent className="p-16 text-center text-slate-500">
            No virtual visits scheduled.
          </CardContent>
        </Card>
      ) : (
        <div className="grid grid-cols-1 lg:grid-cols-2 xl:grid-cols-3 gap-4">
          {visits.map((v) => (
            <Card key={v._id} className="card shadow-sm">
              <CardHeader>
                <CardTitle className="text-base flex items-center gap-2">
                  <Video size={16} className="text-slate-400" />
                  {v.patientName}
                </CardTitle>
                <CardDescription>
                  {v.doctorName || v.department || "Unassigned"} •{" "}
                  {new Date(v.date).toLocaleDateString()}
                  {v.time ? ` ${v.time}` : ""}
                </CardDescription>
              </CardHeader>
              <CardContent className="space-y-3">
                <Badge
                  className={
                    v.status === "in-progress"
                      ? "bg-violet-100 text-violet-700 border-violet-200 dark:bg-violet-900/30 dark:text-violet-400"
                      : v.status === "completed"
                        ? "bg-teal-100 text-teal-700 border-teal-200 dark:bg-teal-900/30 dark:text-teal-400"
                        : "bg-blue-100 text-blue-700 border-blue-200 dark:bg-blue-900/30 dark:text-blue-400"
                  }
                >
                  {v.status.replace("-", " ")}
                </Badge>

                {v.meetingId ? (
                  <div className="flex items-center justify-between text-xs bg-slate-50 dark:bg-slate-900 rounded-lg p-2 font-mono">
                    <span className="truncate">{v.meetingId}</span>
                    <Button
                      variant="ghost"
                      size="icon"
                      className="size-6"
                      onClick={() => copyMeetingId(v.meetingId!)}
                    >
                      <Copy size={12} />
                    </Button>
                  </div>
                ) : (
                  <p className="text-xs text-slate-400 italic">
                    Meeting ID generated once confirmed
                  </p>
                )}

                <div className="flex gap-2">
                  {v.status !== "in-progress" && v.status !== "completed" && (
                    <Button
                      className="flex-1 gap-2"
                      size="sm"
                      disabled={updateMutation.isPending}
                      onClick={() =>
                        updateMutation.mutate({
                          id: v._id,
                          data: { status: "in-progress", isVirtual: true },
                        })
                      }
                    >
                      <PhoneCall size={14} /> Start Session
                    </Button>
                  )}
                  {v.status === "in-progress" && (
                    <Button
                      className="flex-1 gap-2"
                      size="sm"
                      variant="outline"
                      disabled={updateMutation.isPending}
                      onClick={() =>
                        updateMutation.mutate({
                          id: v._id,
                          data: { status: "completed" },
                        })
                      }
                    >
                      <CheckCircle2 size={14} /> Complete
                    </Button>
                  )}
                </div>
              </CardContent>
            </Card>
          ))}
        </div>
      )}
    </div>
  );
}
