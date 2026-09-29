import { useState } from "react";
import { useNavigate } from "react-router";
import { useMutation, useQuery } from "@tanstack/react-query";
import { useForm } from "react-hook-form";
import { toast } from "sonner";
import {
  Area,
  AreaChart,
  CartesianGrid,
  Cell,
  Pie,
  PieChart,
  XAxis,
  YAxis,
} from "recharts";
import {
  Activity,
  ArrowDownRight,
  ArrowUpRight,
  Bell,
  CalendarDays,
  Database,
  Download,
  FileText,
  Globe,
  Server,
  Star,
  Stethoscope,
  TrendingUp,
  Users,
  Wallet,
} from "lucide-react";
import { getAdminOverview, sendAnnouncement } from "@/lib/api";
import type { AdminOverview, Kpi, OverviewPeriod } from "@/types";
import {
  ChartContainer,
  ChartTooltip,
  ChartTooltipContent,
  type ChartConfig,
} from "@/components/ui/chart";
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar";
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
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import { CustomInput } from "@/components/global/CustomInput";
import { CustomSelect } from "@/components/global/CustomSelect";
import Loader from "@/components/global/Loader";
import CreateUserModal from "@/components/users/CreateUserModal";
import { RecentActivity } from "@/components/dashboard/RecentActivity";

const PERIODS: { value: OverviewPeriod; label: string }[] = [
  { value: "today", label: "Today" },
  { value: "week", label: "This Week" },
  { value: "month", label: "This Month" },
  { value: "year", label: "This Year" },
];

const SPECIALTY_COLORS = [
  "var(--chart-1)",
  "var(--chart-2)",
  "var(--chart-3)",
  "var(--chart-4)",
  "var(--chart-5)",
];

const revenueConfig = {
  revenue: { label: "Revenue (UGX)", color: "var(--chart-1)" },
} satisfies ChartConfig;

const ugx = (n: number) => `UGX ${n.toLocaleString()}`;
const compactUgx = (n: number) =>
  n >= 1_000_000
    ? `${(n / 1_000_000).toFixed(n >= 10_000_000 ? 0 : 1)}M`
    : n >= 1000
      ? `${Math.round(n / 1000)}K`
      : String(n);

const initials = (name: string) =>
  name
    .replace(/^dr\.?\s*/i, "")
    .split(/\s+/)
    .map((p) => p[0])
    .join("")
    .slice(0, 2)
    .toUpperCase();

function toCsv(overview: AdminOverview) {
  const k = overview.kpis;
  const rows: (string | number)[][] = [
    ["Section", "Metric", "Value"],
    ["KPIs", "Total patients", k.totalPatients.value],
    ["KPIs", "Total doctors", k.totalDoctors.value],
    ["KPIs", "Active consultations", k.activeConsultations.value],
    ["KPIs", "Appointments today", k.appointmentsToday.value],
    ["KPIs", "Revenue this month (UGX)", k.monthlyRevenue.value],
    ["KPIs", "Sign-ups this quarter", k.platformGrowth.signupsThisQuarter],
    ...overview.revenue.series.map((b) => [
      `Revenue (${overview.revenue.period})`,
      b.label,
      b.revenue,
    ]),
    ...overview.specialties.map((s) => ["Consultations by specialty", s.name, s.count]),
    ...overview.doctorPerformance.map((d) => [
      "Doctor rating",
      d.name,
      `${d.rating} (${d.reviews} reviews)`,
    ]),
  ];
  return rows
    .map((r) => r.map((c) => `"${String(c).replace(/"/g, '""')}"`).join(","))
    .join("\n");
}

function download(filename: string, text: string) {
  const url = URL.createObjectURL(new Blob([text], { type: "text/csv" }));
  const a = document.createElement("a");
  a.href = url;
  a.download = filename;
  a.click();
  URL.revokeObjectURL(url);
}

function Change({ kpi }: { kpi: Kpi }) {
  if (kpi.change === null) {
    return <span className="text-xs text-muted-foreground">No change data yet</span>;
  }
  const up = kpi.change >= 0;
  return (
    <span className="text-xs text-muted-foreground flex items-center gap-1">
      <span
        className={`flex items-center font-semibold ${up ? "text-emerald-600" : "text-destructive"}`}
      >
        {up ? <ArrowUpRight size={14} /> : <ArrowDownRight size={14} />}
        {Math.abs(kpi.change)}%
      </span>
      from last month
    </span>
  );
}

