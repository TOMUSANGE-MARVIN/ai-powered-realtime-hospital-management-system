import { useEffect, useState } from "react";
import { useQuery } from "@tanstack/react-query";
import {
  AlertTriangle,
  CheckCircle2,
  Clock,
  CreditCard,
  FileText,
  MapPin,
  Phone,
  PhoneMissed,
  Star,
  Video,
  Wallet,
  XCircle,
} from "lucide-react";
import { getCallLogs, getConsultations } from "@/lib/api";
import type { Consultation, OverviewPeriod } from "@/types";
import { Badge } from "@/components/ui/badge";
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
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
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import CustomPagination from "@/components/global/CustomPagination";
import GlobalSearch from "@/components/global/GlobalSearch";
import Loader from "@/components/global/Loader";

export function meta() {
  return [{ title: "Consultations | Ask Musawo" }];
}

const PERIODS: { value: OverviewPeriod; label: string }[] = [
  { value: "today", label: "Today" },
  { value: "week", label: "This Week" },
  { value: "month", label: "This Month" },
  { value: "year", label: "This Year" },
];

const STATUSES = [
  "all",
  "requested",
  "confirmed",
  "in_progress",
  "completed",
  "cancelled",
];

const STATUS_BADGE: Record<string, string> = {
  requested: "bg-orange-100 text-orange-700 dark:bg-orange-900/30 dark:text-orange-400",
  scheduled: "bg-blue-100 text-blue-700 dark:bg-blue-900/30 dark:text-blue-400",
  confirmed: "bg-blue-100 text-blue-700 dark:bg-blue-900/30 dark:text-blue-400",
  in_progress: "bg-amber-100 text-amber-700 dark:bg-amber-900/30 dark:text-amber-400",
  completed: "bg-emerald-100 text-emerald-700 dark:bg-emerald-900/30 dark:text-emerald-400",
  cancelled: "bg-red-100 text-red-700 dark:bg-red-900/30 dark:text-red-400",
};

const CALL_BADGE: Record<string, string> = {
  answered: "bg-emerald-100 text-emerald-700 dark:bg-emerald-900/30 dark:text-emerald-400",
  missed: "bg-red-100 text-red-700 dark:bg-red-900/30 dark:text-red-400",
  declined: "bg-red-100 text-red-700 dark:bg-red-900/30 dark:text-red-400",
  busy: "bg-orange-100 text-orange-700 dark:bg-orange-900/30 dark:text-orange-400",
  cancelled: "bg-muted text-muted-foreground",
};

const selectClass =
  "h-9 rounded-md border bg-background px-3 text-sm capitalize";

const duration = (seconds: number | null | undefined) => {
  if (!seconds) return "—";
  const m = Math.floor(seconds / 60);
  const s = seconds % 60;
  return m ? `${m}m ${String(s).padStart(2, "0")}s` : `${s}s`;
};

const when = (iso: string) =>
  new Date(iso).toLocaleString(undefined, {
    dateStyle: "medium",
    timeStyle: "short",
  });

function TypeLabel({ c }: { c: Consultation }) {
  const Icon =
    c.consultationType === "physical"
      ? MapPin
      : c.consultationType === "voice"
        ? Phone
        : Video;
  return (
    <span className="flex items-center gap-1.5 capitalize">
      <Icon size={14} className="text-muted-foreground" />
      {c.consultationType === "physical" ? "In person" : c.consultationType}
      {c.isEmergency && (
        <Badge variant="destructive" className="ml-1">
          Emergency
        </Badge>
      )}
    </span>
  );
}

function Stat({
  label,
  value,
  hint,
  icon,
}: {
  label: string;
  value: string;
  hint?: string;
  icon: React.ReactNode;
}) {
  return (
    <div className="card rounded-xl p-4 shadow-sm space-y-1">
      <div className="flex items-center justify-between text-sm text-muted-foreground">
        {label}
        {icon}
      </div>
      <div className="text-2xl font-black tracking-tight">{value}</div>
      {hint && <div className="text-xs text-muted-foreground">{hint}</div>}
    </div>
  );
}

