import { useMemo } from "react";
import { useQuery } from "@tanstack/react-query";
import {
  Label,
  PolarAngleAxis,
  PolarGrid,
  PolarRadiusAxis,
  RadialBar,
  RadialBarChart,
} from "recharts";
import { getAllInvoices, getUsers } from "@/lib/api";
import { Loader2 } from "lucide-react";
import { ChartContainer, type ChartConfig } from "@/components/ui/chart";

function Gauge({
  value,
  label,
  sublabel,
  color,
}: {
  value: number;
  label: string;
  sublabel: string;
  color: string;
}) {
  const clamped = Math.min(Math.max(value, 0), 100);
  const data = [{ metric: label, value: clamped, fill: color }];
  const config = { value: { label } } satisfies ChartConfig;

  return (
    <div className="flex flex-col items-center">
      <ChartContainer config={config} className="mx-auto aspect-square h-40">
        <RadialBarChart
          data={data}
          startAngle={90}
          endAngle={-270}
          innerRadius="72%"
          outerRadius="100%"
        >
          <PolarAngleAxis
            type="number"
            domain={[0, 100]}
            angleAxisId={0}
            tick={false}
          />
          <PolarGrid gridType="circle" radialLines={false} stroke="none" />
          <RadialBar dataKey="value" background cornerRadius={10} />
          <PolarRadiusAxis tick={false} tickLine={false} axisLine={false}>
            <Label
              content={({ viewBox }) => {
                if (!viewBox || !("cx" in viewBox)) return null;
                return (
                  <text
                    x={viewBox.cx}
                    y={viewBox.cy}
                    textAnchor="middle"
                    dominantBaseline="middle"
                  >
                    <tspan
                      x={viewBox.cx}
                      y={viewBox.cy}
                      className="fill-foreground text-2xl font-bold"
                    >
                      {Math.round(value)}%
                    </tspan>
                  </text>
                );
              }}
            />
          </PolarRadiusAxis>
        </RadialBarChart>
      </ChartContainer>
      <p className="text-sm font-semibold">{label}</p>
      <p className="text-xs text-muted-foreground">{sublabel}</p>
    </div>
  );
}

export function MetricGauges() {
  const { data: patientData, isLoading: patientsLoading } = useQuery({
    queryKey: ["patients"],
    queryFn: () => getUsers({ role: "patient", limit: 100 }),
  });

  const { data: invoiceData, isLoading: invoicesLoading } = useQuery({
    queryKey: ["all-invoices"],
    queryFn: () => getAllInvoices(),
  });

  const { dischargeRate, collectionRate } = useMemo(() => {
    const patients = patientData?.res || [];
    const totalPatients = patients.length;
    const discharged = patients.filter(
      (p) => p.status?.toLowerCase() === "discharged",
    ).length;

    const invoices = invoiceData?.res || [];
    const totalBilled = invoices.reduce(
      (sum, inv) => sum + (Number(inv.totalAmount) || 0),
      0,
    );
    const totalPaid = invoices
      .filter((inv) => inv.status === "paid")
      .reduce((sum, inv) => sum + (Number(inv.totalAmount) || 0), 0);

    return {
      dischargeRate: totalPatients > 0 ? (discharged / totalPatients) * 100 : 0,
      collectionRate: totalBilled > 0 ? (totalPaid / totalBilled) * 100 : 0,
    };
  }, [patientData, invoiceData]);

  if (patientsLoading || invoicesLoading)
    return (
      <div className="flex h-40 items-center justify-center">
        <Loader2 className="animate-spin" />
      </div>
    );

  return (
    <div className="grid grid-cols-2 gap-4">
      <Gauge
        value={collectionRate}
        label="Collection Rate"
        sublabel="Paid vs. billed"
        color="var(--chart-2)"
      />
      <Gauge
        value={dischargeRate}
        label="Discharge Rate"
        sublabel="Patients discharged"
        color="var(--chart-1)"
      />
    </div>
  );
}