function KpiCard({
  title,
  value,
  kpi,
  icon,
}: {
  title: string;
  value: string;
  kpi: Kpi;
  icon: React.ReactNode;
}) {
  return (
    <div className="card rounded-xl p-5 shadow-sm space-y-2">
      <div className="flex items-center justify-between text-muted-foreground">
        <span className="text-sm font-medium">{title}</span>
        {icon}
      </div>
      <div className="text-3xl font-black tracking-tight">{value}</div>
      <Change kpi={kpi} />
    </div>
  );
}

function AnnouncementDialog() {
  const [open, setOpen] = useState(false);
  const form = useForm({
    defaultValues: { audience: "all", title: "", message: "" },
  });
  const mutation = useMutation({
    mutationFn: sendAnnouncement,
    onSuccess: ({ sent }) => {
      toast.success(`Announcement sent to ${sent} user${sent === 1 ? "" : "s"}`);
      setOpen(false);
      form.reset();
    },
    onError: (e: any) => toast.error(e.message || "Failed to send"),
  });
  return (
    <Dialog open={open} onOpenChange={setOpen}>
      <DialogTrigger asChild>
        <Button variant="outline" className="w-full gap-2">
          <Bell size={16} /> Send Announcement
        </Button>
      </DialogTrigger>
      <DialogContent className="sm:max-w-lg card">
        <DialogHeader>
          <DialogTitle>Send Announcement</DialogTitle>
        </DialogHeader>
        <form
          className="space-y-3"
          onSubmit={form.handleSubmit((data) =>
            mutation.mutate(data as Parameters<typeof sendAnnouncement>[0]),
          )}
        >
          <CustomSelect
            control={form.control}
            name="audience"
            label="Send to"
            options={[
              { label: "Everyone", value: "all" },
              { label: "Patients", value: "patients" },
              { label: "Doctors", value: "doctors" },
            ]}
          />
          <CustomInput control={form.control} name="title" label="Title" />
          <CustomInput control={form.control} name="message" label="Message" />
          <Button type="submit" className="w-full" disabled={mutation.isPending}>
            Send
          </Button>
        </form>
      </DialogContent>
    </Dialog>
  );
}

function HealthRow({
  icon,
  label,
  value,
  percent,
}: {
  icon: React.ReactNode;
  label: string;
  value: string;
  percent: number;
}) {
  return (
    <div className="space-y-2">
      <div className="flex items-center justify-between text-sm">
        <span className="flex items-center gap-2">
          {icon}
          {label}
        </span>
        <span className="font-semibold">{value}</span>
      </div>
      <div className="h-1.5 rounded-full bg-muted overflow-hidden">
        <div
          className="h-full bg-primary"
          style={{ width: `${Math.min(100, Math.max(2, percent))}%` }}
        />
      </div>
    </div>
  );
}

const PRIORITY_BADGE: Record<string, string> = {
  low: "bg-muted text-muted-foreground",
  medium: "bg-amber-100 text-amber-700",
  high: "bg-red-100 text-red-700",
};