/** Everything that happened around one consultation, in time order. */
function Timeline({ c }: { c: Consultation }) {
  const events: { at: string; icon: React.ReactNode; title: string; detail?: string }[] = [
    {
      at: c.createdAt,
      icon: <Clock size={14} />,
      title: "Booked",
      detail: c.reason || undefined,
    },
  ];
  events.push({
    at: c.date,
    icon: <Video size={14} />,
    title: `Scheduled ${c.consultationType === "physical" ? "visit" : `${c.consultationType} consultation`}`,
    detail: c.time ? `Slot: ${c.time}` : undefined,
  });
  if (c.payment) {
    events.push({
      at: c.payment.createdAt,
      icon: <CreditCard size={14} />,
      title: `Payment ${c.payment.status} · UGX ${c.payment.amount.toLocaleString()}`,
      detail: [
        c.payment.method,
        c.payment.voucherCode &&
          `voucher ${c.payment.voucherCode} (−UGX ${c.payment.discount.toLocaleString()})`,
      ]
        .filter(Boolean)
        .join(" · "),
    });
  }
  for (const call of c.calls) {
    events.push({
      at: call.createdAt,
      icon: call.status === "answered" ? <Phone size={14} /> : <PhoneMissed size={14} />,
      title: `${call.type === "video" ? "Video" : "Voice"} call ${call.status}`,
      detail: `${call.byDoctor ? "Doctor" : "Patient"} called${call.durationSeconds ? ` · ${duration(call.durationSeconds)}` : ""}`,
    });
  }
  if (c.prescription) {
    events.push({
      at: c.prescription.createdAt,
      icon: <FileText size={14} />,
      title: "Prescription issued",
      detail: `Status: ${c.prescription.status}`,
    });
  }
  events.sort((a, b) => new Date(a.at).getTime() - new Date(b.at).getTime());

  return (
    <ol className="relative border-l pl-5 space-y-5">
      {events.map((e, i) => (
        <li key={i}>
          <span className="absolute -left-2.5 flex size-5 items-center justify-center rounded-full border bg-background text-muted-foreground">
            {e.icon}
          </span>
          <div className="text-sm font-semibold">{e.title}</div>
          <div className="text-xs text-muted-foreground">{when(e.at)}</div>
          {e.detail && <div className="text-sm mt-0.5">{e.detail}</div>}
        </li>
      ))}
    </ol>
  );
}

function ConsultationSheet({
  c,
  onClose,
}: {
  c: Consultation | null;
  onClose: () => void;
}) {
  return (
    <Sheet open={!!c} onOpenChange={(open) => !open && onClose()}>
      <SheetContent className="w-full sm:max-w-md overflow-y-auto">
        {c && (
          <>
            <SheetHeader>
              <SheetTitle>
                {c.patientName} → {c.doctorName || "Unassigned"}
              </SheetTitle>
              <SheetDescription>
                {new Date(c.date).toLocaleDateString(undefined, { dateStyle: "full" })}
                {c.time ? ` · ${c.time}` : ""}
              </SheetDescription>
            </SheetHeader>
            <div className="px-4 pb-6 space-y-6">
              <div className="flex flex-wrap gap-2">
                <Badge className={`capitalize ${STATUS_BADGE[c.status] || ""}`}>
                  {c.status.replace("_", " ")}
                </Badge>
                <Badge variant="outline">
                  <TypeLabel c={c} />
                </Badge>
              </div>
              <div className="grid grid-cols-3 gap-3 text-center">
                <div className="rounded-lg border p-3">
                  <div className="text-xs text-muted-foreground">Talk time</div>
                  <div className="font-bold">{duration(c.talkSeconds)}</div>
                </div>
                <div className="rounded-lg border p-3">
                  <div className="text-xs text-muted-foreground">Paid</div>
                  <div className="font-bold">
                    {c.payment?.status === "paid"
                      ? `UGX ${c.payment.amount.toLocaleString()}`
                      : c.fee
                        ? "No"
                        : "Free"}
                  </div>
                </div>
                <div className="rounded-lg border p-3">
                  <div className="text-xs text-muted-foreground">Rating</div>
                  <div className="font-bold">{c.review ? `${c.review.rating} / 5` : "—"}</div>
                </div>
              </div>
              {c.review?.comment && (
                <blockquote className="border-l-2 pl-3 text-sm italic text-muted-foreground">
                  “{c.review.comment}”
                </blockquote>
              )}
              <div>
                <h4 className="text-sm font-bold mb-3">Timeline</h4>
                <Timeline c={c} />
              </div>
              {c.consultationType !== "physical" &&
                c.status === "completed" &&
                c.calls.length === 0 && (
                  <div className="flex gap-2 rounded-lg border border-amber-300 bg-amber-50 dark:bg-amber-900/20 p-3 text-sm">
                    <AlertTriangle size={16} className="shrink-0 text-amber-600" />
                    Marked completed but no in-app call was recorded around the
                    visit time.
                  </div>
                )}
            </div>
          </>
        )}
      </SheetContent>
    </Sheet>
  );
}

