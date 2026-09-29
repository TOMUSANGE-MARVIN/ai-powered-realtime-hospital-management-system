import { useState } from "react";
import { useQuery } from "@tanstack/react-query";
import {
  Bar,
  BarChart,
  CartesianGrid,
  Line,
  LineChart,
  XAxis,
  YAxis,
} from "recharts";
import { Download } from "lucide-react";
import { getReports } from "@/lib/api";
import type { ReportsResponse } from "@/types";
import { Button } from "@/components/ui/button";
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
import {
  ChartContainer,
  ChartLegend,
  ChartLegendContent,
  ChartTooltip,
  ChartTooltipContent,
  type ChartConfig,
} from "@/components/ui/chart";
import { Input } from "@/components/ui/input";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import Loader from "@/components/global/Loader";

export function meta() {
  return [{ title: "Reports & Analytics | Ask Musawo" }];
}

const iso = (d: Date) => d.toISOString().slice(0, 10);
const daysAgo = (n: number) => iso(new Date(Date.now() - n * 86400_000));
const ugx = (n: number) => `UGX ${n.toLocaleString()}`;
const compact = (n: number) =>
  n >= 1_000_000 ? `${(n / 1_000_000).toFixed(1)}M` : n >= 1000 ? `${Math.round(n / 1000)}K` : String(n);

const PRESETS = [
  { label: "7 days", days: 6 },
  { label: "30 days", days: 29 },
  { label: "90 days", days: 89 },
  { label: "12 months", days: 364 },
];

const consultationConfig = {
  completed: { label: "Completed", color: "var(--chart-2)" },
  other: { label: "Upcoming / in progress", color: "var(--chart-1)" },
  cancelled: { label: "Cancelled", color: "var(--chart-5)" },
} satisfies ChartConfig;

const revenueConfig = {
  revenue: { label: "Revenue", color: "var(--chart-1)" },
  discounts: { label: "Discounts", color: "var(--chart-3)" },
  tax: { label: "Tax", color: "var(--chart-4)" },
} satisfies ChartConfig;

const signupConfig = {
  patients: { label: "Patients", color: "var(--chart-1)" },
  doctors: { label: "Doctors", color: "var(--chart-2)" },
} satisfies ChartConfig;

function toCsv(rows: (string | number | null)[][]) {
  return rows
    .map((r) => r.map((c) => `"${String(c ?? "").replace(/"/g, '""')}"`).join(","))
    .join("\n");
}

function download(name: string, rows: (string | number | null)[][]) {
  const url = URL.createObjectURL(new Blob([toCsv(rows)], { type: "text/csv" }));
  const a = document.createElement("a");
  a.href = url;
  a.download = name;
  a.click();
  URL.revokeObjectURL(url);
}

function periodLabel(period: string, granularity: string) {
  const d = new Date(`${period}T00:00:00Z`);
  if (granularity === "month") {
    return d.toLocaleDateString("en-GB", { month: "short", year: "2-digit", timeZone: "UTC" });
  }
  return d.toLocaleDateString("en-GB", { day: "numeric", month: "short", timeZone: "UTC" });
}

function ExportButton({ onClick }: { onClick: () => void }) {
  return (
    <Button variant="ghost" size="sm" className="gap-1" onClick={onClick}>
      <Download size={14} /> CSV
    </Button>
  );
}

function Total({ label, value, hint }: { label: string; value: string; hint?: string }) {
  return (
    <div className="card rounded-xl p-4 shadow-sm space-y-1">
      <div className="text-sm text-muted-foreground">{label}</div>
      <div className="text-2xl font-black tracking-tight">{value}</div>
      {hint && <div className="text-xs text-muted-foreground">{hint}</div>}
    </div>
  );
}

