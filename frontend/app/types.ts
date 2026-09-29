export type Role =
  | "all"
  | "admin"
  | "doctor"
  | "nurse"
  | "pharmacist"
  | "lab_tech"
  | "patient";
// src/types/index.ts

// --- 1. PATIENT STATUSES ---
// Clinical states for patients
export type PatientStatus =
  | "admitted"
  | "in_treatment"
  | "observation"
  | "discharged"
  | "follow_up"
  | "deceased"; // Optional, but common in HMS

// --- 2. STAFF STATUSES ---
// Employment/Availability states for Doctors, Nurses, etc.
export type StaffStatus = "active" | "on_leave" | "suspended" | "resigned";

// --- 3. COMBINED USER STATUS ---
// The actual type used in the generic User interface
export type UserStatus = PatientStatus | StaffStatus;

export interface LabResult {
  id: string;
  patientId: string;
  testType: string;
  bodyPart: string;
  imageUrl: string;
  aiAnalysis: string;
  status: "pending" | "analyzed" | "reviewed";
  doctorNotes: string;
  createdAt: string;
}

export interface User {
  id: string;
  name: string;
  email: string;
  image?: string | null;
  role: Role;
  emailVerified: boolean;
  createdAt: string;
  updatedAt: string;
  status: UserStatus;
  banned: boolean; // For staff, indicates if they are banned from the system
  specialization?: string;
  gender?: string;
  bloodgroup?: string;
  medicalHistory?: string;
  age?: string;
  department?: string;
  labResults?: LabResult[];
  prescriptions?: string[];
  appointmentsXRay?: string[];
  assignedDoctorId?: string | null;
  assignedNurseId?: string | null;
  triageReasoning?: string;
  assignedDoctorName?: string;
  assignedNurseName?: string;
}

export interface PaginatedResponse<T> {
  res: T[];
  pagination: {
    currentPage: number;
    totalPages: number;
    totalData: number;
    limit: number;
  };
}

export interface Notification {
  id: string;
  title: string;
  message: string;
  type: "system" | "assignment" | "lab_result" | "alert";
  isRead: boolean;
  link?: string;
  createdAt: string;
}

export interface WebPushSubscription {
  userId: string;
  endpoint: string;
  keys: {
    p256dh: string;
    auth: string;
  };
}

export interface ActivityLog {
  id: string;
  user: User; // Who did it?
  action: string; // "Created Exam", "Registered Student"
  details?: string;
  createdAt: Date;
}

export interface invoice {
  id: string;
  user: User;
  polarCheckoutId?: string; // Links to Polar transaction
  status: "draft" | "pending_payment" | "paid";
  items: Array<{
    description: string; // e.g., "Chest X-Ray"
    quantity: number;
    unitPrice: number; // in cents (Polar uses cents)
    totalPrice: number;
  }>;
  totalAmount: number; // Sum of all items in cents
  createdAt: Date;
}

export interface appointment {
  id: string;
  patientId?: string;
  patientName: string;
  patientEmail?: string;
  patientPhone?: string;
  doctorId?: string;
  doctorName?: string;
  nurseId?: string;
  department?: string;
  date: string;
  time?: string;
  reason?: string;
  status:
    | "requested"
    | "scheduled"
    | "confirmed"
    | "completed"
    | "cancelled"
    | "in_progress";
  isVirtual: boolean;
  meetingId?: string;
  notes?: string;
  createdAt: string;
}

export interface Category {
  id: string;
  name: string;
  iconKey: string;
  colorKey: string;
  department?: string | null;
  isActive: boolean;
  createdAt: string;
  updatedAt: string;
}

export type OverviewPeriod = "today" | "week" | "month" | "year";

export interface Kpi {
  value: number;
  change: number | null;
}

export interface AdminOverview {
  kpis: {
    totalPatients: Kpi;
    totalDoctors: Kpi;
    activeConsultations: Kpi;
    appointmentsToday: Kpi;
    monthlyRevenue: Kpi;
    platformGrowth: { value: number | null; signupsThisQuarter: number };
  };
  revenue: { period: OverviewPeriod; series: { label: string; revenue: number }[] };
  specialties: { name: string; count: number }[];
  doctorPerformance: {
    id: string;
    name: string;
    image?: string | null;
    specialization?: string | null;
    rating: number;
    reviews: number;
    status: "active" | "suspended";
  }[];
  incompleteProfiles: {
    id: string;
    name: string;
    image?: string | null;
    specialization?: string | null;
    joinedAt: string;
    completed: number;
    total: number;
  }[];
  supportTickets: { recent: SupportTicket[]; open: number };
  systemHealth: {
    serverLoadPercent: number;
    database: string;
    databaseLatencyMs: number;
    apiLatencyMs: number;
  };
}

export interface ConsultationCall {
  id: string;
  type: "voice" | "video" | string;
  status: string;
  durationSeconds: number | null;
  byDoctor: boolean;
  createdAt: string;
}

