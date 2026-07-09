import { useMemo } from "react";
import { useQuery } from "@tanstack/react-query";
import {
  Area,
  AreaChart,
  CartesianGrid,
  XAxis,
  YAxis,
} from "recharts";
import { getAllInvoices } from "@/lib/api";
import { Loader2 } from "lucide-react";
import {
  ChartContainer,
  ChartTooltip,
  ChartTooltipContent,
  ChartLegend,
  ChartLegendContent,
  type ChartConfig,
} from "@/components/ui/chart";

const chartConfig = {
  paid: {
    label: "Paid",
    color: "var(--chart-1)",
  },
  pending: {
    label: "Pending",
    color: "var(--chart-3)",
  },
} satisfies ChartConfig;

export function RevenueChart() {
  const { data, isLoading, isError } = useQuery({
    queryKey: ["all-invoices"],
    queryFn: () => getAllInvoices(),
  });

  const chartData = useMemo(() => {
    const invoices = data?.res || [];

    const monthNames = [
      "Jan", "Feb", "Mar", "Apr", "May", "Jun",
      "Jul", "Aug", "Sep", "Oct", "Nov", "Dec",
    ];

    const monthly = monthNames.reduce(
      (acc, month) => {
        acc[month] = { paid: 0, pending: 0 };
        return acc;
      },
      {} as Record<string, { paid: number; pending: number }>,
    );

    invoices.forEach((inv) => {
      if (inv.status !== "paid" && inv.status !== "pending_payment") return;

      const rawDate =
        inv.createdAt || inv.user?.createdAt || new Date().toISOString();
      const monthName = monthNames[new Date(rawDate).getMonth()];
      const amount = (Number(inv.totalAmount) || 0) / 100;

      if (!monthName) return;
      if (inv.status === "paid") monthly[monthName].paid += amount;
      else monthly[monthName].pending += amount;
    });

    return monthNames.map((name) => ({ name, ...monthly[name] }));
  }, [data]);

  if (isLoading)
    return (
      <div className="flex h-75 items-center justify-center">
        <Loader2 className="animate-spin" />
      </div>
    );
  if (isError)
    return (
      <div className="flex h-75 items-center justify-center text-destructive">
        Error loading chart
      </div>
    );

  return (
    <ChartContainer config={chartConfig} className="aspect-auto h-75 w-full">
      <AreaChart data={chartData} margin={{ top: 10, right: 10, left: -20, bottom: 0 }}>
        <defs>
          <linearGradient id="fillPaid" x1="0" y1="0" x2="0" y2="1">
            <stop offset="5%" stopColor="var(--color-paid)" stopOpacity={0.35} />
            <stop offset="95%" stopColor="var(--color-paid)" stopOpacity={0.02} />
          </linearGradient>
          <linearGradient id="fillPending" x1="0" y1="0" x2="0" y2="1">
            <stop offset="5%" stopColor="var(--color-pending)" stopOpacity={0.35} />
            <stop offset="95%" stopColor="var(--color-pending)" stopOpacity={0.02} />
          </linearGradient>
        </defs>
        <CartesianGrid strokeDasharray="3 3" vertical={false} />
        <XAxis
          dataKey="name"
          fontSize={12}
          tickLine={false}
          axisLine={false}
        />
        <YAxis
          fontSize={12}
          tickLine={false}
          axisLine={false}
          tickFormatter={(value) => `$${value}`}
        />
        <ChartTooltip
          content={
            <ChartTooltipContent
              indicator="dot"
              formatter={(value, name) => [
                `$${Number(value).toFixed(2)}`,
                ` ${chartConfig[name as keyof typeof chartConfig]?.label ?? name}`,
              ]}
            />
          }
        />
        <Area
          type="monotone"
          dataKey="paid"
          stroke="var(--color-paid)"
          fill="url(#fillPaid)"
          strokeWidth={2.5}
        />
        <Area
          type="monotone"
          dataKey="pending"
          stroke="var(--color-pending)"
          fill="url(#fillPending)"
          strokeWidth={2.5}
        />
        <ChartLegend content={<ChartLegendContent />} />
      </AreaChart>
    </ChartContainer>
  );
}
