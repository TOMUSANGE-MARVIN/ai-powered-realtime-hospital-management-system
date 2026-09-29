import { useState } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { toast } from "sonner";
import { Bell, Link2, Send, Users } from "lucide-react";
import { getAnnouncements, getRecipientCount, sendAnnouncement } from "@/lib/api";
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
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import { Textarea } from "@/components/ui/textarea";
import CustomPagination from "@/components/global/CustomPagination";
import Loader from "@/components/global/Loader";

export function meta() {
  return [{ title: "Notifications | Ask Musawo" }];
}

type Audience = "all" | "patients" | "doctors";

const AUDIENCE_LABEL: Record<Audience, string> = {
  all: "Everyone",
  patients: "Patients",
  doctors: "Doctors",
};

export default function Announcements() {
  const queryClient = useQueryClient();
  const [audience, setAudience] = useState<Audience>("all");
  const [title, setTitle] = useState("");
  const [message, setMessage] = useState("");
  const [link, setLink] = useState("");
  const [confirming, setConfirming] = useState(false);
  const [page, setPage] = useState(1);

  const recipients = useQuery({
    queryKey: ["recipients", audience],
    queryFn: () => getRecipientCount(audience),
  });
  const history = useQuery({
    queryKey: ["announcements", page],
    queryFn: () => getAnnouncements(page),
    placeholderData: (previous) => previous,
  });

  const send = useMutation({
    mutationFn: sendAnnouncement,
    onSuccess: ({ sent }) => {
      toast.success(`Sent to ${sent} ${sent === 1 ? "person" : "people"}`);
      setTitle("");
      setMessage("");
      setLink("");
      setConfirming(false);
      setPage(1);
      queryClient.invalidateQueries({ queryKey: ["announcements"] });
    },
    onError: (e: any) => {
      toast.error(e.message);
      setConfirming(false);
    },
  });

  const linkValid = !link.trim() || /^(https?:\/\/|\/)/.test(link.trim());
  const ready = title.trim() && message.trim() && linkValid;
  const count = recipients.data?.count;

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-3xl font-black tracking-tight">Notifications</h1>
        <p className="text-slate-500 font-medium">
          Send announcements to patients, doctors or everyone, and see who read them.
        </p>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-5 gap-6">
        <Card className="card shadow-sm lg:col-span-3">
          <CardHeader>
            <CardTitle>New announcement</CardTitle>
            <CardDescription>
              Appears in each recipient's notification bell.
            </CardDescription>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="space-y-2">
              <Label>Send to</Label>
              <div className="flex flex-wrap gap-2">
                {(Object.keys(AUDIENCE_LABEL) as Audience[]).map((a) => (
                  <Button
                    key={a}
                    type="button"
                    variant={audience === a ? "default" : "outline"}
                    size="sm"
                    onClick={() => setAudience(a)}
                  >
                    {AUDIENCE_LABEL[a]}
                  </Button>
                ))}
                <span className="flex items-center gap-1 text-sm text-muted-foreground ml-2">
                  <Users size={14} />
                  {count === undefined ? "…" : `${count} recipient${count === 1 ? "" : "s"}`}
                </span>
              </div>
            </div>
            <div className="space-y-2">
              <Label htmlFor="ann-title">Title</Label>
              <Input
                id="ann-title"
                maxLength={120}
                placeholder="e.g. Clinic closed on Monday"
                value={title}
                onChange={(e) => setTitle(e.target.value)}
              />
            </div>
            <div className="space-y-2">
              <Label htmlFor="ann-message">Message</Label>
              <Textarea
                id="ann-message"
                rows={4}
                maxLength={1000}
                placeholder="What do people need to know?"
                value={message}
                onChange={(e) => setMessage(e.target.value)}
              />
              <div className="text-xs text-muted-foreground text-right">
                {message.length}/1000
              </div>
            </div>
            <div className="space-y-2">
              <Label htmlFor="ann-link">Link (optional)</Label>
              <Input
                id="ann-link"
                placeholder="/faq or https://…"
                value={link}
                onChange={(e) => setLink(e.target.value)}
              />
              {!linkValid && (
                <p className="text-xs text-destructive">
                  Links must start with / or http(s)://
                </p>
              )}
            </div>
            <Button
              className="gap-2"
              disabled={!ready || !count || send.isPending}
              onClick={() => setConfirming(true)}
            >
              <Send size={16} /> Send announcement
            </Button>
          </CardContent>
        </Card>

        <Card className="card shadow-sm lg:col-span-2">
          <CardHeader>
            <CardTitle>Preview</CardTitle>
            <CardDescription>How it shows in the notification list</CardDescription>
          </CardHeader>
          <CardContent>
            <div className="flex gap-3 rounded-lg border p-3">
              <span className="flex size-9 shrink-0 items-center justify-center rounded-full bg-primary/10 text-primary">
                <Bell size={16} />
              </span>
              <div className="min-w-0 space-y-1">
                <div className="font-semibold break-words">
                  {title.trim() || "Announcement title"}
                </div>
                <p className="text-sm text-muted-foreground whitespace-pre-line break-words">
                  {message.trim() || "Your message appears here."}
                </p>
                {link.trim() && linkValid && (
                  <span className="flex items-center gap-1 text-xs text-primary">
                    <Link2 size={12} /> {link.trim()}
                  </span>
                )}
                <div className="text-xs text-muted-foreground">Just now</div>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>

      <Card className="card shadow-sm">
        <CardHeader>
          <CardTitle>Sent announcements</CardTitle>
          <CardDescription>
            Read rate counts recipients who opened it from their bell
          </CardDescription>
        </CardHeader>
        <CardContent className="p-0">
          {history.isLoading ? (
            <div className="flex justify-center py-12">
              <Loader label="Loading history..." />
            </div>
          ) : history.isError || !history.data ? (
            <div className="p-10 text-center text-red-500">Failed to load history.</div>
          ) : (
            <>
              <Table>
                <TableHeader>
                  <TableRow>
                    <TableHead className="pl-6">Announcement</TableHead>
                    <TableHead>Audience</TableHead>
                    <TableHead>Sent</TableHead>
                    <TableHead>Read</TableHead>
                    <TableHead className="pr-6">By</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {history.data.announcements.length === 0 ? (
                    <TableRow>
                      <TableCell colSpan={5} className="text-center h-24 text-muted-foreground">
                        Nothing sent yet.
                      </TableCell>
                    </TableRow>
                  ) : (
                    history.data.announcements.map((a) => {
                      const rate = a.sentCount ? Math.round((a.readCount / a.sentCount) * 100) : 0;
                      return (
                        <TableRow key={a.id}>
                          <TableCell className="pl-6 max-w-md">
                            <div className="font-semibold">{a.title}</div>
                            <div className="text-xs text-muted-foreground line-clamp-2">
                              {a.message}
                            </div>
                          </TableCell>
                          <TableCell>
                            <Badge variant="outline">{AUDIENCE_LABEL[a.audience]}</Badge>
                          </TableCell>
                          <TableCell>
                            <div>{new Date(a.createdAt).toLocaleDateString()}</div>
                            <div className="text-xs text-muted-foreground">
                              {a.sentCount} recipient{a.sentCount === 1 ? "" : "s"}
                            </div>
                          </TableCell>
                          <TableCell className="min-w-32">
                            <div className="text-sm font-medium">
                              {a.readCount} ({rate}%)
                            </div>
                            <div className="h-1.5 rounded-full bg-muted overflow-hidden mt-1">
                              <div className="h-full bg-primary" style={{ width: `${rate}%` }} />
                            </div>
                          </TableCell>
                          <TableCell className="pr-6 text-sm">{a.sentByName}</TableCell>
                        </TableRow>
                      );
                    })
                  )}
                </TableBody>
              </Table>
              {history.data.pagination.totalPages > 1 && (
                <CustomPagination
                  loading={history.isFetching}
                  currentPage={page}
                  setPage={setPage}
                  totalPages={history.data.pagination.totalPages}
                />
              )}
            </>
          )}
        </CardContent>
      </Card>

      <Dialog open={confirming} onOpenChange={setConfirming}>
        <DialogContent className="card sm:max-w-md">
          <DialogHeader>
            <DialogTitle>Send to {count} {count === 1 ? "person" : "people"}?</DialogTitle>
          </DialogHeader>
          <p className="text-sm text-muted-foreground">
            “{title.trim()}” goes to {AUDIENCE_LABEL[audience].toLowerCase()} right away
            and can't be recalled.
          </p>
          <DialogFooter>
            <Button variant="outline" onClick={() => setConfirming(false)}>
              Cancel
            </Button>
            <Button
              disabled={send.isPending}
              onClick={() =>
                send.mutate({
                  audience,
                  title: title.trim(),
                  message: message.trim(),
                  link: link.trim() || undefined,
                })
              }
            >
              Send now
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
}