export default function PlatformOverview() {
  const navigate = useNavigate();
  const [period, setPeriod] = useState<OverviewPeriod>("month");
  const { data, isLoading, isError, refetch } = useQuery({
    queryKey: ["admin-overview", period],
    queryFn: () => getAdminOverview(period),
    placeholderData: (previous) => previous,
  });

  if (isLoading) {
    return (
      <div className="w-full h-[70vh] flex items-center justify-center">
        <Loader label="Loading platform overview..." />
      </div>
    );
  }
  if (isError || !data) {
    return (
      <div className="p-10 text-center space-y-3">
        <p className="text-destructive">Failed to load the overview.</p>
        <Button variant="outline" onClick={() => refetch()}>
          Try again
        </Button>
      </div>
    );
  }

  const k = data.kpis;
  const periodLabel = PERIODS.find((p) => p.value === period)!.label;
  const specialtyConfig = Object.fromEntries(
    data.specialties.map((s, i) => [
      s.name,
      { label: s.name, color: SPECIALTY_COLORS[i % SPECIALTY_COLORS.length] },
    ]),
  ) satisfies ChartConfig;

  return (
    <div className="grid grid-cols-1 xl:grid-cols-[1fr_280px] gap-8">
      <div className="space-y-6 min-w-0">
        <div className="flex flex-col md:flex-row md:items-end justify-between gap-4">
          <div>
            <h1 className="text-3xl font-black tracking-tight">Platform Overview</h1>
            <p className="text-slate-500 font-medium">
              Monitor key metrics, performance, and system health.
            </p>
          </div>
          <div className="flex gap-2">
            <Button
              variant="outline"
              className="gap-2"
              onClick={() =>
                download(`ask-musawo-overview-${period}.csv`, toCsv(data))
              }
            >
              <Download size={16} /> Export Data
            </Button>
            <select
              aria-label="Filter dashboard by period"
              className="h-9 rounded-md border bg-primary text-primary-foreground px-3 text-sm font-medium"
              value={period}
              onChange={(e) => setPeriod(e.target.value as OverviewPeriod)}
            >
              {PERIODS.map((p) => (
                <option key={p.value} value={p.value} className="text-foreground bg-background">
                  {p.label}
                </option>
              ))}
            </select>
          </div>
        </div>

        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
          <KpiCard
            title="Total Patients"
            value={k.totalPatients.value.toLocaleString()}
            kpi={k.totalPatients}
            icon={<Users size={18} />}
          />
          <KpiCard
            title="Total Doctors"
            value={k.totalDoctors.value.toLocaleString()}
            kpi={k.totalDoctors}
            icon={<Stethoscope size={18} />}
          />
          <KpiCard
            title="Active Consultations"
            value={k.activeConsultations.value.toLocaleString()}
            kpi={k.activeConsultations}
            icon={<Activity size={18} />}
          />
          <KpiCard
            title="Appointments Today"
            value={k.appointmentsToday.value.toLocaleString()}
            kpi={k.appointmentsToday}
            icon={<CalendarDays size={18} />}
          />
          <KpiCard
            title="Monthly Revenue"
            value={ugx(k.monthlyRevenue.value)}
            kpi={k.monthlyRevenue}
            icon={<Wallet size={18} />}
          />
          <div className="rounded-xl p-5 border border-primary/30 bg-primary/5 space-y-2">
            <div className="flex items-center justify-between text-primary">
              <span className="text-sm font-semibold">Platform Growth</span>
              <TrendingUp size={18} />
            </div>
            <div className="text-3xl font-black tracking-tight text-primary">
              {k.platformGrowth.value === null
                ? "—"
                : `${k.platformGrowth.value >= 0 ? "+" : ""}${k.platformGrowth.value}%`}
            </div>
            <span className="text-xs text-primary">
              {k.platformGrowth.value === null
                ? `${k.platformGrowth.signupsThisQuarter.toLocaleString()} sign-ups this quarter · none last quarter to compare`
                : `Sign-ups this quarter vs last (${k.platformGrowth.signupsThisQuarter.toLocaleString()} so far)`}
            </span>
          </div>
        </div>

        <div className="grid grid-cols-1 lg:grid-cols-5 gap-6">
          <section className="card rounded-xl p-6 shadow-sm lg:col-span-3">
            <div className="flex flex-wrap items-start justify-between gap-3 mb-4">
              <div>
                <h3 className="text-lg font-bold">Revenue Analytics</h3>
                <p className="text-sm text-muted-foreground">
                  Paid consultations, {periodLabel.toLowerCase()} (UGX)
                </p>
              </div>
              <div className="flex rounded-lg bg-muted p-1 text-sm">
                {PERIODS.map((p) => (
                  <button
                    key={p.value}
                    onClick={() => setPeriod(p.value)}
                    className={`px-3 py-1 rounded-md ${period === p.value ? "bg-background shadow-sm font-semibold" : "text-muted-foreground"}`}
                  >
                    {p.label}
                  </button>
                ))}
              </div>
            </div>
            <ChartContainer config={revenueConfig} className="aspect-auto h-72 w-full">
              <AreaChart
                data={data.revenue.series}
                margin={{ top: 10, right: 10, left: 0, bottom: 0 }}
              >
                <defs>
                  <linearGradient id="fillRevenue" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="5%" stopColor="var(--color-revenue)" stopOpacity={0.35} />
                    <stop offset="95%" stopColor="var(--color-revenue)" stopOpacity={0.02} />
                  </linearGradient>
                </defs>
                <CartesianGrid strokeDasharray="3 3" vertical={false} />
                <XAxis dataKey="label" fontSize={12} tickLine={false} axisLine={false} />
                <YAxis
                  fontSize={12}
                  tickLine={false}
                  axisLine={false}
                  width={48}
                  tickFormatter={compactUgx}
                />
                <ChartTooltip
                  content={
                    <ChartTooltipContent
                      indicator="dot"
                      formatter={(value) => [ugx(Number(value)), " Revenue"]}
                    />
                  }
                />
                <Area
                  type="monotone"
                  dataKey="revenue"
                  stroke="var(--color-revenue)"
                  fill="url(#fillRevenue)"
                  strokeWidth={2.5}
                />
              </AreaChart>
            </ChartContainer>
          </section>

          <section className="card rounded-xl p-6 shadow-sm lg:col-span-2">
            <h3 className="text-lg font-bold">Consultations by Specialty</h3>
            <p className="text-sm text-muted-foreground mb-4">
              Appointments booked, {periodLabel.toLowerCase()}
            </p>
            {data.specialties.length === 0 ? (
              <div className="h-56 flex items-center justify-center text-sm text-muted-foreground">
                No appointments in this period.
              </div>
            ) : (
              <>
                <ChartContainer config={specialtyConfig} className="aspect-square h-52 mx-auto">
                  <PieChart>
                    <ChartTooltip content={<ChartTooltipContent nameKey="name" hideLabel />} />
                    <Pie
                      data={data.specialties}
                      dataKey="count"
                      nameKey="name"
                      innerRadius={55}
                      strokeWidth={2}
                    >
                      {data.specialties.map((s, i) => (
                        <Cell
                          key={s.name}
                          fill={SPECIALTY_COLORS[i % SPECIALTY_COLORS.length]}
                        />
                      ))}
                    </Pie>
                  </PieChart>
                </ChartContainer>
                <ul className="mt-4 space-y-1.5 text-sm">
                  {data.specialties.slice(0, 6).map((s, i) => (
                    <li key={s.name} className="flex items-center justify-between">
                      <span className="flex items-center gap-2">
                        <span
                          className="size-2.5 rounded-full"
                          style={{
                            background: SPECIALTY_COLORS[i % SPECIALTY_COLORS.length],
                          }}
                        />
                        {s.name}
                      </span>
                      <span className="font-semibold">{s.count}</span>
                    </li>
                  ))}
                </ul>
              </>
            )}
          </section>
        </div>

        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
          <section className="card rounded-xl p-6 shadow-sm">
            <h3 className="text-lg font-bold mb-4">Doctor Performance</h3>
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>Doctor</TableHead>
                  <TableHead>Rating</TableHead>
                  <TableHead>Status</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {data.doctorPerformance.length === 0 ? (
                  <TableRow>
                    <TableCell colSpan={3} className="text-center h-20 text-muted-foreground">
                      No reviews yet.
                    </TableCell>
                  </TableRow>
                ) : (
                  data.doctorPerformance.map((d) => (
                    <TableRow key={d.id}>
                      <TableCell>
                        <div className="flex items-center gap-3">
                          <Avatar className="size-9">
                            <AvatarImage src={d.image ?? undefined} />
                            <AvatarFallback>{initials(d.name)}</AvatarFallback>
                          </Avatar>
                          <div>
                            <div className="font-semibold">{d.name}</div>
                            <div className="text-xs text-muted-foreground">
                              {d.specialization || "General Practice"}
                            </div>
                          </div>
                        </div>
                      </TableCell>
                      <TableCell>
                        <span className="flex items-center gap-1 font-semibold">
                          <Star size={14} className="fill-amber-400 text-amber-400" />
                          {d.rating}
                          <span className="text-xs text-muted-foreground font-normal">
                            ({d.reviews})
                          </span>
                        </span>
                      </TableCell>
                      <TableCell>
                        {d.status === "suspended" ? (
                          <Badge variant="destructive">Suspended</Badge>
                        ) : (
                          <Badge className="bg-emerald-100 text-emerald-700">Active</Badge>
                        )}
                      </TableCell>
                    </TableRow>
                  ))
                )}
              </TableBody>
            </Table>
          </section>

          <section className="card rounded-xl p-6 shadow-sm">
            <h3 className="text-lg font-bold">Incomplete Doctor Profiles</h3>
            <p className="text-sm text-muted-foreground mb-4">
              Fee, qualifications, hospital and availability filled in
            </p>
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>Doctor</TableHead>
                  <TableHead>Joined</TableHead>
                  <TableHead>Profile</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {data.incompleteProfiles.length === 0 ? (
                  <TableRow>
                    <TableCell colSpan={3} className="text-center h-20 text-muted-foreground">
                      Every doctor profile is complete.
                    </TableCell>
                  </TableRow>
                ) : (
                  data.incompleteProfiles.map((d) => (
                    <TableRow
                      key={d.id}
                      className="cursor-pointer"
                      onClick={() => navigate(`/profile/${d.id}`)}
                    >
                      <TableCell>
                        <div className="flex items-center gap-3">
                          <Avatar className="size-9">
                            <AvatarImage src={d.image ?? undefined} />
                            <AvatarFallback>{initials(d.name)}</AvatarFallback>
                          </Avatar>
                          <div>
                            <div className="font-semibold">{d.name}</div>
                            <div className="text-xs text-muted-foreground">
                              {d.specialization || "No specialty"}
                            </div>
                          </div>
                        </div>
                      </TableCell>
                      <TableCell>{new Date(d.joinedAt).toLocaleDateString()}</TableCell>
                      <TableCell className="font-semibold">
                        {d.completed}/{d.total}
                      </TableCell>
                    </TableRow>
                  ))
                )}
              </TableBody>
            </Table>
          </section>
        </div>

        <div className="grid grid-cols-1 lg:grid-cols-5 gap-6">
          <section className="card rounded-xl p-6 shadow-sm lg:col-span-3">
            <div className="flex items-center justify-between mb-4">
              <h3 className="text-lg font-bold">
                Recent Support Tickets
                <span className="ml-2 text-sm font-medium text-muted-foreground">
                  {data.supportTickets.open} open
                </span>
              </h3>
              <Button variant="ghost" size="sm" onClick={() => navigate("/support")}>
                View All
              </Button>
            </div>
            {data.supportTickets.recent.length === 0 ? (
              <p className="text-sm text-muted-foreground">No tickets yet.</p>
            ) : (
              <ul className="divide-y">
                {data.supportTickets.recent.map((t) => (
                  <li key={t.id} className="py-3 flex items-start justify-between gap-4">
                    <div className="space-y-1">
                      <div className="flex items-center gap-2 text-xs">
                        <span className="text-muted-foreground">
                          #{t.id.slice(-5).toUpperCase()}
                        </span>
                        <Badge className={`capitalize ${PRIORITY_BADGE[t.priority]}`}>
                          {t.priority}
                        </Badge>
                      </div>
                      <div className="font-semibold">{t.subject}</div>
                      <div className="text-xs text-muted-foreground">{t.userName}</div>
                    </div>
                    <Badge variant="outline" className="capitalize shrink-0">
                      {t.status.replace("_", " ")}
                    </Badge>
                  </li>
                ))}
              </ul>
            )}
          </section>

          <section className="card rounded-xl p-6 shadow-sm lg:col-span-2 space-y-5">
            <h3 className="text-lg font-bold">System Health</h3>
            <HealthRow
              icon={<Server size={16} />}
              label="Server Load"
              value={`${data.systemHealth.serverLoadPercent}%`}
              percent={data.systemHealth.serverLoadPercent}
            />
            <HealthRow
              icon={<Database size={16} />}
              label="Database"
              value={`${data.systemHealth.database === "healthy" ? "Healthy" : data.systemHealth.database} · ${data.systemHealth.databaseLatencyMs}ms`}
              percent={100}
            />
            <HealthRow
              icon={<Globe size={16} />}
              label="API Response"
              value={`${data.systemHealth.apiLatencyMs}ms`}
              percent={Math.min(100, data.systemHealth.apiLatencyMs / 10)}
            />
          </section>
        </div>
      </div>

      <aside className="space-y-8">
        <section className="space-y-3">
          <h3 className="text-sm font-bold uppercase tracking-wide text-muted-foreground">
            Quick Actions
          </h3>
          <CreateUserModal role="doctor" triggerClassName="w-full gap-2" />
          <CreateUserModal
            role="admin"
            triggerVariant="outline"
            triggerClassName="w-full gap-2"
          />
          <AnnouncementDialog />
          <Button
            variant="outline"
            className="w-full gap-2"
            onClick={() => {
              download(`ask-musawo-report-${period}.csv`, toCsv(data));
              toast.success("Report downloaded");
            }}
          >
            <FileText size={16} /> Generate Report
          </Button>
          <Button
            variant="outline"
            className="w-full gap-2"
            onClick={() => navigate("/settings/payouts")}
          >
            <Wallet size={16} /> Process Withdrawal
          </Button>
        </section>
        <section className="space-y-3">
          <h3 className="text-sm font-bold uppercase tracking-wide text-muted-foreground">
            Recent Activity
          </h3>
          <RecentActivity />
        </section>
      </aside>
    </div>
  );
}