function ConsultationsTab({ period }: { period: OverviewPeriod }) {
  const [status, setStatus] = useState("all");
  const [type, setType] = useState("all");
  const [search, setSearch] = useState("");
  const [debounced, setDebounced] = useState("");
  const [page, setPage] = useState(1);
  const [selected, setSelected] = useState<Consultation | null>(null);

  useEffect(() => {
    const t = setTimeout(() => setDebounced(search), 300);
    return () => clearTimeout(t);
  }, [search]);
  useEffect(() => setPage(1), [period, status, type, debounced]);

  const { data, isLoading, isError, isFetching } = useQuery({
    queryKey: ["consultations", period, status, type, debounced, page],
    queryFn: () =>
      getConsultations({ period, status, type, search: debounced, page }),
    placeholderData: (previous) => previous,
  });

  if (isLoading) {
    return (
      <div className="flex justify-center py-20">
        <Loader label="Loading consultations..." />
      </div>
    );
  }
  if (isError || !data) {
    return (
      <div className="p-10 text-center text-red-500">
        Failed to load consultations.
      </div>
    );
  }

  const s = data.summary;
  return (
    <div className="space-y-6">
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
        <Stat
          label="Consultations"
          value={s.total.toLocaleString()}
          hint={`${s.upcoming} upcoming · ${s.inProgress} in progress`}
          icon={<Video size={16} />}
        />
        <Stat
          label="Completed"
          value={s.completed.toLocaleString()}
          hint={
            s.completionRate === null
              ? "No finished visits yet"
              : `${s.completionRate}% of finished visits · ${s.cancelled} cancelled`
          }
          icon={<CheckCircle2 size={16} />}
        />
        <Stat
          label="Avg. call length"
          value={s.avgCallSeconds === null ? "—" : duration(s.avgCallSeconds)}
          hint={`${s.missedCalls} missed or declined calls`}
          icon={<Phone size={16} />}
        />
        <Stat
          label="Revenue"
          value={`UGX ${s.revenue.toLocaleString()}`}
          hint="Paid consultations"
          icon={<Wallet size={16} />}
        />
      </div>

      <Card className="card shadow-sm">
        <CardHeader className="flex flex-col md:flex-row md:items-center justify-between gap-3">
          <div>
            <CardTitle>All consultations</CardTitle>
            <CardDescription>
              Click a row for payment, calls, review and prescription
            </CardDescription>
          </div>
          <div className="flex flex-wrap gap-2">
            <GlobalSearch search={search} setSearch={setSearch} title="patient or doctor" />
            <select
              aria-label="Status"
              className={selectClass}
              value={status}
              onChange={(e) => setStatus(e.target.value)}
            >
              {STATUSES.map((v) => (
                <option key={v} value={v}>
                  {v === "all" ? "All statuses" : v.replace("_", " ")}
                </option>
              ))}
            </select>
            <select
              aria-label="Type"
              className={selectClass}
              value={type}
              onChange={(e) => setType(e.target.value)}
            >
              <option value="all">All types</option>
              <option value="video">Video</option>
              <option value="voice">Voice</option>
              <option value="physical">In person</option>
            </select>
          </div>
        </CardHeader>
        <CardContent className="p-0">
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead className="pl-6">Patient → Doctor</TableHead>
                <TableHead>When</TableHead>
                <TableHead>Type</TableHead>
                <TableHead>Status</TableHead>
                <TableHead>Payment</TableHead>
                <TableHead>Calls</TableHead>
                <TableHead>Review</TableHead>
                <TableHead className="pr-6">Rx</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody className={isFetching ? "opacity-60" : ""}>
              {data.consultations.length === 0 ? (
                <TableRow>
                  <TableCell colSpan={8} className="text-center h-24 text-muted-foreground">
                    No consultations match these filters.
                  </TableCell>
                </TableRow>
              ) : (
                data.consultations.map((c) => {
                  const answered = c.calls.filter((x) => x.status === "answered").length;
                  return (
                    <TableRow
                      key={c.id}
                      className="cursor-pointer"
                      onClick={() => setSelected(c)}
                    >
                      <TableCell className="pl-6">
                        <div className="font-semibold">{c.patientName}</div>
                        <div className="text-xs text-muted-foreground">
                          {c.doctorName || "Unassigned"}
                        </div>
                      </TableCell>
                      <TableCell>
                        <div>{new Date(c.date).toLocaleDateString()}</div>
                        <div className="text-xs text-muted-foreground">{c.time || ""}</div>
                      </TableCell>
                      <TableCell>
                        <TypeLabel c={c} />
                      </TableCell>
                      <TableCell>
                        <Badge className={`capitalize ${STATUS_BADGE[c.status] || ""}`}>
                          {c.status.replace("_", " ")}
                        </Badge>
                      </TableCell>
                      <TableCell>
                        {c.payment ? (
                          <div>
                            <div className="font-medium">
                              UGX {c.payment.amount.toLocaleString()}
                            </div>
                            <div className="text-xs text-muted-foreground capitalize">
                              {c.payment.status}
                              {c.payment.voucherCode ? ` · ${c.payment.voucherCode}` : ""}
                            </div>
                          </div>
                        ) : (
                          <span className="text-muted-foreground">
                            {c.fee ? "Unpaid" : "Free"}
                          </span>
                        )}
                      </TableCell>
                      <TableCell>
                        {c.calls.length === 0 ? (
                          c.status === "completed" &&
                          c.consultationType !== "physical" ? (
                            <span
                              className="flex items-center gap-1 text-xs text-amber-600"
                              title="Marked completed but no in-app call was recorded"
                            >
                              <AlertTriangle size={14} /> No call
                            </span>
                          ) : (
                            <span className="text-muted-foreground">—</span>
                          )
                        ) : (
                          <div>
                            <div className="font-medium">
                              {answered}/{c.calls.length} answered
                            </div>
                            <div className="text-xs text-muted-foreground">
                              {duration(c.talkSeconds)}
                            </div>
                          </div>
                        )}
                      </TableCell>
                      <TableCell>
                        {c.review ? (
                          <span className="flex items-center gap-1 font-semibold">
                            <Star size={14} className="fill-amber-400 text-amber-400" />
                            {c.review.rating}
                          </span>
                        ) : (
                          <span className="text-muted-foreground">—</span>
                        )}
                      </TableCell>
                      <TableCell className="pr-6">
                        {c.prescription ? (
                          <CheckCircle2 size={16} className="text-emerald-600" />
                        ) : (
                          <span className="text-muted-foreground">—</span>
                        )}
                      </TableCell>
                    </TableRow>
                  );
                })
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
      <ConsultationSheet c={selected} onClose={() => setSelected(null)} />
    </div>
  );
}

function CallLogsTab({ period }: { period: OverviewPeriod }) {
  const [status, setStatus] = useState("all");
  const [page, setPage] = useState(1);
  useEffect(() => setPage(1), [period, status]);

  const { data, isLoading, isError, isFetching } = useQuery({
    queryKey: ["call-logs", period, status, page],
    queryFn: () => getCallLogs({ period, status, page }),
    placeholderData: (previous) => previous,
  });

  return (
    <Card className="card shadow-sm">
      <CardHeader className="flex flex-row items-center justify-between gap-3">
        <div>
          <CardTitle>Call logs</CardTitle>
          <CardDescription>Every in-app voice and video call</CardDescription>
        </div>
        <select
          aria-label="Call status"
          className={selectClass}
          value={status}
          onChange={(e) => setStatus(e.target.value)}
        >
          {["all", "answered", "missed", "declined", "busy", "cancelled"].map((v) => (
            <option key={v} value={v}>
              {v === "all" ? "All calls" : v}
            </option>
          ))}
        </select>
      </CardHeader>
      <CardContent className="p-0">
        {isLoading ? (
          <div className="flex justify-center py-16">
            <Loader label="Loading calls..." />
          </div>
        ) : isError || !data ? (
          <div className="p-10 text-center text-red-500">Failed to load call logs.</div>
        ) : (
          <>
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead className="pl-6">When</TableHead>
                  <TableHead>Caller → Callee</TableHead>
                  <TableHead>Type</TableHead>
                  <TableHead>Status</TableHead>
                  <TableHead className="pr-6">Duration</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody className={isFetching ? "opacity-60" : ""}>
                {data.calls.length === 0 ? (
                  <TableRow>
                    <TableCell colSpan={5} className="text-center h-24 text-muted-foreground">
                      No calls in this period.
                    </TableCell>
                  </TableRow>
                ) : (
                  data.calls.map((call) => (
                    <TableRow key={call.id}>
                      <TableCell className="pl-6">{when(call.createdAt)}</TableCell>
                      <TableCell>
                        <span className="font-medium">{call.callerName}</span>
                        <span className="text-muted-foreground"> → </span>
                        <span className="font-medium">{call.calleeName}</span>
                      </TableCell>
                      <TableCell className="capitalize">
                        <span className="flex items-center gap-1.5">
                          {call.type === "video" ? <Video size={14} /> : <Phone size={14} />}
                          {call.type}
                        </span>
                      </TableCell>
                      <TableCell>
                        <Badge className={`capitalize ${CALL_BADGE[call.status] || ""}`}>
                          {call.status === "missed" && <XCircle size={12} className="mr-1" />}
                          {call.status}
                        </Badge>
                      </TableCell>
                      <TableCell className="pr-6">{duration(call.durationSeconds)}</TableCell>
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
          </>
        )}
      </CardContent>
    </Card>
  );
}

export default function Consultations() {
  const [period, setPeriod] = useState<OverviewPeriod>("month");
  return (
    <div className="space-y-6">
      <div className="flex flex-col md:flex-row md:items-end justify-between gap-4">
        <div>
          <h1 className="text-3xl font-black tracking-tight">Consultations</h1>
          <p className="text-slate-500 font-medium">
            Every consultation across all doctors, with its payment, calls,
            review and prescription.
          </p>
        </div>
        <select
          aria-label="Period"
          className={selectClass}
          value={period}
          onChange={(e) => setPeriod(e.target.value as OverviewPeriod)}
        >
          {PERIODS.map((p) => (
            <option key={p.value} value={p.value}>
              {p.label}
            </option>
          ))}
        </select>
      </div>
      <Tabs defaultValue="consultations">
        <TabsList>
          <TabsTrigger value="consultations">Consultations</TabsTrigger>
          <TabsTrigger value="calls">Call logs</TabsTrigger>
        </TabsList>
        <TabsContent value="consultations" className="mt-4">
          <ConsultationsTab period={period} />
        </TabsContent>
        <TabsContent value="calls" className="mt-4">
          <CallLogsTab period={period} />
        </TabsContent>
      </Tabs>
    </div>
  );
}
