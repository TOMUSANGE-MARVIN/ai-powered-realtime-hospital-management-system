import LegalPage from "@/components/legal/LegalPage";

export function meta() {
  return [
    { title: "Privacy Policy — Ask Musawo" },
    {
      name: "description",
      content:
        "How Ask Musawo collects, uses and protects your personal and health information under Uganda's Data Protection and Privacy Act.",
    },
  ];
}

export default function Privacy() {
  return <LegalPage kind="privacy" />;
}
