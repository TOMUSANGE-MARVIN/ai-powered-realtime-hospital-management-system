import { useState } from "react";
import { useMutation, useQuery } from "@tanstack/react-query";
import { getFeedbackList, createFeedback } from "@/lib/api";
import { toast } from "sonner";
import { authClient } from "@/lib/auth-client";
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
import { Send, Star, MessageSquareHeart } from "lucide-react";

export function meta() {
  return [{ title: "Feedback | Ask Musawo" }];
}

export default function FeedbackPage() {
  const { data: session } = authClient.useSession();
  const isAdmin = session?.user?.role === "admin";

  const [category, setCategory] = useState("general");
  const [message, setMessage] = useState("");
  const [rating, setRating] = useState(5);

  const { data, isLoading, refetch } = useQuery({
    queryKey: ["feedback"],
    queryFn: getFeedbackList,
    enabled: isAdmin,
  });

  const mutation = useMutation({
    mutationFn: createFeedback,
    onSuccess: () => {
      toast.success("Thanks for your feedback!");
      setMessage("");
      refetch();
    },
    onError: (e: any) => toast.error(e.message || "Failed to submit feedback"),
  });

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!message.trim()) return toast.error("Please write a message");
    mutation.mutate({ category, message, rating });
  };

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-3xl font-black tracking-tight">Feedback</h1>
        <p className="text-slate-500 font-medium">
          Tell us what's working and what could be better.
        </p>
      </div>

      <Card className="card shadow-sm max-w-2xl">
        <CardHeader>
          <CardTitle>Share Feedback</CardTitle>
          <CardDescription>Sent directly to the product team.</CardDescription>
        </CardHeader>
        <CardContent>
          <form onSubmit={handleSubmit} className="space-y-4">
            <div className="grid grid-cols-2 gap-4">
              <div className="space-y-1.5">
                <label className="text-xs font-bold text-slate-500 uppercase tracking-widest ml-1">
                  Category
                </label>
                <Select value={category} onValueChange={setCategory}>
                  <SelectTrigger className="w-full">
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="general">General</SelectItem>
                    <SelectItem value="bug">Bug Report</SelectItem>
                    <SelectItem value="feature">Feature Request</SelectItem>
                  </SelectContent>
                </Select>
              </div>
              <div className="space-y-1.5">
                <label className="text-xs font-bold text-slate-500 uppercase tracking-widest ml-1">
                  Rating
                </label>
                <div className="flex items-center gap-1 pt-2">
                  {[1, 2, 3, 4, 5].map((n) => (
                    <button
                      type="button"
                      key={n}
                      onClick={() => setRating(n)}
                      className="p-0.5"
                    >
                      <Star
                        size={22}
                        className={
                          n <= rating
                            ? "fill-amber-400 text-amber-400"
                            : "text-slate-300"
                        }
                      />
                    </button>
                  ))}
                </div>
              </div>
            </div>
            <Textarea
              className="min-h-28"
              value={message}
              onChange={(e) => setMessage(e.target.value)}
              placeholder="What's on your mind?"
            />
            <Button type="submit" className="gap-2" disabled={mutation.isPending}>
              <Send size={16} /> Send Feedback
            </Button>
          </form>
        </CardContent>
      </Card>

      {isAdmin && (
        <Card className="card shadow-sm">
          <CardHeader>
            <CardTitle>All Feedback</CardTitle>
            <CardDescription>Recent submissions from staff and patients.</CardDescription>
          </CardHeader>
          <CardContent className="space-y-3">
            {isLoading ? (
              <Loader label="Loading feedback..." />
            ) : (data || []).length === 0 ? (
              <div className="text-center py-10 text-slate-500 flex flex-col items-center gap-2">
                <MessageSquareHeart size={32} className="text-slate-300" />
                No feedback submitted yet.
              </div>
            ) : (
              (data || []).map((f) => (
                <div
                  key={f._id}
                  className="rounded-lg border border-zinc-200 dark:border-zinc-800 p-3"
                >
                  <div className="flex items-center justify-between mb-1">
                    <span className="font-semibold text-sm">{f.userName}</span>
                    <div className="flex items-center gap-2">
                      <Badge variant="secondary" className="capitalize">
                        {f.category}
                      </Badge>
                      {f.rating && (
                        <span className="flex items-center gap-0.5 text-xs text-amber-500">
                          <Star size={12} className="fill-amber-400" /> {f.rating}
                        </span>
                      )}
                    </div>
                  </div>
                  <p className="text-sm text-slate-600 dark:text-slate-300">
                    {f.message}
                  </p>
                </div>
              ))
            )}
          </CardContent>
        </Card>
      )}
    </div>
  );
}
