import { useEffect, useState } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { toast } from "sonner";
import { Eye, EyeOff, MessageSquareReply, Star, ThumbsDown } from "lucide-react";
import { getAdminReviews, moderateReview } from "@/lib/api";
import type { AdminReview } from "@/types";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
import {
  Dialog,
  DialogContent,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { Textarea } from "@/components/ui/textarea";
import CustomPagination from "@/components/global/CustomPagination";
import GlobalSearch from "@/components/global/GlobalSearch";
import Loader from "@/components/global/Loader";

export function meta() {
  return [{ title: "Reviews & Ratings | Ask Musawo" }];
}

const selectClass = "h-9 rounded-md border bg-background px-3 text-sm";

const HELP_LABELS: Record<string, string> = {
  online_examination: "Online examination",
  consultation: "Consultation",
  medicine_instruction: "Medicine instruction",
};

function Stars({ rating }: { rating: number }) {
  return (
    <span className="flex" aria-label={`${rating} out of 5`}>
      {[1, 2, 3, 4, 5].map((i) => (
        <Star
          key={i}
          size={14}
          className={i <= rating ? "fill-amber-400 text-amber-400" : "text-muted-foreground/40"}
        />
      ))}
    </span>
  );
}

function HideDialog({
  review,
  onClose,
}: {
  review: AdminReview | null;
  onClose: () => void;
}) {
  const [reason, setReason] = useState("");
  const queryClient = useQueryClient();
  const mutation = useMutation({
    mutationFn: moderateReview,
    onSuccess: () => {
      toast.success("Review hidden");
      queryClient.invalidateQueries({ queryKey: ["admin-reviews"] });
      setReason("");
      onClose();
    },
    onError: (e: any) => toast.error(e.message),
  });
  return (
    <Dialog open={!!review} onOpenChange={(open) => !open && onClose()}>
      <DialogContent className="card sm:max-w-md">
        <DialogHeader>
          <DialogTitle>Hide this review?</DialogTitle>
        </DialogHeader>
        <p className="text-sm text-muted-foreground">
          Patients won't see it and it stops counting toward{" "}
          {review?.doctor?.name ?? "the doctor"}'s rating. The doctor still sees
          it, with your reason.
        </p>
        <Textarea
          placeholder="Reason, e.g. abusive language or personal information"
          value={reason}
          onChange={(e) => setReason(e.target.value)}
        />
        <DialogFooter>
          <Button variant="outline" onClick={onClose}>
            Cancel
          </Button>
          <Button
            variant="destructive"
            disabled={!reason.trim() || mutation.isPending}
            onClick={() =>
              review && mutation.mutate({ id: review.id, hidden: true, reason })
            }
          >
            Hide review
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}

export default function Reviews() {
  const [period, setPeriod] = useState("month");
  const [rating, setRating] = useState("all");
  const [replied, setReplied] = useState("all");
  const [visibility, setVisibility] = useState("all");
  const [search, setSearch] = useState("");
  const [debounced, setDebounced] = useState("");
  const [page, setPage] = useState(1);
  const [hiding, setHiding] = useState<AdminReview | null>(null);
  const queryClient = useQueryClient();

  useEffect(() => {
    const t = setTimeout(() => setDebounced(search), 300);
    return () => clearTimeout(t);
  }, [search]);
  useEffect(() => setPage(1), [period, rating, replied, visibility, debounced]);

  const { data, isLoading, isError, isFetching } = useQuery({
    queryKey: ["admin-reviews", period, rating, replied, visibility, debounced, page],
    queryFn: () =>
      getAdminReviews({ period, rating, replied, visibility, search: debounced, page }),
    placeholderData: (previous) => previous,
  });

  const unhide = useMutation({
    mutationFn: moderateReview,
    onSuccess: () => {
      toast.success("Review visible again");
      queryClient.invalidateQueries({ queryKey: ["admin-reviews"] });
    },
    onError: (e: any) => toast.error(e.message),
  });

  if (isLoading) {
    return (
      <div className="flex justify-center items-center min-h-[60vh]">
        <Loader label="Loading reviews..." />
      </div>
    );
  }
  if (isError || !data) {
    return <div className="p-10 text-center text-red-500">Failed to load reviews.</div>;
  }

  const s = data.summary;
  const maxCount = Math.max(1, ...s.distribution.map((d) => d.count));

  return (
    <div className="space-y-6">
      <div className="flex flex-col md:flex-row md:items-end justify-between gap-4">
        <div>
          <h1 className="text-3xl font-black tracking-tight">Reviews & Ratings</h1>
          <p className="text-slate-500 font-medium">
            What patients say about their doctors. Hide reviews that break the rules.
          </p>
        </div>
        <select
          aria-label="Period"
          className={selectClass}
          value={period}
          onChange={(e) => setPeriod(e.target.value)}
        >
          <option value="week">Last 7 days</option>
          <option value="month">Last 30 days</option>
          <option value="quarter">Last 3 months</option>
          <option value="year">Last 12 months</option>
          <option value="all">All time</option>
        </select>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-4">
        <div className="card rounded-xl p-5 shadow-sm flex items-center gap-5">
          <div>
            <div className="text-sm text-muted-foreground">Average rating</div>
            <div className="text-4xl font-black">{s.average ?? "—"}</div>
            <div className="text-xs text-muted-foreground">
              {s.total} visible review{s.total === 1 ? "" : "s"}
            </div>
          </div>
          <div className="flex-1 space-y-1">
            {s.distribution.map((d) => (
              <button
                key={d.stars}
                className="flex w-full items-center gap-2 text-xs"
                onClick={() => setRating(String(d.stars))}
                title={`Show ${d.stars}-star reviews`}
              >
                <span className="w-3">{d.stars}</span>
                <Star size={11} className="fill-amber-400 text-amber-400" />
                <span className="h-2 flex-1 rounded-full bg-muted overflow-hidden">
                  <span
                    className="block h-full bg-amber-400"
                    style={{ width: `${(d.count / maxCount) * 100}%` }}
                  />
                </span>
                <span className="w-6 text-right text-muted-foreground">{d.count}</span>
              </button>
            ))}
          </div>
        </div>
        <div className="card rounded-xl p-5 shadow-sm space-y-1">
          <div className="flex items-center justify-between text-sm text-muted-foreground">
            Low ratings (1–2 ★) <ThumbsDown size={16} />
          </div>
          <div className="text-3xl font-black">{s.lowRatings}</div>
          <div className="text-xs text-muted-foreground">
            {s.hidden} hidden by admins in this period
          </div>
        </div>
        <div className="card rounded-xl p-5 shadow-sm space-y-1">
          <div className="flex items-center justify-between text-sm text-muted-foreground">
            Doctor reply rate <MessageSquareReply size={16} />
          </div>
          <div className="text-3xl font-black">
            {s.replyRate === null ? "—" : `${s.replyRate}%`}
          </div>
          <div className="text-xs text-muted-foreground">of reviews have a doctor reply</div>
        </div>
      </div>

      <Card className="card shadow-sm">
        <CardHeader className="flex flex-col md:flex-row md:items-center justify-between gap-3">
          <div>
            <CardTitle>All reviews</CardTitle>
            <CardDescription>{data.pagination.total} matching</CardDescription>
          </div>
          <div className="flex flex-wrap gap-2">
            <GlobalSearch search={search} setSearch={setSearch} title="doctor, patient, text" />
            <select aria-label="Rating" className={selectClass} value={rating} onChange={(e) => setRating(e.target.value)}>
              <option value="all">All ratings</option>
              {[5, 4, 3, 2, 1].map((r) => (
                <option key={r} value={r}>
                  {r} star{r === 1 ? "" : "s"}
                </option>
              ))}
            </select>
            <select aria-label="Reply" className={selectClass} value={replied} onChange={(e) => setReplied(e.target.value)}>
              <option value="all">Replied or not</option>
              <option value="yes">Doctor replied</option>
              <option value="no">No reply yet</option>
            </select>
            <select aria-label="Visibility" className={selectClass} value={visibility} onChange={(e) => setVisibility(e.target.value)}>
              <option value="all">Visible and hidden</option>
              <option value="visible">Visible</option>
              <option value="hidden">Hidden</option>
            </select>
          </div>
        </CardHeader>
        <CardContent className={`p-0 divide-y ${isFetching ? "opacity-60" : ""}`}>
          {data.reviews.length === 0 ? (
            <div className="p-10 text-center text-muted-foreground">
              No reviews match these filters.
            </div>
          ) : (
            data.reviews.map((r) => (
              <div
                key={r.id}
                className={`px-6 py-4 flex flex-col md:flex-row gap-4 ${r.hidden ? "bg-muted/40" : ""}`}
              >
                <div className="flex-1 space-y-2 min-w-0">
                  <div className="flex flex-wrap items-center gap-x-3 gap-y-1">
                    <Stars rating={r.rating} />
                    <span className="font-semibold">{r.patientName}</span>
                    <span className="text-muted-foreground text-sm">
                      on {r.doctor?.name ?? "Unknown doctor"}
                      {r.doctor?.specialization ? ` · ${r.doctor.specialization}` : ""}
                    </span>
                    <span className="text-xs text-muted-foreground">
                      {new Date(r.createdAt).toLocaleDateString()}
                    </span>
                    {r.hidden && (
                      <Badge variant="secondary" className="gap-1">
                        <EyeOff size={12} /> Hidden
                      </Badge>
                    )}
                  </div>
                  {r.comment ? (
                    <p className="text-sm">{r.comment}</p>
                  ) : (
                    <p className="text-sm italic text-muted-foreground">No written comment</p>
                  )}
                  {r.helpedWith && (
                    <div className="flex flex-wrap gap-1">
                      {r.helpedWith.split(",").map((t) => (
                        <Badge key={t} variant="outline" className="text-xs">
                          {HELP_LABELS[t] ?? t}
                        </Badge>
                      ))}
                    </div>
                  )}
                  {r.doctorReply && (
                    <div className="rounded-lg border-l-2 border-primary bg-muted/50 px-3 py-2 text-sm">
                      <span className="font-semibold">Doctor's reply: </span>
                      {r.doctorReply}
                    </div>
                  )}
                  {r.hidden && r.hiddenReason && (
                    <p className="text-xs text-muted-foreground">
                      Hidden because: {r.hiddenReason}
                    </p>
                  )}
                </div>
                <div className="shrink-0">
                  {r.hidden ? (
                    <Button
                      variant="outline"
                      size="sm"
                      className="gap-1"
                      disabled={unhide.isPending}
                      onClick={() => unhide.mutate({ id: r.id, hidden: false })}
                    >
                      <Eye size={14} /> Unhide
                    </Button>
                  ) : (
                    <Button
                      variant="outline"
                      size="sm"
                      className="gap-1"
                      onClick={() => setHiding(r)}
                    >
                      <EyeOff size={14} /> Hide
                    </Button>
                  )}
                </div>
              </div>
            ))
          )}
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
      <HideDialog review={hiding} onClose={() => setHiding(null)} />
    </div>
  );
}
