import { Outlet } from "react-router";
import Navbar from "@/components/home/Navbar";
import Footer from "@/components/home/Footer";

export default function MarketingLayout() {
  return (
    <div className="relative overflow-x-clip overflow-y-visible bg-[#F5F0E6]">
      <div className="bg-linear-to-b from-[#F8F5F2] to-[#F4F6F1]">
        <Navbar />
        <Outlet />
      </div>
      <Footer />
    </div>
  );
}
