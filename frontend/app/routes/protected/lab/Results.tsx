import { useState } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { getAllLabResults, updateLabResult } from "@/lib/api";
import { toast } from "sonner";
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Textarea } from "@/components/ui/textarea";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import Loader from "@/components/global/Loader";
import { FlaskConical, Sparkles, CheckCircle2 } from "lucide-react";

export function meta() {
  return [{ title: "Results Entry | Ask Musawo" }];
}

function ResultCard({ result, onSaved }: { result: any; onSaved: () => void }) {
  const [notes, setNotes] = useState(result.doctorNotes || "");

  const mutation = useMutation({
    mutationFn: updateLabResult,
    onSuccess: () => {
      toast.success("Result recorded");
      onSaved();
    },
    onError: (e: any) => toast.error(e.message || "Failed to save result"),
  });

  const markReviewed = () => {
    mutation.mutate({ id: result.id, data: { doctorNotes: notes, status: "reviewed" } });
  };

  return (
    <Card className="card shadow-sm">
      <CardHeader>
        <CardTitle className="text-base flex items-center gap-2">
          <FlaskConical size={16} className="text-slate-400" />
          {result.patientName}
        </CardTitle>
        <CardDescription>
          {result.testType}
          {result.bodyPart ? ` — ${result.bodyPart}` : ""} •{" "}
          {new Date(result.createdAt).toLocaleDateString()}
        </CardDescription>
      </CardHeader>
      <CardContent className="space-y-3">
        {result.imageUrl && (
          <img
            src={result.imageUrl}
            alt={result.testType}
            className="w-full max-h-56 object-contain rounded-lg bg-black/5 dark:bg-white/5"
          />
        )}
        {result.aiAnalysis && (
          <div className="text-xs bg-indigo-50/50 dark:bg-indigo-950/20 p-2 rounded border border-indigo-100/50 dark:border-indigo-900/50 text-indigo-700 dark:text-indigo-300 flex gap-2">
            <Sparkles size={12} className="shrink-0 mt-0.5" />
            <p>{result.aiAnalysis}</p>
          </div>
        )}
        <Textarea
          placeholder="Enter findings / doctor notes..."
          value={notes}
          onChange={(e) => setNotes(e.target.value)}
          className="min-h-20"
        />
        <Button
          className="w-full gap-2"
          disabled={mutation.isPending || !notes.trim()}
          onClick={markReviewed}
        >
          <CheckCircle2 size={16} /> Save & Mark Reviewed
        </Button>
      </CardContent>
    </Card>
  );
}

export default function LabResults() {
  const [status, setStatus] = useState("pending");

  const { data, isLoading, isError, refetch } = useQuery({
    queryKey: ["lab-results", "entry", status],
    queryFn: () =>
      getAllLabResults({ status: status === "all" ? "all" : status, limit: 50 }),
    refetchInterval: 15000,
  });

  if (isLoading) {
    return (
      <div className="flex justify-center items-center min-h-[60vh]">
        <Loader label="Loading Results..." />
      </div>
    );
  }
  if (isError) {
    return (
      <div className="p-10 text-center text-red-500">
        Failed to load lab results.
      </div>
    );
  }

  const results = (data?.res || []).filter((r) =>
    status === "all" ? true : status === "pending" ? r.status !== "reviewed" : true,
  );

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-black tracking-tight">Results Entry</h1>
          <p className="text-slate-500 font-medium">
            Review AI analysis and record final findings.
          </p>
        </div>
        <Select value={status} onValueChange={setStatus}>
          <SelectTrigger className="w-44">
            <SelectValue />
          </SelectTrigger>
          <SelectContent>
            <SelectItem value="pending">Needs review</SelectItem>
            <SelectItem value="reviewed">Reviewed</SelectItem>
            <SelectItem value="all">All</SelectItem>
          </SelectContent>
        </Select>
      </div>

      {results.length === 0 ? (
        <Card className="card shadow-sm">
          <CardContent className="p-16 text-center text-slate-500">
            No lab results in this view.
          </CardContent>
        </Card>
      ) : (
        <div className="grid grid-cols-1 lg:grid-cols-2 xl:grid-cols-3 gap-4">
          {results.map((r) => (
            <ResultCard key={r.id} result={r} onSaved={refetch} />
          ))}
        </div>
      )}
    </div>
  );
}
