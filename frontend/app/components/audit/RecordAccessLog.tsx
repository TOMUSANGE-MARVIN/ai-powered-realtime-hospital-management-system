import { useState } from "react";
import { useQuery } from "@tanstack/react-query";
import { format } from "date-fns";
import { getRecordAccess } from "@/lib/api";
import type { RecordAccessEntry } from "@/types";
import CustomPagination from "@/components/global/CustomPagination";
import Loader from "@/components/global/Loader";
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
import { Input } from "@/components/ui/input";

// Record-access audit log (E23.3): every time someone other than the patient
// opened a patient's records. Search by the viewer's or the patient's name.

const RESOURCE_LABEL: Record<RecordAccessEntry["resource"], string> = {
  full_history: "Full history",
  lab_results: "Lab results",
  prescriptions: "Prescriptions",
  profile: "Profile",
};

const LIMIT = 20;

export default function RecordAccessLog() {
  const [page, setPage] = useState(1);
  const [search, setSearch] = useState("");

  const { data, isLoading, isError } = useQuery({
    queryKey: ["record-access", page, search],
    queryFn: () => getRecordAccess({ page, limit: LIMIT, search }),
    placeholderData: (previous) => previous,
  });

  return (
    <Card className="card shadow-sm">
      <CardHeader className="flex flex-row items-center justify-between gap-4">
        <div>
          <CardTitle>Record access</CardTitle>
          <CardDescription>
            Who opened which patient's records. Repeat views by the same person
            within 30 minutes are logged once. Patients see their own entries
            in the app.
          </CardDescription>
        </div>
        <Input
          placeholder="Search viewer or patient"
          value={search}
          onChange={(e) => {
            setSearch(e.target.value);
            setPage(1);
          }}
          className="max-w-xs"
        />
      </CardHeader>
      <CardContent>
        {isLoading ? (
          <div className="flex justify-center py-16">
            <Loader label="Loading record access..." />
          </div>
        ) : isError ? (
          <div className="p-10 text-center text-red-500">
            Failed to load the record-access log.
          </div>
        ) : (
          <div className="rounded-md border border-zinc-300 dark:border-zinc-700">
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>When</TableHead>
                  <TableHead>Viewer</TableHead>
                  <TableHead>Patient</TableHead>
                  <TableHead>Records</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {(data?.res || []).length === 0 ? (
                  <TableRow>
                    <TableCell colSpan={4} className="text-center h-24 text-muted-foreground">
                      Nothing logged yet.
                    </TableCell>
                  </TableRow>
                ) : (
                  data!.res.map((e) => (
                    <TableRow key={e.id}>
                      <TableCell className="whitespace-nowrap">
                        {format(new Date(e.createdAt), "d MMM yyyy, HH:mm")}
                      </TableCell>
                      <TableCell>
                        <div className="font-medium">{e.viewerName}</div>
                        <div className="text-xs text-muted-foreground capitalize">
                          {e.viewerRole.replace("_", " ")}
                        </div>
                      </TableCell>
                      <TableCell>
                        <div className="font-medium">{e.patientName}</div>
                        {e.patientEmail && (
                          <div className="text-xs text-muted-foreground">{e.patientEmail}</div>
                        )}
                      </TableCell>
                      <TableCell>
                        <Badge variant="outline">{RESOURCE_LABEL[e.resource] ?? e.resource}</Badge>
                      </TableCell>
                    </TableRow>
                  ))
                )}
              </TableBody>
            </Table>
            <CustomPagination
              loading={isLoading}
              totalPages={Math.ceil((data?.total || 0) / LIMIT)}
              currentPage={page}
              setPage={setPage}
            />
          </div>
        )}
      </CardContent>
    </Card>
  );
}
