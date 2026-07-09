import { useState } from "react";
import { useMutation, useQuery } from "@tanstack/react-query";
import {
  getSupportTickets,
  createSupportTicket,
  updateSupportTicketStatus,
} from "@/lib/api";
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
import { Textarea } from "@/components/ui/textarea";
import Loader from "@/components/global/Loader";
import { LifeBuoy, Plus } from "lucide-react";

export function meta() {
  return [{ title: "Support | Ask Musawo" }];
}

function statusBadge(status: string) {
  const map: Record<string, string> = {
    open: "bg-amber-100 text-amber-700 border-amber-200 dark:bg-amber-900/30 dark:text-amber-400",
    in_progress:
      "bg-blue-100 text-blue-700 border-blue-200 dark:bg-blue-900/30 dark:text-blue-400",
    resolved:
      "bg-emerald-100 text-emerald-700 border-emerald-200 dark:bg-emerald-900/30 dark:text-emerald-400",
  };
  return <Badge className={map[status]}>{status.replace("_", " ")}</Badge>;
}

function NewTicketModal({ onSaved }: { onSaved: () => void }) {
  const [open, setOpen] = useState(false);
  const [priority, setPriority] = useState("medium");
  const form = useForm({ defaultValues: { subject: "", message: "" } });

  const mutation = useMutation({
    mutationFn: createSupportTicket,
    onSuccess: () => {
      toast.success("Support ticket submitted");
      setOpen(false);
      form.reset();
      onSaved();
    },
    onError: (e: any) => toast.error(e.message || "Failed to submit ticket"),
  });

  const onSubmit = (data: any) => {
    mutation.mutate({ ...data, priority });
  };

  return (
    <Dialog open={open} onOpenChange={setOpen}>
      <DialogTrigger asChild>
        <Button className="gap-2">
          <Plus size={16} /> New Ticket
        </Button>
      </DialogTrigger>
      <DialogContent className="sm:max-w-lg card">
        <DialogHeader>
          <DialogTitle>Contact Support</DialogTitle>
        </DialogHeader>
        <form onSubmit={form.handleSubmit(onSubmit)} className="space-y-3">
          <CustomInput
            control={form.control}
            name="subject"
            label="Subject"
            placeholder="What do you need help with?"
          />
          <div className="space-y-1.5">
            <label className="text-xs font-bold text-slate-500 uppercase tracking-widest ml-1">
              Message
            </label>
            <Textarea
              className="min-h-24"
              {...form.register("message")}
              placeholder="Describe the issue in detail"
            />
          </div>
          <div className="space-y-1.5">
            <label className="text-xs font-bold text-slate-500 uppercase tracking-widest ml-1">
              Priority
            </label>
            <Select value={priority} onValueChange={setPriority}>
              <SelectTrigger className="w-full">
                <SelectValue />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="low">Low</SelectItem>
                <SelectItem value="medium">Medium</SelectItem>
                <SelectItem value="high">High</SelectItem>
              </SelectContent>
            </Select>
          </div>
          <Button type="submit" className="w-full" disabled={mutation.isPending}>
            Submit Ticket
          </Button>
        </form>
      </DialogContent>
    </Dialog>
  );
}

export default function Support() {
  const { data: session } = authClient.useSession();
  const isAdmin = session?.user?.role === "admin";

  const { data, isLoading, isError, refetch } = useQuery({
    queryKey: ["support-tickets"],
    queryFn: getSupportTickets,
  });

  const statusMutation = useMutation({
    mutationFn: updateSupportTicketStatus,
    onSuccess: () => {
      toast.success("Ticket updated");
      refetch();
    },
    onError: (e: any) => toast.error(e.message || "Failed to update ticket"),
  });

  if (isLoading) {
    return (
      <div className="flex justify-center items-center min-h-[60vh]">
        <Loader label="Loading Support Tickets..." />
      </div>
    );
  }
  if (isError) {
    return (
      <div className="p-10 text-center text-red-500">
        Failed to load support tickets.
      </div>
    );
  }

  const tickets = data || [];

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-black tracking-tight">Support</h1>
          <p className="text-slate-500 font-medium">
            {isAdmin
              ? "All support requests raised by staff and patients."
              : "Get help from the Ask Musawo team."}
          </p>
        </div>
        <NewTicketModal onSaved={refetch} />
      </div>

      {tickets.length === 0 ? (
        <Card className="card shadow-sm">
          <CardContent className="p-16 flex flex-col items-center justify-center text-center gap-3">
            <LifeBuoy size={40} className="text-slate-300" />
            <p className="text-slate-500 font-medium">No support tickets yet.</p>
          </CardContent>
        </Card>
      ) : (
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
          {tickets.map((t) => (
            <Card key={t._id} className="card shadow-sm">
              <CardHeader className="flex flex-row items-start justify-between">
                <div>
                  <CardTitle className="text-base">{t.subject}</CardTitle>
                  <CardDescription>
                    {isAdmin ? `${t.userName} • ` : ""}
                    {new Date(t.createdAt).toLocaleDateString()}
                  </CardDescription>
                </div>
                {statusBadge(t.status)}
              </CardHeader>
              <CardContent className="space-y-3">
                <p className="text-sm text-slate-600 dark:text-slate-300">
                  {t.message}
                </p>
                <Badge variant="outline" className="capitalize">
                  {t.priority} priority
                </Badge>
                {isAdmin && t.status !== "resolved" && (
                  <div className="flex gap-2 pt-2">
                    {t.status === "open" && (
                      <Button
                        size="sm"
                        variant="outline"
                        disabled={statusMutation.isPending}
                        onClick={() =>
                          statusMutation.mutate({ id: t._id, status: "in_progress" })
                        }
                      >
                        Start Working
                      </Button>
                    )}
                    <Button
                      size="sm"
                      disabled={statusMutation.isPending}
                      onClick={() =>
                        statusMutation.mutate({ id: t._id, status: "resolved" })
                      }
                    >
                      Mark Resolved
                    </Button>
                  </div>
                )}
              </CardContent>
            </Card>
          ))}
        </div>
      )}
    </div>
  );
}
