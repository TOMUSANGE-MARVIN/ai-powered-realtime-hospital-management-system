import { useEffect, useState } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { toast } from "sonner";
import { getLegal, updateLegal } from "@/lib/api";
import type { LegalDocuments } from "@/types";
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Textarea } from "@/components/ui/textarea";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import Loader from "@/components/global/Loader";
import LegalText from "@/components/legal/LegalText";

export function meta() {
  return [{ title: "Legal & Consent | Ask Musawo" }];
}

type Field = "terms" | "privacy" | "telemedicineConsent";

const FIELDS: { key: Field; label: string; hint: string }[] = [
  {
    key: "privacy",
    label: "Privacy Policy",
    hint: "Shown at sign-up, in the app's Privacy settings and at /privacy.",
  },
  {
    key: "terms",
    label: "Terms of Service",
    hint: "Shown at sign-up, in the app's Privacy settings and at /terms.",
  },
  {
    key: "telemedicineConsent",
    label: "Consultation consent",
    hint: "What patients agree to on every booking (\"What this means\").",
  },
];

// E23.2: admins edit the legal text here. "Save" fixes wording without
// asking anyone again; "Publish new version" makes every patient and doctor
// accept the Terms and Privacy Policy again before they continue.
export default function LegalSettings() {
  const queryClient = useQueryClient();
  const { data, isLoading } = useQuery({ queryKey: ["legal"], queryFn: getLegal });
  const [draft, setDraft] = useState<Pick<LegalDocuments, Field> | null>(null);
  const [preview, setPreview] = useState(false);

  useEffect(() => {
    if (data) {
      setDraft({
        terms: data.terms,
        privacy: data.privacy,
        telemedicineConsent: data.telemedicineConsent,
      });
    }
  }, [data]);

  const mutation = useMutation({
    mutationFn: updateLegal,
    onSuccess: (docs, vars) => {
      queryClient.setQueryData(["legal"], docs);
      toast.success(
        vars.publishNewVersion
          ? `Version ${docs.version} published — users will be asked to accept it`
          : "Saved",
      );
    },
    onError: (e: any) => toast.error(e.message || "Failed to save"),
  });

  if (isLoading || !draft || !data) {
    return (
      <div className="flex justify-center py-16">
        <Loader label="Loading legal documents..." />
      </div>
    );
  }

  const dirty =
    draft.terms !== data.terms ||
    draft.privacy !== data.privacy ||
    draft.telemedicineConsent !== data.telemedicineConsent;

  const publish = () => {
    if (
      !window.confirm(
        "Publish a new version? Every patient and doctor will have to read and accept the Terms and Privacy Policy again before they can continue.",
      )
    )
      return;
    mutation.mutate({ ...draft, publishNewVersion: true });
  };

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-3xl font-black tracking-tight">Legal & Consent</h1>
        <p className="text-slate-500 font-medium">
          Current version <span className="font-semibold">{data.version}</span>,
          last changed {new Date(data.updatedAt).toLocaleString()}. Have changes
          reviewed by a lawyer before publishing.
        </p>
      </div>

      <Card className="card shadow-sm">
        <CardHeader className="flex flex-row items-center justify-between gap-4">
          <div>
            <CardTitle>Documents</CardTitle>
            <CardDescription>
              Format: "## " for headings, "- " for bullet points, a blank line
              between paragraphs.
            </CardDescription>
          </div>
          <div className="flex flex-wrap gap-2">
            <Button variant="outline" size="sm" onClick={() => setPreview(!preview)}>
              {preview ? "Edit" : "Preview"}
            </Button>
            <Button
              variant="outline"
              size="sm"
              disabled={!dirty || mutation.isPending}
              onClick={() => mutation.mutate(draft)}
            >
              Save wording
            </Button>
            <Button size="sm" disabled={mutation.isPending} onClick={publish}>
              Publish new version
            </Button>
          </div>
        </CardHeader>
        <CardContent>
          <Tabs defaultValue="privacy">
            <TabsList>
              {FIELDS.map((f) => (
                <TabsTrigger key={f.key} value={f.key}>
                  {f.label}
                </TabsTrigger>
              ))}
            </TabsList>
            {FIELDS.map((f) => (
              <TabsContent key={f.key} value={f.key} className="space-y-2 pt-2">
                <p className="text-sm text-muted-foreground">{f.hint}</p>
                {preview ? (
                  <div className="rounded-md border p-6 bg-white">
                    <LegalText text={draft[f.key]} />
                  </div>
                ) : (
                  <Textarea
                    value={draft[f.key]}
                    onChange={(e) => setDraft({ ...draft, [f.key]: e.target.value })}
                    className="min-h-[480px] font-mono text-sm"
                  />
                )}
              </TabsContent>
            ))}
          </Tabs>
        </CardContent>
      </Card>
    </div>
  );
}