export interface Consultation {
  id: string;
  patientId: string | null;
  patientName: string;
  doctorId: string | null;
  doctorName: string | null;
  date: string;
  time: string | null;
  status: string;
  consultationType: "physical" | "voice" | "video" | string;
  isEmergency: boolean;
  reason: string | null;
  fee: number | null;
  createdAt: string;
  payment: {
    amount: number;
    status: string;
    method: string;
    voucherCode: string | null;
    discount: number;
    createdAt: string;
  } | null;
  calls: ConsultationCall[];
  talkSeconds: number;
  review: { rating: number; comment: string | null; helpedWith: string | null } | null;
  prescription: { id: string; status: string; createdAt: string } | null;
}

export interface ConsultationsResponse {
  period: OverviewPeriod;
  summary: {
    total: number;
    completed: number;
    inProgress: number;
    upcoming: number;
    cancelled: number;
    completionRate: number | null;
    avgCallSeconds: number | null;
    missedCalls: number;
    revenue: number;
  };
  consultations: Consultation[];
  pagination: { page: number; limit: number; total: number; totalPages: number };
}

export interface CallLogEntry {
  id: string;
  callerId: string;
  callerName: string;
  calleeId: string;
  calleeName: string;
  type: string;
  status: string;
  durationSeconds: number | null;
  createdAt: string;
}

export interface Withdrawal {
  id: string;
  doctorId: string;
  doctorName: string;
  amount: number;
  method: "mobile_money" | "bank";
  provider: string;
  accountName: string;
  accountNumber: string;
  status: "requested" | "approved" | "paid" | "rejected";
  adminNote?: string | null;
  processedAt?: string | null;
  createdAt: string;
}

export interface Voucher {
  id: string;
  code: string;
  discountType: "fixed" | "percent";
  value: number;
  expiresAt?: string | null;
  maxUses?: number | null;
  usedCount: number;
  active: boolean;
  createdAt: string;
  updatedAt: string;
}

export interface CategoryOptions {
  icons: { key: string; label: string }[];
  colors: { key: string; label: string }[];
}

export interface Medication {
  id: string;
  name: string;
  category: string;
  unit: string;
  stock: number;
  reorderLevel: number;
  unitPrice: number;
  expiryDate?: string;
  supplier?: string;
  createdAt: string;
  updatedAt: string;
}

export interface PrescriptionItem {
  medication?: string;
  medicationName: string;
  dosage: string;
  quantity: number;
  instructions?: string;
}

export interface Prescription {
  id: string;
  patient: string;
  patientName: string;
  doctor: string;
  doctorName: string;
  items: PrescriptionItem[];
  status: "pending" | "dispensed" | "cancelled";
  dispensedBy?: string;
  dispensedAt?: string;
  notes?: string;
  createdAt: string;
  updatedAt: string;
}

export interface SupportTicket {
  id: string;
  userId: string;
  userName: string;
  subject: string;
  message: string;
  priority: "low" | "medium" | "high";
  status: "open" | "in_progress" | "resolved";
  createdAt: string;
  updatedAt: string;
}

export interface Feedback {
  id: string;
  userId: string;
  userName: string;
  category: "bug" | "feature" | "general";
  message: string;
  rating?: number;
  createdAt: string;
}

export interface AdminReview {
  id: string;
  appointmentId: string;
  patientName: string;
  doctorId: string;
  rating: number;
  comment: string | null;
  helpedWith: string | null;
  doctorReply: string | null;
  hidden: boolean;
  hiddenReason: string | null;
  createdAt: string;
  doctor: { id: string; name: string; specialization: string | null; image: string | null } | null;
}

export interface AdminReviewsResponse {
  summary: {
    average: number | null;
    total: number;
    hidden: number;
    lowRatings: number;
    replyRate: number | null;
    distribution: { stars: number; count: number }[];
  };
  reviews: AdminReview[];
  pagination: { page: number; total: number; totalPages: number };
}

export interface Announcement {
  id: string;
  title: string;
  message: string;
  audience: "all" | "patients" | "doctors";
  link: string | null;
  sentCount: number;
  readCount: number;
  sentByName: string;
  createdAt: string;
}

export interface ReportsResponse {
  range: { from: string; to: string; granularity: "day" | "week" | "month" };
  totals: {
    consultations: number;
    completed: number;
    cancelled: number;
    cancellationRate: number | null;
    revenue: number;
    discounts: number;
    tax: number;
    newPatients: number;
    newDoctors: number;
    averageRating: number | null;
  };
  consultations: { period: string; completed: number; cancelled: number; other: number }[];
  revenue: { period: string; revenue: number; discounts: number; tax: number }[];
  signups: { period: string; patients: number; doctors: number }[];
  specialties: { name: string; consultations: number; revenue: number }[];
  doctors: {
    id: string;
    name: string;
    specialization: string;
    consultations: number;
    completed: number;
    revenue: number;
    rating: number | null;
    ratings: number;
  }[];
  vouchers: { code: string; uses: number; discount: number }[];
  payouts: { requested: number; approved: number; paid: number; rejected: number };
}

export type BlogAccent = "lime" | "sky" | "amber" | "orange" | "rose" | "violet";

export interface BlogPost {
  id: string;
  slug: string;
  title: string;
  excerpt: string;
  content: string;
  category: string;
  image: string | null;
  accent: BlogAccent;
  authorName: string | null;
  published: boolean;
  publishedAt: string | null;
  createdAt: string;
  updatedAt: string;
}
