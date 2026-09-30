import { useQuery } from "@tanstack/react-query";
import { getLegal } from "@/lib/api";
import PageHeader from "@/components/home/PageHeader";
import LegalText from "./LegalText";

/** Public Terms of Service / Privacy Policy page, from the published text. */
export default function LegalPage({ kind }: { kind: "terms" | "privacy" }) {
  const { data, isLoading, isError } = useQuery({
    queryKey: ["legal"],
    queryFn: getLegal,
  });

  return (
    <>
      <PageHeader
        eyebrow="Legal"
        title={kind === "privacy" ? "Privacy Policy" : "Terms of Service"}
        description={
          data
            ? `Last updated ${new Date(data.updatedAt).toLocaleDateString("en-GB", {
                day: "numeric",
                month: "long",
                year: "numeric",
              })}`
            : undefined
        }
      />
      <section className="bg-white pb-28">
        <div className="mx-auto max-w-2xl px-6 md:px-4">
          {isLoading ? (
            <div className="space-y-3">
              {[90, 70, 85, 60, 80].map((w, i) => (
                <div
                  key={i}
                  className="h-4 animate-pulse rounded bg-stone-200"
                  style={{ width: `${w}%` }}
                />
              ))}
            </div>
          ) : isError || !data ? (
            <p className="text-stone-600">
              We couldn't load this page. Please try again, or email
              care@askmusawo.co.ug.
            </p>
          ) : (
            <LegalText text={kind === "privacy" ? data.privacy : data.terms} />
          )}
        </div>
      </section>
    </>
  );
}
