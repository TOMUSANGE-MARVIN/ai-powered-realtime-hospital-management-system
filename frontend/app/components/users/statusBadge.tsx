import {
  CheckCircle2,
  Clock,
  Home,
  Activity,
  AlertCircle,
  LogOut,
  HeartPulse,
  Ban,
} from "lucide-react";

export const STATUS_CONFIG: Record<
  string,
  { label: string; color: string; icon?: any }
> = {
  // --- Patient ---
  admitted: {
    label: "Admitted",
    color:
      "bg-orange-100 text-orange-700 border-orange-200 dark:bg-orange-900/30 dark:text-orange-400 dark:border-orange-900",
    icon: Home,
  },
  in_treatment: {
    label: "In Treatment",
    color:
      "bg-blue-100 text-blue-700 border-blue-200 dark:bg-blue-900/30 dark:text-blue-400 dark:border-blue-900",
    icon: Activity,
  },
  observation: {
    label: "Observation",
    color:
      "bg-yellow-100 text-yellow-700 border-yellow-200 dark:bg-yellow-900/30 dark:text-yellow-400 dark:border-yellow-900",
    icon: Clock,
  },
  discharged: {
    label: "Discharged",
    color:
      "bg-green-100 text-green-700 border-green-200 dark:bg-green-900/30 dark:text-green-400 dark:border-green-900",
    icon: CheckCircle2,
  },
  follow_up: {
    label: "Follow Up",
    color:
      "bg-purple-100 text-purple-700 border-purple-200 dark:bg-purple-900/30 dark:text-purple-400 dark:border-purple-900",
    icon: AlertCircle,
  },
  deceased: {
    label: "Deceased",
    color:
      "bg-zinc-800/10 text-zinc-600 border-zinc-300 dark:bg-zinc-100/10 dark:text-zinc-400 dark:border-zinc-700",
    icon: HeartPulse,
  },

  // --- Staff ---
  active: {
    label: "Active",
    color:
      "bg-emerald-100 text-emerald-700 border-emerald-200 dark:bg-emerald-900/30 dark:text-emerald-400 dark:border-emerald-900",
    icon: CheckCircle2,
  },
  on_leave: {
    label: "On Leave",
    color:
      "bg-sky-100 text-sky-700 border-sky-200 dark:bg-sky-900/30 dark:text-sky-400 dark:border-sky-900",
    icon: Clock,
  },
  suspended: {
    label: "Suspended",
    color:
      "bg-amber-100 text-amber-700 border-amber-200 dark:bg-amber-900/30 dark:text-amber-400 dark:border-amber-900",
    icon: Ban,
  },
  resigned: {
    label: "Resigned",
    color:
      "bg-red-50 text-red-700 border-red-200 dark:bg-red-900/30 dark:text-red-400 dark:border-red-900",
    icon: LogOut,
  },
};
