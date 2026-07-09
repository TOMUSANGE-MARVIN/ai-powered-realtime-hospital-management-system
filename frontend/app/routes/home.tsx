import type { Route } from "./+types/home";
import Navbar from "@/components/home/Navbar";
import Hero from "@/components/home/Hero";
import HelpSection from "@/components/home/HelpSection";
import ConfidenceSection from "@/components/home/ConfidenceSection";
import FeaturesSection from "@/components/home/FeaturesSection";
import AICapabilitiesSection from "@/components/home/AICapabilitiesSection";
import ProcessSection from "@/components/home/ProcessSection";
import VideoSection from "@/components/home/VideoSection";
import TestimonialSection from "@/components/home/TestimonialSection";
import BlogSection from "@/components/home/BlogSection";
import Footer from "@/components/home/Footer";

export function meta({}: Route.MetaArgs) {
  return [
    { title: "Ask Musawo — Smarter care starts here" },
    {
      name: "description",
      content:
        "Real-time patient monitoring and AI-assisted diagnostics for modern hospitals.",
    },
  ];
}

export default function Home() {
  return (
    <div className="relative overflow-x-clip overflow-y-visible bg-[#F5F0E6]">
      {/* decorative corner accents */}
      <div className="pointer-events-none absolute -top-40 -left-40 size-80 rounded-full bg-orange-400" />
      <div className="pointer-events-none absolute right-0 bottom-40 size-72 translate-x-1/3 rounded-full bg-amber-300" />

      <div className="relative">
        {/* z-10 keeps this content stacked above VideoSection's fixed video
            backdrop regardless of scroll position or DOM order */}
        <div className="relative z-10">
          <div className="bg-linear-to-b from-[#F8F5F2] to-[#F4F6F1]">
            <Navbar />
            <Hero />
            <HelpSection />
          </div>
          <ConfidenceSection />
          <FeaturesSection />
          <AICapabilitiesSection />
          <ProcessSection />
        </div>
        <VideoSection />
        <div className="relative z-10">
          <TestimonialSection />
          <BlogSection />
          <Footer />
        </div>
      </div>
    </div>
  );
}
