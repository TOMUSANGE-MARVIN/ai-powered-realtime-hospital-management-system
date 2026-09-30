// Renders the legal documents' plain format — "## " headings, "- " bullet
// points, blank-line-separated paragraphs — the same format the mobile app
// renders and admins edit in Settings → Legal & Consent.
export default function LegalText({ text }: { text: string }) {
  const blocks: React.ReactNode[] = [];
  let bullets: string[] = [];
  const flush = () => {
    if (!bullets.length) return;
    blocks.push(
      <ul key={`ul-${blocks.length}`} className="my-3 list-disc space-y-1.5 pl-6">
        {bullets.map((b, i) => (
          <li key={i}>{b}</li>
        ))}
      </ul>,
    );
    bullets = [];
  };
  text.split("\n").forEach((raw, i) => {
    const line = raw.trimEnd();
    if (line.startsWith("- ")) {
      bullets.push(line.slice(2));
      return;
    }
    flush();
    if (!line) return;
    if (line.startsWith("## ")) {
      blocks.push(
        <h2 key={i} className="mt-8 mb-2 font-display text-xl font-medium text-stone-900">
          {line.slice(3)}
        </h2>,
      );
    } else {
      blocks.push(
        <p key={i} className="my-3">
          {line}
        </p>,
      );
    }
  });
  flush();
  return <div className="text-[15px] leading-relaxed text-stone-700">{blocks}</div>;
}
