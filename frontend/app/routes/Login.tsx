import type { Route } from "../+types/root";
import {
  Activity,
  Lock,
  Mail,
  ChevronRight,
  AlertCircle,
  ShieldCheck,
  Clock,
  Stethoscope,
} from "lucide-react";
import { CustomInput } from "@/components/global/CustomInput";
import { Button } from "@/components/ui/button";
import { Checkbox } from "@/components/ui/checkbox";
import { useForm } from "react-hook-form";
import { useState } from "react";
import z from "zod";
import { zodResolver } from "@hookform/resolvers/zod";
import { toast } from "sonner";
import { authClient } from "@/lib/auth-client";
import { useNavigate, Navigate } from "react-router"; // Import this to redirect
import { loginSchema } from "@/components/auth/login.schema";
import Loader from "@/components/global/Loader";

export function meta({}: Route.MetaArgs) {
  return [
    { title: "Login" },
    { name: "description", content: "Login to our amazing Medflow" },
  ];
}

type LoginFormValues = z.infer<typeof loginSchema>;

const Login = () => {
  const [globalError, setGlobalError] = useState("");
  const [isLoading, setIsLoading] = useState(false);
  const navigate = useNavigate(); // Hook for redirection
  const { data: session, isPending } = authClient.useSession();

  const form = useForm<LoginFormValues>({
    resolver: zodResolver(loginSchema),
    defaultValues: { email: "", password: "", rememberMe: false },
  });

  if (isPending) {
    return (
      <div className="min-h-screen flex justify-center items-center">
        <Loader label="Loading..." />
      </div>
    );
  }

  // Redirect if logged in
  if (session) {
    return <Navigate to="/dashboard" replace />;
  }

  const onSubmit = async (data: LoginFormValues) => {
    setGlobalError("");
    setIsLoading(true);
    await authClient.signIn.email(
      {
        email: data.email,
        password: data.password,
        rememberMe: data.rememberMe,
      },
      {
        // Optional: Callbacks for cleaner logic
        onSuccess: () => {
          // we need to fix toast as it was not showing
          toast.success("Login Successful!");
          navigate("/dashboard"); // 👈 Redirect user after login
        },
        onError: (ctx) => {
          // ctx.error.message contains the server response (e.g. "Invalid password")
          setGlobalError(ctx.error.message);
        },
      },
    );
    setIsLoading(false);
  };
  return (
    <div className="min-h-screen flex bg-slate-50 dark:bg-slate-950 transition-colors">
      {/* Brand / illustration panel — hidden below lg, where the form panel
          becomes the whole page (matches the previous single-column layout). */}
      <div className="hidden lg:flex lg:w-1/2 relative overflow-hidden bg-linear-to-br from-blue-600 via-indigo-600 to-indigo-800">
        <div className="absolute -top-24 -left-24 w-96 h-96 bg-white/10 rounded-full blur-3xl" />
        <div className="absolute bottom-10 -right-24 w-96 h-96 bg-white/10 rounded-full blur-3xl" />

        <div className="relative z-10 flex flex-col justify-between p-12 text-white w-full">
          <div className="flex items-center gap-3">
            <div className="bg-white/15 backdrop-blur p-2.5 rounded-xl">
              <Activity className="w-6 h-6" />
            </div>
            <span className="text-xl font-black tracking-tight">
              Ask Musawo
            </span>
          </div>

          <div className="max-w-md">
            <h2 className="text-4xl font-black leading-tight mb-4">
              Real-time care,
              <br />
              whenever you need it.
            </h2>
            <p className="text-blue-100 text-lg mb-8">
              Sign in to manage appointments, patients, and consultations from
              one secure portal.
            </p>
            <div className="space-y-4">
              <div className="flex items-center gap-3 text-blue-50">
                <div className="bg-white/15 backdrop-blur p-2 rounded-lg shrink-0">
                  <ShieldCheck className="w-4 h-4" />
                </div>
                <span className="text-sm font-medium">
                  HIPAA-conscious, encrypted patient data
                </span>
              </div>
              <div className="flex items-center gap-3 text-blue-50">
                <div className="bg-white/15 backdrop-blur p-2 rounded-lg shrink-0">
                  <Clock className="w-4 h-4" />
                </div>
                <span className="text-sm font-medium">
                  Live appointment and triage updates
                </span>
              </div>
              <div className="flex items-center gap-3 text-blue-50">
                <div className="bg-white/15 backdrop-blur p-2 rounded-lg shrink-0">
                  <Stethoscope className="w-4 h-4" />
                </div>
                <span className="text-sm font-medium">
                  Built for doctors, nurses, and admins alike
                </span>
              </div>
            </div>
          </div>

          {/* spacer so the photo has room to sit at the bottom without
              overlapping the copy above on shorter viewports */}
          <div className="h-40" />
        </div>

        <img
          src="/images/doctor-photo.png"
          alt=""
          className="absolute bottom-0 right-6 w-2/3 max-w-sm object-contain drop-shadow-2xl pointer-events-none select-none"
        />
      </div>

      {/* Form panel */}
      <div className="flex-1 flex items-center justify-center p-6 sm:p-10">
        <div className="w-full max-w-md">
          {/* Logo shown only when the brand panel is hidden (mobile/tablet) */}
          <div className="flex lg:hidden flex-col items-center mb-10">
            <div className="bg-linear-to-tr from-blue-600 to-indigo-600 p-3 rounded-2xl shadow-lg shadow-blue-500/30 mb-4">
              <Activity className="text-white w-8 h-8" />
            </div>
            <h1 className="text-2xl font-black text-slate-900 dark:text-white tracking-tight">
              Ask Musawo
            </h1>
            <p className="text-slate-500 dark:text-slate-400 font-medium text-sm mt-1">
              Secure Provider Portal
            </p>
          </div>

          <div className="hidden lg:block mb-10">
            <h1 className="text-3xl font-black text-slate-900 dark:text-white tracking-tight">
              Welcome back
            </h1>
            <p className="text-slate-500 dark:text-slate-400 mt-2">
              Sign in to your provider account
            </p>
          </div>

          {/* global error */}
          {globalError && (
            <div className="mb-6 bg-red-50 dark:bg-red-950/30 text-red-600 dark:text-red-400 p-4 rounded-2xl text-sm flex items-center gap-3 border border-red-100 dark:border-red-900/50 animate-in slide-in-from-top-2 fade-in">
              <AlertCircle size={18} className="shrink-0" />
              <span className="font-medium">{globalError}</span>
            </div>
          )}
          {/* form */}
          <form className="space-y-6" onSubmit={form.handleSubmit(onSubmit)}>
            {/* input(custom) */}
            <CustomInput
              control={form.control}
              name="email"
              label="Email Address"
              placeholder="name@hospital.com"
              type="email"
              startIcon={<Mail size={18} />}
            />
            <CustomInput
              control={form.control}
              name="password"
              label="Password"
              placeholder="••••••••"
              type="password"
              startIcon={<Lock size={18} />}
            />
            <div className="flex items-center justify-between py-2">
              <div className="flex items-center space-x-2">
                <Checkbox
                  id="remember"
                  onCheckedChange={(checked) =>
                    form.setValue("rememberMe", checked as boolean)
                  }
                  className="border-slate-200 dark:border-slate-700 data-[state=checked]:bg-blue-600 data-[state=checked]:border-blue-600"
                />
                <label
                  htmlFor="remember"
                  className="text-sm font-medium leading-none text-slate-500 dark:text-slate-400 cursor-pointer hover:text-slate-700 dark:hover:text-slate-300 transition-colors"
                >
                  Keep me signed in
                </label>
              </div>
              <button
                type="button"
                className="text-sm font-bold text-blue-600 dark:text-blue-400 hover:text-blue-700 dark:hover:text-blue-300 transition-colors"
              >
                Forgot?
              </button>
            </div>
            <Button
              type="submit"
              disabled={isLoading}
              className="w-full bg-slate-900 dark:bg-blue-600 hover:bg-slate-800 dark:hover:bg-blue-700 text-white rounded-2xl py-6 font-bold text-base shadow-xl shadow-slate-200 dark:shadow-blue-900/20 transition-all active:scale-[0.98] group"
            >
              {isLoading ? (
                <div className="flex items-center gap-2">
                  <div className="w-4 h-4 border-2 border-white/30 border-t-white rounded-full animate-spin" />
                  <span>Verifying...</span>
                </div>
              ) : (
                <div className="flex items-center justify-center gap-2">
                  Sign Into Portal
                  <ChevronRight
                    size={18}
                    className="group-hover:translate-x-1 transition-transform"
                  />
                </div>
              )}
            </Button>
          </form>
        </div>
      </div>
    </div>
  );
};

export default Login;
