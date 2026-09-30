import LegalPage from "@/components/legal/LegalPage";

export function meta() {
  return [
    { title: "Terms of Service — Ask Musawo" },
    { name: "description", content: "The terms for using Ask Musawo." },
  ];
}

export default function Terms() {
  return <LegalPage kind="terms" />;
}
