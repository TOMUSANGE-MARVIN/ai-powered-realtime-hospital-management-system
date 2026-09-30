import { useState } from "react";
import { useMutation, useQuery } from "@tanstack/react-query";
import { toast } from "sonner";
import { FileText } from "lucide-react";
import {
  getDoctorVerifications,
  reviewDoctorVerification,
} from "@/lib/api";
import type { DoctorVerification } from "@/types";
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import Loader from "@/components/global/Loader";

// Doctor licence verification queue (E23.1). Doctors stay hidden from
// patients until approved here; rejecting sends the reason to the doctor,
// who can fix their details in the app and resubmit.

const FILTERS = [
  { value: "pending", label: "Pending" },
  { value: "rejected", label: "Rejected" },
  { value: "approved", label: "Approved" },
  { value: "none", label: "Not submitted" },
  { value: "all", label: "All" },
] as const;

const STATUS_BADGE: Record<string, string> = {
  pending: "bg-orange-100 text-orange-700",
  approved: "bg-teal-100 text-teal-700",
  rejected: "bg-red-100 text-red-700",
  none: "bg-slate-100 text-slate-600",
};

const isPdf = (url: string) => url.toLowerCase().endsWith(".pdf");

export default function VerificationQueue() {
  const [filter, setFilter] =
    useState<(typeof FILTERS)[number]["value"]>("pending");

  const { data, isLoading, isError, refetch } = useQuery({
    queryKey: ["doctor-verifications", filter],
    queryFn: () => getDoctorVerifications(filter),
  });

  const mutation = useMutation({
    mutationFn: reviewDoctorVerification,
    onSuccess: (doctor, vars) => {
      toast.success(
        vars.decision === "approve"
          ? `${doctor.name} approved — patients can now book them`
          : `${doctor.name} rejected — they've been told why`,
      );
      refetch();
    },
    onError: (e: any) => toast.error(e.message || "Failed to update"),
  });

  const approve = (d: DoctorVerification) => {
    if (
      !window.confirm(
        `Approve ${d.name}? Check licence ${d.licenseNumber} against the UMDPC register first.`,
      )
    )
      return;
    mutation.mutate({ id: d.id, decision: "approve" });
  };

  const reject = (d: DoctorVerification) => {
    const reason = window.prompt(
      "Reason for rejecting (shown to the doctor so they can fix it)",
    );
    if (!reason?.trim()) return;
    mutation.mutate({ id: d.id, decision: "reject", reason: reason.trim() });
  };

  return (
    <Card className="card shadow-sm">
      <CardHeader className="flex flex-row items-center justify-between gap-4">
        <div>
          <CardTitle>Licence verification</CardTitle>
          <CardDescription>
            Check each licence against the Uganda Medical and Dental
            Practitioners Council register. Doctors are hidden from patients
            until approved.
          </CardDescription>
        </div>
        <div className="flex flex-wrap gap-2">
          {FILTERS.map((f) => (
            <Button
              key={f.value}
              size="sm"
              variant={filter === f.value ? "default" : "outline"}
              onClick={() => setFilter(f.value)}
            >
              {f.label}
            </Button>
          ))}
        </div>
      </CardHeader>
      <CardContent>
        {isLoading ? (
          <div className="flex justify-center py-16">
            <Loader label="Loading doctors..." />
          </div>
        ) : isError ? (
          <div className="p-10 text-center text-red-500">
            Failed to load doctors.
          </div>
        ) : (
          <div className="rounded-md border border-zinc-300 dark:border-zinc-700">
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>Doctor</TableHead>
                  <TableHead>Licence</TableHead>
                  <TableHead>Facility</TableHead>
                  <TableHead>Document</TableHead>
                  <TableHead>Status</TableHead>
                  <TableHead className="text-right">Actions</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {(data || []).length === 0 ? (
                  <TableRow>
                    <TableCell
                      colSpan={6}
                      className="text-center h-24 text-muted-foreground"
                    >
                      Nothing here.
                    </TableCell>
                  </TableRow>
                ) : (
                  data!.map((d) => {
                    const status = d.doctorVerificationStatus ?? "none";
                    return (
                      <TableRow key={d.id}>
                        <TableCell>
                          <div className="font-medium">{d.name}</div>
                          <div className="text-xs text-muted-foreground">
                            {d.specialization || "No specialty"} · {d.email}
                            {d.phoneNumber ? ` · ${d.phoneNumber}` : ""}
                          </div>
                        </TableCell>
                        <TableCell>
                          <div className="font-medium">
                            {d.licenseNumber || "—"}
                          </div>
                          {d.yearsOfExperience != null && (
                            <div className="text-xs text-muted-foreground">
                              {d.yearsOfExperience} years' experience
                            </div>
                          )}
                        </TableCell>
                        <TableCell>
                          <div className="font-medium">
                            {d.hospitalName || "—"}
                          </div>
                          {d.hospitalAddress && (
                            <div className="text-xs text-muted-foreground">
                              {d.hospitalAddress}
                            </div>
                          )}
                        </TableCell>
                        <TableCell>
                          {d.licenseDocumentUrl ? (
                            <a
                              href={d.licenseDocumentUrl}
                              target="_blank"
                              rel="noreferrer"
                              className="inline-flex items-center gap-2 text-teal-700 hover:underline"
                            >
                              {isPdf(d.licenseDocumentUrl) ? (
                                <>
                                  <FileText className="h-4 w-4" /> Open PDF
                                </>
                              ) : (
                                <img
                                  src={d.licenseDocumentUrl}
                                  alt={`${d.name}'s licence`}
                                  className="h-14 w-20 rounded-sm border object-cover"
                                />
                              )}
                            </a>
                          ) : (
                            <span className="text-muted-foreground">None</span>
                          )}
                        </TableCell>
                        <TableCell>
                          <Badge className={`capitalize ${STATUS_BADGE[status]}`}>
                            {status === "none" ? "Not submitted" : status}
                          </Badge>
                          {d.verificationSubmittedAt && (
                            <div className="text-xs text-muted-foreground mt-1">
                              Submitted{" "}
                              {new Date(d.verificationSubmittedAt).toLocaleDateString()}
                            </div>
                          )}
                          {status === "rejected" && d.verificationNote && (
                            <div className="text-xs text-muted-foreground mt-1">
                              {d.verificationNote}
                            </div>
                          )}
                        </TableCell>
                        <TableCell className="text-right">
                          <div className="flex justify-end gap-2">
                            {status !== "approved" && d.licenseDocumentUrl && (
                              <Button
                                size="sm"
                                disabled={mutation.isPending}
                                onClick={() => approve(d)}
                              >
                                Approve
                              </Button>
                            )}
                            {status !== "rejected" && status !== "none" && (
                              <Button
                                size="sm"
                                variant="destructive"
                                disabled={mutation.isPending}
                                onClick={() => reject(d)}
                              >
                                {status === "approved" ? "Revoke" : "Reject"}
                              </Button>
                            )}
                          </div>
                        </TableCell>
                      </TableRow>
                    );
                  })
                )}
              </TableBody>
            </Table>
          </div>
        )}
      </CardContent>
    </Card>
  );
}