function Reports({ data }: { data: ReportsResponse }) {
  const { range, totals: t } = data;
  const label = (p: string) => periodLabel(p, range.granularity);
  const file = (name: string) => `ask-musawo-${name}-${range.from}-to-${range.to}.csv`;

  return (
    <div className="space-y-6">
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
        <Total
          label="Consultations"
          value={t.consultations.toLocaleString()}
          hint={`${t.completed} completed · ${t.cancellationRate ?? "—"}${t.cancellationRate === null ? "" : "%"} cancelled`}
        />
        <Total
          label="Revenue"
          value={ugx(t.revenue)}
          hint={`${ugx(t.discounts)} discounts · ${ugx(t.tax)} tax`}
        />
        <Total
          label="New sign-ups"
          value={(t.newPatients + t.newDoctors).toLocaleString()}
          hint={`${t.newPatients} patients · ${t.newDoctors} doctors`}
        />
        <Total
          label="Average rating"
          value={t.averageRating === null ? "—" : `${t.averageRating} / 5`}
          hint="Visible reviews in this range"
        />
      </div>

      <div className="grid grid-cols-1 xl:grid-cols-2 gap-6">
        <Card className="card shadow-sm">
          <CardHeader className="flex flex-row items-start justify-between">
            <div>
              <CardTitle>Consultations</CardTitle>
              <CardDescription>By visit date, per {range.granularity}</CardDescription>
            </div>
            <ExportButton
              onClick={() =>
                download(file("consultations"), [
                  ["Period", "Completed", "Cancelled", "Upcoming / in progress"],
                  ...data.consultations.map((r) => [r.period, r.completed, r.cancelled, r.other]),
                ])
              }
            />
          </CardHeader>
          <CardContent>
            <ChartContainer config={consultationConfig} className="aspect-auto h-64 w-full">
              <BarChart data={data.consultations}>
                <CartesianGrid vertical={false} strokeDasharray="3 3" />
                <XAxis dataKey="period" tickFormatter={label} fontSize={11} tickLine={false} axisLine={false} minTickGap={12} />
                <YAxis allowDecimals={false} fontSize={11} tickLine={false} axisLine={false} width={28} />
                <ChartTooltip content={<ChartTooltipContent labelFormatter={(v) => label(String(v))} />} />
                <ChartLegend content={<ChartLegendContent />} />
                <Bar dataKey="completed" stackId="a" fill="var(--color-completed)" isAnimationActive={false} />
                <Bar dataKey="other" stackId="a" fill="var(--color-other)" isAnimationActive={false} />
                <Bar dataKey="cancelled" stackId="a" fill="var(--color-cancelled)" radius={[3, 3, 0, 0]} isAnimationActive={false} />
              </BarChart>
            </ChartContainer>
          </CardContent>
        </Card>

        <Card className="card shadow-sm">
          <CardHeader className="flex flex-row items-start justify-between">
            <div>
              <CardTitle>Revenue</CardTitle>
              <CardDescription>Paid consultations (UGX), per {range.granularity}</CardDescription>
            </div>
            <ExportButton
              onClick={() =>
                download(file("revenue"), [
                  ["Period", "Revenue (UGX)", "Discounts (UGX)", "Tax (UGX)"],
                  ...data.revenue.map((r) => [r.period, r.revenue, r.discounts, r.tax]),
                ])
              }
            />
          </CardHeader>
          <CardContent>
            <ChartContainer config={revenueConfig} className="aspect-auto h-64 w-full">
              <LineChart data={data.revenue}>
                <CartesianGrid vertical={false} strokeDasharray="3 3" />
                <XAxis dataKey="period" tickFormatter={label} fontSize={11} tickLine={false} axisLine={false} minTickGap={12} />
                <YAxis tickFormatter={compact} fontSize={11} tickLine={false} axisLine={false} width={40} />
                <ChartTooltip
                  content={
                    <ChartTooltipContent
                      labelFormatter={(v) => label(String(v))}
                      formatter={(value, name) => [
                        ugx(Number(value)),
                        ` ${revenueConfig[name as keyof typeof revenueConfig]?.label ?? name}`,
                      ]}
                    />
                  }
                />
                <ChartLegend content={<ChartLegendContent />} />
                <Line dataKey="revenue" stroke="var(--color-revenue)" strokeWidth={2.5} dot={false} isAnimationActive={false} />
                <Line dataKey="discounts" stroke="var(--color-discounts)" strokeWidth={1.5} dot={false} isAnimationActive={false} />
                <Line dataKey="tax" stroke="var(--color-tax)" strokeWidth={1.5} dot={false} isAnimationActive={false} />
              </LineChart>
            </ChartContainer>
          </CardContent>
        </Card>

        <Card className="card shadow-sm">
          <CardHeader className="flex flex-row items-start justify-between">
            <div>
              <CardTitle>New sign-ups</CardTitle>
              <CardDescription>Patients and doctors, per {range.granularity}</CardDescription>
            </div>
            <ExportButton
              onClick={() =>
                download(file("signups"), [
                  ["Period", "Patients", "Doctors"],
                  ...data.signups.map((r) => [r.period, r.patients, r.doctors]),
                ])
              }
            />
          </CardHeader>
          <CardContent>
            <ChartContainer config={signupConfig} className="aspect-auto h-64 w-full">
              <BarChart data={data.signups}>
                <CartesianGrid vertical={false} strokeDasharray="3 3" />
                <XAxis dataKey="period" tickFormatter={label} fontSize={11} tickLine={false} axisLine={false} minTickGap={12} />
                <YAxis allowDecimals={false} fontSize={11} tickLine={false} axisLine={false} width={28} />
                <ChartTooltip content={<ChartTooltipContent labelFormatter={(v) => label(String(v))} />} />
                <ChartLegend content={<ChartLegendContent />} />
                <Bar dataKey="patients" fill="var(--color-patients)" radius={[3, 3, 0, 0]} isAnimationActive={false} />
                <Bar dataKey="doctors" fill="var(--color-doctors)" radius={[3, 3, 0, 0]} isAnimationActive={false} />
              </BarChart>
            </ChartContainer>
          </CardContent>
        </Card>

        <Card className="card shadow-sm">
          <CardHeader className="flex flex-row items-start justify-between">
            <div>
              <CardTitle>By specialty</CardTitle>
              <CardDescription>Consultations and revenue</CardDescription>
            </div>
            <ExportButton
              onClick={() =>
                download(file("specialties"), [
                  ["Specialty", "Consultations", "Revenue (UGX)"],
                  ...data.specialties.map((s) => [s.name, s.consultations, s.revenue]),
                ])
              }
            />
          </CardHeader>
          <CardContent className="p-0">
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead className="pl-6">Specialty</TableHead>
                  <TableHead className="text-right">Consultations</TableHead>
                  <TableHead className="text-right pr-6">Revenue</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {data.specialties.length === 0 ? (
                  <TableRow>
                    <TableCell colSpan={3} className="text-center h-20 text-muted-foreground">
                      No consultations in this range.
                    </TableCell>
                  </TableRow>
                ) : (
                  data.specialties.map((s) => (
                    <TableRow key={s.name}>
                      <TableCell className="pl-6 font-medium">{s.name}</TableCell>
                      <TableCell className="text-right">{s.consultations}</TableCell>
                      <TableCell className="text-right pr-6">{ugx(s.revenue)}</TableCell>
                    </TableRow>
                  ))
                )}
              </TableBody>
            </Table>
          </CardContent>
        </Card>
      </div>

      <Card className="card shadow-sm">
        <CardHeader className="flex flex-row items-start justify-between">
          <div>
            <CardTitle>Doctor leaderboard</CardTitle>
            <CardDescription>Sorted by revenue in this range</CardDescription>
          </div>
          <ExportButton
            onClick={() =>
              download(file("doctors"), [
                ["Doctor", "Specialty", "Consultations", "Completed", "Revenue (UGX)", "Rating", "Reviews"],
                ...data.doctors.map((d) => [d.name, d.specialization, d.consultations, d.completed, d.revenue, d.rating, d.ratings]),
              ])
            }
          />
        </CardHeader>
        <CardContent className="p-0">
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead className="pl-6">Doctor</TableHead>
                <TableHead className="text-right">Consultations</TableHead>
                <TableHead className="text-right">Completed</TableHead>
                <TableHead className="text-right">Revenue</TableHead>
                <TableHead className="text-right pr-6">Rating</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {data.doctors.length === 0 ? (
                <TableRow>
                  <TableCell colSpan={5} className="text-center h-20 text-muted-foreground">
                    No doctor activity in this range.
                  </TableCell>
                </TableRow>
              ) : (
                data.doctors.map((d) => (
                  <TableRow key={d.id}>
                    <TableCell className="pl-6">
                      <div className="font-medium">{d.name}</div>
                      <div className="text-xs text-muted-foreground">{d.specialization}</div>
                    </TableCell>
                    <TableCell className="text-right">{d.consultations}</TableCell>
                    <TableCell className="text-right">{d.completed}</TableCell>
                    <TableCell className="text-right">{ugx(d.revenue)}</TableCell>
                    <TableCell className="text-right pr-6">
                      {d.rating === null ? "—" : `${d.rating} (${d.ratings})`}
                    </TableCell>
                  </TableRow>
                ))
              )}
            </TableBody>
          </Table>
        </CardContent>
      </Card>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <Card className="card shadow-sm">
          <CardHeader className="flex flex-row items-start justify-between">
            <div>
              <CardTitle>Voucher usage</CardTitle>
              <CardDescription>Paid bookings that used a code</CardDescription>
            </div>
            <ExportButton
              onClick={() =>
                download(file("vouchers"), [
                  ["Code", "Uses", "Discount given (UGX)"],
                  ...data.vouchers.map((v) => [v.code, v.uses, v.discount]),
                ])
              }
            />
          </CardHeader>
          <CardContent className="p-0">
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead className="pl-6">Code</TableHead>
                  <TableHead className="text-right">Uses</TableHead>
                  <TableHead className="text-right pr-6">Discount given</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {data.vouchers.length === 0 ? (
                  <TableRow>
                    <TableCell colSpan={3} className="text-center h-20 text-muted-foreground">
                      No vouchers used in this range.
                    </TableCell>
                  </TableRow>
                ) : (
                  data.vouchers.map((v) => (
                    <TableRow key={v.code}>
                      <TableCell className="pl-6 font-mono font-semibold">{v.code}</TableCell>
                      <TableCell className="text-right">{v.uses}</TableCell>
                      <TableCell className="text-right pr-6">{ugx(v.discount)}</TableCell>
                    </TableRow>
                  ))
                )}
              </TableBody>
            </Table>
          </CardContent>
        </Card>

        <Card className="card shadow-sm">
          <CardHeader className="flex flex-row items-start justify-between">
            <div>
              <CardTitle>Doctor payouts</CardTitle>
              <CardDescription>Withdrawals requested in this range, by status</CardDescription>
            </div>
            <ExportButton
              onClick={() =>
                download(file("payouts"), [
                  ["Status", "Amount (UGX)"],
                  ...Object.entries(data.payouts),
                ])
              }
            />
          </CardHeader>
          <CardContent className="grid grid-cols-2 gap-3">
            {(
              [
                ["Waiting for approval", data.payouts.requested],
                ["Approved, not yet paid", data.payouts.approved],
                ["Paid out", data.payouts.paid],
                ["Rejected", data.payouts.rejected],
              ] as const
            ).map(([name, amount]) => (
              <div key={name} className="rounded-lg border p-3">
                <div className="text-xs text-muted-foreground">{name}</div>
                <div className="font-bold">{ugx(amount)}</div>
              </div>
            ))}
          </CardContent>
        </Card>
      </div>
    </div>
  );
}

