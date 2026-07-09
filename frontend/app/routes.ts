import {
  type RouteConfig,
  index,
  layout,
  route,
} from "@react-router/dev/routes";

export default [
  index("routes/home.tsx"),
  route("login", "routes/Login.tsx"),
  layout("routes/marketing/layout.tsx", [
    route("about", "routes/marketing/About.tsx"),
    route("services", "routes/marketing/Services.tsx"),
    route("team", "routes/marketing/Doctors.tsx"),
    route("contact", "routes/marketing/Contact.tsx"),
    route("book-appointment", "routes/marketing/BookAppointment.tsx"),
    route("faq", "routes/marketing/FAQ.tsx"),
    route("careers", "routes/marketing/Careers.tsx"),
    route("blog", "routes/marketing/Blog.tsx"),
    route("blog/:slug", "routes/marketing/BlogPost.tsx"),
  ]),
  // you can use index or layout for nested routes
  layout("routes/protected/layout.tsx", [
    route("dashboard", "routes/protected/Dashboard.tsx"),
    route("admins", "routes/protected/Admins.tsx"),
    route("doctors", "routes/protected/Doctors.tsx"),
    route("nurses", "routes/protected/Nurses.tsx"),
    route("patients", "routes/protected/Patients.tsx"),
    route("activities-log", "routes/protected/ActivitiesLog.tsx"),
    route("profile/:id", "routes/protected/Profile.tsx"),
    route("financial-history", "routes/protected/FinancialHistory.tsx"),
  ]),
] satisfies RouteConfig;
