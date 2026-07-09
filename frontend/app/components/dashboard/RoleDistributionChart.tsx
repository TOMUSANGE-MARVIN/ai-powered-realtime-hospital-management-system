import { useQueries } from "@tanstack/react-query";
import { Bar, BarChart, CartesianGrid, Cell, XAxis, YAxis, LabelList } from "recharts";
import { getUsers } from "@/lib/api";
import { Loader2 } from "lucide-react";
import {
  ChartContainer,
  ChartTooltip,
  ChartTooltipContent,
  type ChartConfig,
} from "@/components/ui/chart";
import type { Role } from "@/types";

const ROLES: { role: Role; label: string; color: string }[] = [
  { role: "admin", label: "Admins", color: "var(--chart-4)" },
  { role: "doctor", label: "Doctors", color: "var(--chart-1)" },
  { role: "nurse", label: "Nurses", color: "var(--chart-2)" },
  { role: "patient", label: "Patients", color: "var(--chart-3)" },
];

const chartConfig = {
  count: { label: "Users" },
} satisfies ChartConfig;

export function RoleDistributionChart() {
  const results = useQueries({
    queries: ROLES.map(({ role }) => ({
      queryKey: ["users", role, "count"],
      queryFn: () => getUsers({ role, limit: 1 }),
    })),
  });

  const isLoading = results.some((r) => r.isLoading);
  const isError = results.some((r) => r.isError);

  if (isLoading)
    return (
      <div className="flex h-64 items-center justify-center">
        <Loader2 className="animate-spin" />
      </div>
    );
  if (isError)
    return (
      <div className="flex h-64 items-center justify-center text-destructive">
        Error loading chart
      </div>
    );

  const chartData = ROLES.map(({ role, label, color }, i) => ({
    role: label,
    count: results[i].data?.pagination.totalData ?? 0,
    fill: color,
  }));

  return (
    <ChartContainer config={chartConfig} className="aspect-auto h-64 w-full">
      <BarChart
        data={chartData}
        layout="vertical"
        margin={{ top: 10, right: 24, left: 10, bottom: 0 }}
      >
        <CartesianGrid horizontal={false} strokeDasharray="3 3" />
        <XAxis type="number" hide />
        <YAxis
          type="category"
          dataKey="role"
          fontSize={12}
          tickLine={false}
          axisLine={false}
          width={70}
        />
        <ChartTooltip content={<ChartTooltipContent hideLabel />} />
        <Bar dataKey="count" radius={6} barSize={14}>
          {chartData.map((entry) => (
            <Cell key={entry.role} fill={entry.fill} />
          ))}
          <LabelList
            dataKey="count"
            position="right"
            className="fill-foreground"
            fontSize={12}
            fontWeight={600}
          />
        </Bar>
      </BarChart>
    </ChartContainer>
  );
}