export default function ReportsPage() {
  const [from, setFrom] = useState(daysAgo(29));
  const [to, setTo] = useState(iso(new Date()));
  const [granularity, setGranularity] = useState("auto");

  const { data, isLoading, isError, error, isFetching } = useQuery({
    queryKey: ["reports", from, to, granularity],
    queryFn: () =>
      getReports({ from, to, granularity: granularity === "auto" ? undefined : granularity }),
    enabled: !!from && !!to && from <= to,
    placeholderData: (previous) => previous,
  });

  return (
    <div className="space-y-6">
      <div className="flex flex-col xl:flex-row xl:items-end justify-between gap-4">
        <div>
          <h1 className="text-3xl font-black tracking-tight">Reports & Analytics</h1>
          <p className="text-slate-500 font-medium">
            Consultations, revenue, growth and doctor performance for any date range.
          </p>
        </div>
        <div className="flex flex-wrap items-center gap-2">
          {PRESETS.map((p) => (
            <Button
              key={p.label}
              size="sm"
              variant={from === daysAgo(p.days) && to === iso(new Date()) ? "default" : "outline"}
              onClick={() => {
                setFrom(daysAgo(p.days));
                setTo(iso(new Date()));
              }}
            >
              {p.label}
            </Button>
          ))}
          <Input
            type="date"
            aria-label="From"
            className="w-38"
            value={from}
            max={to}
            onChange={(e) => setFrom(e.target.value)}
          />
          <span className="text-muted-foreground">to</span>
          <Input
            type="date"
            aria-label="To"
            className="w-38"
            value={to}
            min={from}
            max={iso(new Date())}
            onChange={(e) => setTo(e.target.value)}
          />
          <select
            aria-label="Group by"
            className="h-9 rounded-md border bg-background px-3 text-sm"
            value={granularity}
            onChange={(e) => setGranularity(e.target.value)}
          >
            <option value="auto">Auto</option>
            <option value="day">Daily</option>
            <option value="week">Weekly</option>
            <option value="month">Monthly</option>
          </select>
        </div>
      </div>

      {isLoading ? (
        <div className="flex justify-center py-24">
          <Loader label="Building reports..." />
        </div>
      ) : isError || !data ? (
        <div className="p-10 text-center text-red-500">
          {(error as Error)?.message || "Failed to load reports."}
        </div>
      ) : (
        <div className={isFetching ? "opacity-60 transition-opacity" : ""}>
          <Reports data={data} />
        </div>
      )}
    </div>
  );
}
