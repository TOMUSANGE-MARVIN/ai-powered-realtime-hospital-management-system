import { useEffect, useState } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { toast } from "sonner";
import {
  AlertTriangle,
  CheckCircle2,
  Clock,
  CreditCard,
  RefreshCw,
  RotateCcw,
  Smartphone,
  Wallet,
  XCircle,
} from "lucide-react";
import { getAdminPayments, refundAdminPayment, syncAdminPayment } from "@/lib/api";
import type { AdminPayment } from "@/types";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
import { Checkbox } from "@/components/ui/checkbox";
import {
  Dialog,
  DialogContent,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import {
  Sheet,
  SheetContent,
  SheetDescription,
  SheetHeader,
  SheetTitle,
} from "@/components/ui/sheet";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import { Textarea } from "@/components/ui/textarea";
import CustomPagination from "@/components/global/CustomPagination";
import GlobalSearch from "@/components/global/GlobalSearch";
import Loader from "@/components/global/Loader";

export function meta() {
  return [{ title: "Payments | Ask Musawo" }];
}

const ugx = (n: number) => `UGX ${n.toLocaleString()}`;
const when = (iso: string) =>
  new Date(iso).toLocaleString(undefined, { dateStyle: "medium", timeStyle: "short" });
const selectClass = "h-9 rounded-md border bg-background px-3 text-sm";

const STATUS_BADGE: Record<string, string> = {
  paid: "bg-emerald-100 text-emerald-700 dark:bg-emerald-900/30 dark:text-emerald-400",
  pending: "bg-amber-100 text-amber-700 dark:bg-amber-900/30 dark:text-amber-400",
  failed: "bg-red-100 text-red-700 dark:bg-red-900/30 dark:text-red-400",
  reversed: "bg-violet-100 text-violet-700 dark:bg-violet-900/30 dark:text-violet-400",
};
const STATUS_LABEL: Record<string, string> = {
  paid: "Paid",
  pending: "Pending",
  failed: "Failed",
  reversed: "Refunded",
};

function StatusBadge({ p }: { p: AdminPayment }) {
  return (
    <div className="flex flex-col items-start gap-1">
      <Badge className={STATUS_BADGE[p.status]}>{STATUS_LABEL[p.status] ?? p.status}</Badge>
      {p.refundStatus === "requested" && (
        <span className="flex items-center gap-1 text-xs text-amber-600">
          <Clock size={12} /> Refund {ugx(p.refundAmount ?? 0)} requested
        </span>
      )}
    </div>
  );
}

function Method({ p }: { p: AdminPayment }) {
  if (!p.methodType) return <span className="text-muted-foreground">Not chosen yet</span>;
  const Icon = p.methodType === "card" ? CreditCard : Smartphone;
  return (
    <span className="flex items-center gap-1.5">
      <Icon size={14} className="text-muted-foreground" />
      {p.method}
    </span>
  );
}

/** Why a payment can't be refunded, or null when it can. */
function refundBlocker(p: AdminPayment, pesapalConfigured: boolean) {
  if (p.status !== "paid") return "Only completed payments can be refunded.";
  if (p.refundStatus) return "A refund was already requested — Pesapal allows one per payment.";
  if (!p.reference) return "No Pesapal confirmation code yet — sync this payment first.";
  if (!pesapalConfigured) return "Pesapal isn't configured on this server.";
  return null;
}

function RefundDialog({
  payment,
  onClose,
}: {
  payment: AdminPayment | null;
  onClose: () => void;
}) {
  const queryClient = useQueryClient();
  const [amount, setAmount] = useState("");
  const [reason, setReason] = useState("");
  const [cancel, setCancel] = useState(true);
  useEffect(() => {
    if (payment) {
      setAmount(String(payment.amount));
      setReason("");
      setCancel(!!payment.appointment && !["completed", "cancelled"].includes(payment.appointment.status));
    }
  }, [payment]);

  const refund = useMutation({
    mutationFn: refundAdminPayment,
    onSuccess: () => {
      toast.success("Refund requested. Approve it in your Pesapal merchant account.");
      queryClient.invalidateQueries({ queryKey: ["admin-payments"] });
      onClose();
    },
    onError: (e: any) => toast.error(e.message),
  });

  if (!payment) return null;
  const isCard = payment.methodType === "card";
  const value = Number(amount);
  const amountError =
    !Number.isInteger(value) || value <= 0
      ? "Enter a whole amount in UGX"
      : value > payment.amount
        ? `No more than ${ugx(payment.amount)}`
        : null;
  const openAppointment =
    payment.appointment && !["completed", "cancelled"].includes(payment.appointment.status);

  return (
    <Dialog open onOpenChange={(open) => !open && onClose()}>
      <DialogContent className="card sm:max-w-md">
        <DialogHeader>
          <DialogTitle>Refund {payment.patient?.name ?? "this payment"}</DialogTitle>
        </DialogHeader>
        <div className="space-y-4 text-sm">
          <div className="rounded-lg border p-3 space-y-1">
            <div className="flex justify-between">
              <span className="text-muted-foreground">Paid</span>
              <span className="font-semibold">{ugx(payment.amount)}</span>
            </div>
            <div className="flex justify-between">
              <span className="text-muted-foreground">Method</span>
              <Method p={payment} />
            </div>
            <div className="flex justify-between">
              <span className="text-muted-foreground">Confirmation code</span>
              <span className="font-mono">{payment.reference}</span>
            </div>
          </div>
          <div className="space-y-2">
            <Label htmlFor="refund-amount">Amount to refund (UGX)</Label>
            <Input
              id="refund-amount"
              inputMode="numeric"
              value={amount}
              disabled={!isCard}
              onChange={(e) => setAmount(e.target.value.replace(/[^\d]/g, ""))}
            />
            {!isCard && (
              <p className="text-xs text-muted-foreground">
                Mobile money payments can only be refunded in full.
              </p>
            )}
            {amountError && isCard && <p className="text-xs text-destructive">{amountError}</p>}
          </div>
          <div className="space-y-2">
            <Label htmlFor="refund-reason">Reason</Label>
            <Textarea
              id="refund-reason"
              rows={3}
              maxLength={200}
              placeholder="e.g. Doctor unavailable, call could not connect"
              value={reason}
              onChange={(e) => setReason(e.target.value)}
            />
          </div>
          {openAppointment && (
            <label className="flex items-start gap-2">
              <Checkbox checked={cancel} onCheckedChange={(v) => setCancel(v === true)} />
              <span>
                Also cancel the appointment on{" "}
                {new Date(payment.appointment!.date).toLocaleDateString()}
              </span>
            </label>
          )}
          <div className="flex gap-2 rounded-lg border border-amber-300 bg-amber-50 dark:bg-amber-900/20 p-3 text-xs">
            <AlertTriangle size={16} className="shrink-0 text-amber-600" />
            <span>
              Pesapal allows only one refund per payment, and you must approve it
              in your Pesapal merchant account. The payment shows as refunded once
              Pesapal completes it.
            </span>
          </div>
        </div>
        <DialogFooter>
          <Button variant="outline" onClick={onClose}>
            Cancel
          </Button>
          <Button
            variant="destructive"
            disabled={!!amountError || !reason.trim() || refund.isPending}
            onClick={() =>
              refund.mutate({
                id: payment.id,
                amount: value,
                reason: reason.trim(),
                cancelAppointment: !!openAppointment && cancel,
              })
            }
          >
            Request refund of {Number.isInteger(value) && value > 0 ? ugx(value) : "…"}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}

function PaymentSheet({
  payment,
  pesapalConfigured,
  onClose,
  onRefund,
}: {
  payment: AdminPayment | null;
  pesapalConfigured: boolean;
  onClose: () => void;
  onRefund: (p: AdminPayment) => void;
}) {
  const queryClient = useQueryClient();
  const sync = useMutation({
    mutationFn: syncAdminPayment,
    onSuccess: ({ changed, payment: p }) => {
      toast.success(changed ? `Updated: now ${STATUS_LABEL[p.status] ?? p.status}` : "No change from Pesapal");
      queryClient.invalidateQueries({ queryKey: ["admin-payments"] });
      onClose();
    },
    onError: (e: any) => toast.error(e.message),
  });

  const p = payment;
  const blocker = p ? refundBlocker(p, pesapalConfigured) : null;
  const canSync =
    p && pesapalConfigured && (p.status === "pending" || p.refundStatus === "requested");

  return (
    <Sheet open={!!p} onOpenChange={(open) => !open && onClose()}>
      <SheetContent className="w-full sm:max-w-md overflow-y-auto">
        {p && (
          <>
            <SheetHeader>
              <SheetTitle>{ugx(p.amount)}</SheetTitle>
              <SheetDescription>
                {p.patient?.name ?? "Unknown patient"} → {p.doctor?.name ?? "Unknown doctor"}
              </SheetDescription>
            </SheetHeader>
            <div className="px-4 pb-6 space-y-5 text-sm">
              <StatusBadge p={p} />
              <dl className="grid grid-cols-[auto_1fr] gap-x-4 gap-y-2">
                <dt className="text-muted-foreground">Started</dt>
                <dd>{when(p.createdAt)}</dd>
                <dt className="text-muted-foreground">Method</dt>
                <dd><Method p={p} /></dd>
                <dt className="text-muted-foreground">Confirmation</dt>
                <dd className="font-mono">{p.reference ?? "—"}</dd>
                <dt className="text-muted-foreground">Voucher</dt>
                <dd>{p.voucherCode ? `${p.voucherCode} (−${ugx(p.discount)})` : "—"}</dd>
                <dt className="text-muted-foreground">Tax</dt>
                <dd>{p.tax ? ugx(p.tax) : "—"}</dd>
                <dt className="text-muted-foreground">Patient email</dt>
                <dd className="break-all">{p.patient?.email ?? "—"}</dd>
                <dt className="text-muted-foreground">Appointment</dt>
                <dd>
                  {p.appointment
                    ? `${new Date(p.appointment.date).toLocaleDateString()}${p.appointment.time ? ` ${p.appointment.time}` : ""} · ${p.appointment.status.replace("_", " ")}`
                    : "Not booked (payment didn't complete or booking failed)"}
                </dd>
              </dl>
              {p.refundStatus && (
                <div className="rounded-lg border p-3 space-y-1">
                  <div className="font-semibold flex items-center gap-2">
                    <RotateCcw size={14} />
                    Refund {p.refundStatus === "completed" ? "completed" : "requested"} ·{" "}
                    {ugx(p.refundAmount ?? 0)}
                  </div>
                  <div className="text-muted-foreground">
                    By {p.refundRequestedBy} on {p.refundRequestedAt ? when(p.refundRequestedAt) : "—"}
                  </div>
                  {p.refundReason && <div>“{p.refundReason}”</div>}
                </div>
              )}
              <div className="flex flex-wrap gap-2">
                {canSync && (
                  <Button
                    variant="outline"
                    className="gap-2"
                    disabled={sync.isPending}
                    onClick={() => sync.mutate(p.id)}
                  >
                    <RefreshCw size={14} className={sync.isPending ? "animate-spin" : ""} />
                    Check with Pesapal
                  </Button>
                )}
                <Button
                  variant="destructive"
                  className="gap-2"
                  disabled={!!blocker}
                  onClick={() => onRefund(p)}
                >
                  <RotateCcw size={14} /> Refund
                </Button>
              </div>
              {blocker && <p className="text-xs text-muted-foreground">{blocker}</p>}
            </div>
          </>
        )}
      </SheetContent>
    </Sheet>
  );
}

export default function Payments() {
  const [period, setPeriod] = useState("month");
  const [status, setStatus] = useState("all");
  const [method, setMethod] = useState("all");
  const [search, setSearch] = useState("");
  const [debounced, setDebounced] = useState("");
  const [page, setPage] = useState(1);
  const [selected, setSelected] = useState<AdminPayment | null>(null);
  const [refunding, setRefunding] = useState<AdminPayment | null>(null);

  useEffect(() => {
    const t = setTimeout(() => setDebounced(search), 300);
    return () => clearTimeout(t);
  }, [search]);
  useEffect(() => setPage(1), [period, status, method, debounced]);

  const { data, isLoading, isError, isFetching } = useQuery({
    queryKey: ["admin-payments", period, status, method, debounced, page],
    queryFn: () => getAdminPayments({ period, status, method, search: debounced, page }),
    placeholderData: (previous) => previous,
  });

  if (isLoading) {
    return (
      <div className="flex justify-center items-center min-h-[60vh]">
        <Loader label="Loading payments..." />
      </div>
    );
  }
  if (isError || !data) {
    return <div className="p-10 text-center text-red-500">Failed to load payments.</div>;
  }
  const s = data.summary;

  return (
    <div className="space-y-6">
      <div className="flex flex-col md:flex-row md:items-end justify-between gap-4">
        <div>
          <h1 className="text-3xl font-black tracking-tight">Payments</h1>
          <p className="text-slate-500 font-medium">
            Every Pesapal consultation payment, with status checks and refunds.
          </p>
        </div>
        <select aria-label="Period" className={selectClass} value={period} onChange={(e) => setPeriod(e.target.value)}>
          <option value="week">Last 7 days</option>
          <option value="month">Last 30 days</option>
          <option value="quarter">Last 3 months</option>
          <option value="year">Last 12 months</option>
          <option value="all">All time</option>
        </select>
      </div>

      {!data.pesapalConfigured && (
        <div className="flex gap-2 rounded-lg border border-amber-300 bg-amber-50 dark:bg-amber-900/20 p-3 text-sm">
          <AlertTriangle size={16} className="shrink-0 text-amber-600" />
          Pesapal isn't configured on this server, so status checks and refunds are unavailable.
        </div>
      )}

      <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
        {[
          { label: "Collected", value: ugx(s.collected), hint: `${s.paidCount} paid · ${ugx(s.tax)} tax`, icon: <Wallet size={16} /> },
          { label: "Pending", value: String(s.pendingCount), hint: "Checkout started, not finished", icon: <Clock size={16} /> },
          { label: "Failed", value: String(s.failedCount), hint: "Declined or abandoned", icon: <XCircle size={16} /> },
          {
            label: "Refunded",
            value: ugx(s.refunded),
            hint: `${s.refundedCount} done · ${s.refundsRequested} awaiting Pesapal (${ugx(s.refundsRequestedAmount)})`,
            icon: <RotateCcw size={16} />,
          },
        ].map((c) => (
          <div key={c.label} className="card rounded-xl p-4 shadow-sm space-y-1">
            <div className="flex items-center justify-between text-sm text-muted-foreground">
              {c.label}
              {c.icon}
            </div>
            <div className="text-2xl font-black tracking-tight">{c.value}</div>
            <div className="text-xs text-muted-foreground">{c.hint}</div>
          </div>
        ))}
      </div>

      <Card className="card shadow-sm">
        <CardHeader className="flex flex-col md:flex-row md:items-center justify-between gap-3">
          <div>
            <CardTitle>Transactions</CardTitle>
            <CardDescription>{data.pagination.total} matching · click a row for details</CardDescription>
          </div>
          <div className="flex flex-wrap gap-2">
            <GlobalSearch search={search} setSearch={setSearch} title="name, code, voucher" />
            <select aria-label="Status" className={selectClass} value={status} onChange={(e) => setStatus(e.target.value)}>
              <option value="all">All statuses</option>
              <option value="paid">Paid</option>
              <option value="pending">Pending</option>
              <option value="failed">Failed</option>
              <option value="reversed">Refunded</option>
              <option value="refund_requested">Refund requested</option>
            </select>
            <select aria-label="Method" className={selectClass} value={method} onChange={(e) => setMethod(e.target.value)}>
              <option value="all">All methods</option>
              <option value="mobile">Mobile money</option>
              <option value="card">Card</option>
            </select>
          </div>
        </CardHeader>
        <CardContent className="p-0">
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead className="pl-6">Date</TableHead>
                <TableHead>Patient → Doctor</TableHead>
                <TableHead>Method</TableHead>
                <TableHead className="text-right">Amount</TableHead>
                <TableHead>Status</TableHead>
                <TableHead className="pr-6">Booked</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody className={isFetching ? "opacity-60" : ""}>
              {data.payments.length === 0 ? (
                <TableRow>
                  <TableCell colSpan={6} className="text-center h-24 text-muted-foreground">
                    No payments match these filters.
                  </TableCell>
                </TableRow>
              ) : (
                data.payments.map((p) => (
                  <TableRow key={p.id} className="cursor-pointer" onClick={() => setSelected(p)}>
                    <TableCell className="pl-6 whitespace-nowrap">{when(p.createdAt)}</TableCell>
                    <TableCell>
                      <div className="font-medium">{p.patient?.name ?? "—"}</div>
                      <div className="text-xs text-muted-foreground">{p.doctor?.name ?? "—"}</div>
                    </TableCell>
                    <TableCell><Method p={p} /></TableCell>
                    <TableCell className="text-right">
                      <div className="font-semibold">{ugx(p.amount)}</div>
                      {p.voucherCode && (
                        <div className="text-xs text-muted-foreground">{p.voucherCode}</div>
                      )}
                    </TableCell>
                    <TableCell><StatusBadge p={p} /></TableCell>
                    <TableCell className="pr-6">
                      {p.appointment ? (
                        <CheckCircle2 size={16} className="text-emerald-600" />
                      ) : p.status === "paid" ? (
                        <span
                          className="flex items-center gap-1 text-xs text-amber-600"
                          title="Paid but no appointment is linked to this payment"
                        >
                          <AlertTriangle size={14} /> Not booked
                        </span>
                      ) : (
                        <span className="text-muted-foreground">—</span>
                      )}
                    </TableCell>
                  </TableRow>
                ))
              )}
            </TableBody>
          </Table>
          {data.pagination.totalPages > 1 && (
            <CustomPagination
              loading={isFetching}
              currentPage={page}
              setPage={setPage}
              totalPages={data.pagination.totalPages}
            />
          )}
        </CardContent>
      </Card>

      <PaymentSheet
        payment={selected}
        pesapalConfigured={data.pesapalConfigured}
        onClose={() => setSelected(null)}
        onRefund={(p) => {
          setSelected(null);
          setRefunding(p);
        }}
      />
      <RefundDialog payment={refunding} onClose={() => setRefunding(null)} />
    </div>
  );
}
