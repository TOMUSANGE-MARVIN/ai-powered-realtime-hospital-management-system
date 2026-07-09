import { useMemo } from "react";
import { Pie, PieChart, Cell } from "recharts";
import {
  ChartContainer,
  ChartTooltip,
  ChartTooltipContent,
  ChartLegend,
  ChartLegendContent,
  type ChartConfig,
} from "@/components/ui/chart";
import type { User } from "@/types";

const STATUS_META: Record<string, { label: string; color: string }> = {
  admitted: { label: "Admitted", color: "var(--chart-3)" },
  in_treatment: { label: "In Treatment", color: "var(--chart-1)" },
  observation: { label: "Observation", color: "var(--chart-4)" },
  discharged: { label: "Discharged", color: "var(--chart-2)" },
  follow_up: { label: "Follow Up", color: "var(--chart-5)" },
};

export function PatientStatusChart({ patients }: { patients: User[] }) {
  const { chartData, chartConfig, total } = useMemo(() => {
    const counts: Record<string, number> = {};
    patients.forEach((p) => {
      const key = p.status?.toLowerCase();
      if (key && STATUS_META[key]) {
        counts[key] = (counts[key] || 0) + 1;
      }
    });

    const config: ChartConfig = {};
    const data = Object.entries(STATUS_META)
      .filter(([key]) => counts[key] > 0)
      .map(([key, meta]) => {
        config[key] = { label: meta.label, color: meta.color };
        return { status: key, value: counts[key], fill: meta.color };
      });

    return {
      chartData: data,
      chartConfig: config,
      total: data.reduce((sum, d) => sum + d.value, 0),
    };
  }, [patients]);

  if (total === 0) {
    return (
      <div className="flex h-70 items-center justify-center text-sm text-muted-foreground">
        No patient data yet.
      </div>
    );
  }

  return (
    <ChartContainer
      config={chartConfig}
      className="mx-auto aspect-square h-70"
    >
      <PieChart>
        <ChartTooltip content={<ChartTooltipContent hideLabel />} />
        <Pie
          data={chartData}
          dataKey="value"
          nameKey="status"
          innerRadius={55}
          outerRadius={90}
          strokeWidth={4}
          paddingAngle={2}
        >
          {chartData.map((entry) => (
            <Cell key={entry.status} fill={entry.fill} />
          ))}
        </Pie>
        <ChartLegend
          content={<ChartLegendContent nameKey="status" />}
          className="flex-wrap gap-x-4 gap-y-1"
        />
      </PieChart>
    </ChartContainer>
  );
}
