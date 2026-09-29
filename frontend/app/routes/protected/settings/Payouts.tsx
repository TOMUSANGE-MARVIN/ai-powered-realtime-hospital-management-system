import { useState } from "react";
import { useMutation, useQuery } from "@tanstack/react-query";
import { toast } from "sonner";
import { getWithdrawals, updateWithdrawal } from "@/lib/api";
import type { Withdrawal } from "@/types";
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
import Loader from "@/components/global/Loader";

export function meta() {
  return [{ title: "Doctor Payouts | Ask Musawo" }];
}

const FILTERS = ["requested", "approved", "paid", "rejected", "all"] as const;

const STATUS_BADGE: Record<Withdrawal["status"], string> = {
  requested: "bg-orange-100 text-orange-700",
  approved: "bg-teal-100 text-teal-700",
  paid: "bg-emerald-100 text-emerald-700",
  rejected: "bg-red-100 text-red-700",
};

export default function Payouts() {
  const [filter, setFilter] = useState<(typeof FILTERS)[number]>("requested");

  const { data, isLoading, isError, refetch } = useQuery({
    queryKey: ["withdrawals", filter],
    queryFn: () => getWithdrawals(filter),
  });

  const mutation = useMutation({
    mutationFn: updateWithdrawal,
    onSuccess: (_, vars) => {
      toast.success(`Marked ${vars.status}`);
      refetch();
    },
    onError: (e: any) => toast.error(e.message || "Failed to update"),
  });

  const act = (w: Withdrawal, status: Withdrawal["status"]) => {
    let adminNote: string | undefined;
    if (status === "rejected") {
      adminNote = window.prompt("Reason for rejecting (shown to the doctor)") ?? undefined;
      if (adminNote === undefined) return;
    }
    if (status === "paid") {
      adminNote =
        window.prompt("Transaction reference for this payout (optional)") ?? undefined;
    }
    mutation.mutate({ id: w.id, status, adminNote });
  };

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-3xl font-black tracking-tight">Doctor Payouts</h1>
        <p className="text-slate-500 font-medium">
          Approve withdrawal requests, send the money by mobile money or bank,
          then mark them paid.
        </p>
      </div>

      <Card className="card shadow-sm">
        <CardHeader className="flex flex-row items-center justify-between gap-4">
          <div>
            <CardTitle>Withdrawal requests</CardTitle>
            <CardDescription>
              Requested and approved amounts are already held from the
              doctor's available balance
            </CardDescription>
          </div>
          <div className="flex flex-wrap gap-2">
            {FILTERS.map((f) => (
              <Button
                key={f}
                size="sm"
                variant={filter === f ? "default" : "outline"}
                onClick={() => setFilter(f)}
                className="capitalize"
              >
                {f}
              </Button>
            ))}
          </div>
        </CardHeader>
        <CardContent>
          {isLoading ? (
            <div className="flex justify-center py-16">
              <Loader label="Loading payouts..." />
            </div>
          ) : isError ? (
            <div className="p-10 text-center text-red-500">
              Failed to load payouts.
            </div>
          ) : (
            <div className="rounded-md border border-zinc-300 dark:border-zinc-700">
              <Table>
                <TableHeader>
                  <TableRow>
                    <TableHead>Doctor</TableHead>
                    <TableHead>Amount (UGX)</TableHead>
                    <TableHead>Send to</TableHead>
                    <TableHead>Requested</TableHead>
                    <TableHead>Status</TableHead>
                    <TableHead className="text-right">Actions</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {(data || []).length === 0 ? (
                    <TableRow>
                      <TableCell
                        colSpan={6}
                        className="text-center h-24 text-muted-foreground"
                      >
                        Nothing here.
                      </TableCell>
                    </TableRow>
                  ) : (
                    data!.map((w) => (
                      <TableRow key={w.id}>
                        <TableCell className="font-medium">{w.doctorName}</TableCell>
                        <TableCell>{w.amount.toLocaleString()}</TableCell>
                        <TableCell>
                          <div className="font-medium">
                            {w.provider} ·{" "}
                            {w.method === "bank" ? "Bank" : "Mobile money"}
                          </div>
                          <div className="text-xs text-muted-foreground">
                            {w.accountName} · {w.accountNumber}
                          </div>
                        </TableCell>
                        <TableCell>
                          {new Date(w.createdAt).toLocaleDateString()}
                        </TableCell>
                        <TableCell>
                          <Badge className={`capitalize ${STATUS_BADGE[w.status]}`}>
                            {w.status}
                          </Badge>
                          {w.adminNote && (
                            <div className="text-xs text-muted-foreground mt-1">
                              {w.adminNote}
                            </div>
                          )}
                        </TableCell>
                        <TableCell className="text-right">
                          <div className="flex justify-end gap-2">
                            {w.status === "requested" && (
                              <Button
                                size="sm"
                                disabled={mutation.isPending}
                                onClick={() => act(w, "approved")}
                              >
                                Approve
                              </Button>
                            )}
                            {w.status === "approved" && (
                              <Button
                                size="sm"
                                disabled={mutation.isPending}
                                onClick={() => act(w, "paid")}
                              >
                                Mark paid
                              </Button>
                            )}
                            {(w.status === "requested" || w.status === "approved") && (
                              <Button
                                size="sm"
                                variant="destructive"
                                disabled={mutation.isPending}
                                onClick={() => act(w, "rejected")}
                              >
                                Reject
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
          )}
        </CardContent>
      </Card>
    </div>
  );
}
