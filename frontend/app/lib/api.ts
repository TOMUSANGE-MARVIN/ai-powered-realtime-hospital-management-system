import type {
  PaginatedResponse,
  Role,
  User,
  LabResult,
  WebPushSubscription,
  ActivityLog,
  invoice,
  appointment,
  Medication,
  Prescription,
  SupportTicket,
  Feedback,
} from "@/types";

export const API_URL = `${import.meta.env.VITE_API_URL || "http://localhost:5000"}/api`;

export const getUsers = async (params: {
  role: Role;
  page?: number;
  limit?: number;
}): Promise<PaginatedResponse<User>> => {
  const query = new URLSearchParams({
    role: params.role,
    page: (params.page || 1).toString(),
    limit: (params.limit || 10).toString(),
  }).toString();

  const res = await fetch(`${API_URL}/users?${query}`, {
    credentials: "include", // Important for Better Auth cookies
  });

  if (!res.ok) throw new Error("Failed");

  return res.json();
};

export const triggerAdmission = async ({
  patientId,
  admissionReason,
}: {
  patientId: string;
  admissionReason: string;
}) => {
  // /:id/admit
  const res = await fetch(`${API_URL}/users/${patientId}/admit`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ admissionReason }),
    credentials: "include",
  });
  if (!res.ok) throw new Error("Failed to start admission process");
  return res.json();
};

interface UpdateUserParams {
  userId: string;
  userData: Partial<User> & Record<string, any>; // Allow custom fields
}

// /update/:id
export const updateUser = async ({ userId, userData }: UpdateUserParams) => {
  const res = await fetch(`${API_URL}/users/update/${userId}`, {
    method: "PUT",
    headers: {
      "Content-Type": "application/json",
    },
    body: JSON.stringify(userData),
    credentials: "include", // Important for Better Auth cookies
  });

  if (!res.ok) {
    const error = await res.json();
    throw new Error(error.message || "Failed to update user");
  }

  return res.json();
};

export const createActityLog = async (data: {
  userId: string;
  action: string;
  details?: string;
}) => {
  const res = await fetch(`${API_URL}/activity-logs/create`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(data),
    credentials: "include", // Important for Better Auth cookies
  });
  if (!res.ok) throw new Error("Failed to create activity log");
  return res.json();
};

export const getPatientLabResults = async (
  patientId: string,
): Promise<LabResult[]> => {
  const res = await fetch(`${API_URL}/lab-results/patient/${patientId}`, {
    method: "GET",
    credentials: "include",
  });
  if (!res.ok) throw new Error("Failed to fetch lab results");
  return res.json();
};

export const updateLabResult = async ({
  id,
  data,
}: {
  id: string;
  data: { doctorNotes?: string; status?: string };
}) => {
  const res = await fetch(`${API_URL}/lab-results/${id}`, {
    method: "PUT",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(data),
    credentials: "include",
  });
  if (!res.ok) throw new Error("Failed to update lab result");
  return res.json();
};

export const createLabResult = async (data: {
  patientId: string;
  testType: string;
  bodyPart: string;
  imageUrl: string;
  aiAnalysis?: string;
}) => {
  const res = await fetch(`${API_URL}/lab-results`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
    },
    body: JSON.stringify(data),
    credentials: "include", // Important for Better Auth cookies
  });

  if (!res.ok) {
    const error = await res.json();
    throw new Error(error.message || "Failed to create lab result");
  }

  return res.json();
};

export const deleteFile = async ({ file }: { file: string }) => {
  const res = await fetch(`${API_URL}/uploadthing/delete`, {
    method: "DELETE",
    headers: {
      "Content-Type": "application/json",
    },
    body: JSON.stringify({ fileUrl: file }),
    credentials: "include", // Important for Better Auth cookies
  });

  if (!res.ok) {
    const error = await res.json();
    throw new Error(error.message || "Failed to delete file");
  }

  return res.json();
};

export const getActivityLogs = async (params: {
  page?: number;
  limit?: number;
}): Promise<PaginatedResponse<ActivityLog>> => {
  const query = new URLSearchParams({
    page: (params.page || 1).toString(),
    limit: (params.limit || 10).toString(),
  }).toString();

  const res = await fetch(`${API_URL}/activity-logs?${query}`, {
    credentials: "include", // Important for Better Auth cookies
  });

  if (!res.ok) throw new Error("Failed to fetch activity logs");

  return res.json();
};

export const getUserById = async (userId: string) => {
  const res = await fetch(`${API_URL}/users/profile/${userId}`, {
    credentials: "include",
  });
  if (!res.ok) throw new Error("Failed to fetch user");
  return res.json();
};

export const getMyActiveInvoice = async () => {
  const res = await fetch(`${API_URL}/invoices/my-active-invoice`, {
    credentials: "include",
  });
  if (!res.ok) {
    if (res.status === 404) return null; // No active invoice
    throw new Error("Failed to fetch invoice");
  }
  return res.json();
};

export const createCheckoutSession = async (invoiceId: string) => {
  const res = await fetch(`${API_URL}/invoices/${invoiceId}/checkout`, {
    method: "POST",
    credentials: "include",
  });
  if (!res.ok) throw new Error("Failed to initiate checkout");
  return res.json();
};

export const getBillingHistory = async (userId: string) => {
  const res = await fetch(`${API_URL}/invoices/history/${userId}`, {
    credentials: "include",
  });
  if (!res.ok) throw new Error("Failed to fetch billing history");
  return res.json();
};

export const getAllInvoices = async (data?: {
  page?: number;
  limit?: number;
}): Promise<PaginatedResponse<invoice>> => {
  const res = await fetch(`${API_URL}/invoices`, {
    credentials: "include",
    body: JSON.stringify(data),
  });
  if (!res.ok) throw new Error("Failed to fetch invoices");
  return res.json();
};

export const polarPortalLink = async (userId: string) => {
  const res = await fetch(`${API_URL}/users/polar-portal/${userId}`, {
    method: "GET",
    credentials: "include",
  });
  if (!res.ok) throw new Error("Failed to fetch polar portal link");
  return res.json();
};

export const fetchNotifications = async () => {
  const res = await fetch(`${API_URL}/notifications`, {
    credentials: "include",
  });
  if (!res.ok) throw new Error("Failed to fetch notifications");
  return res.json(); // Expected response: { notifications:[], unreadCount: 0 }
};

export const markAsRead = async (id: string) => {
  const res = await fetch(`${API_URL}/notifications/${id}/read`, {
    method: "POST",
    credentials: "include",
  });
  if (!res.ok) throw new Error("Failed to mark as read");
  return res.json();
};

// --- Lab results (global list, used by Lab Requests / Results Entry) ---

export const getAllLabResults = async (params?: {
  status?: string;
  page?: number;
  limit?: number;
}): Promise<PaginatedResponse<LabResult & { patientName: string }>> => {
  const query = new URLSearchParams({
    status: params?.status || "all",
    page: (params?.page || 1).toString(),
    limit: (params?.limit || 20).toString(),
  }).toString();
  const res = await fetch(`${API_URL}/lab-results?${query}`, {
    credentials: "include",
  });
  if (!res.ok) throw new Error("Failed to fetch lab results");
  return res.json();
};

// --- Pharmacy: Medications (inventory) ---

export const getMedications = async (params?: {
  search?: string;
  page?: number;
  limit?: number;
}): Promise<PaginatedResponse<Medication>> => {
  const query = new URLSearchParams({
    search: params?.search || "",
    page: (params?.page || 1).toString(),
    limit: (params?.limit || 20).toString(),
  }).toString();
  const res = await fetch(`${API_URL}/medications?${query}`, {
    credentials: "include",
  });
  if (!res.ok) throw new Error("Failed to fetch medications");
  return res.json();
};

export const createMedication = async (data: Partial<Medication>) => {
  const res = await fetch(`${API_URL}/medications`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(data),
    credentials: "include",
  });
  if (!res.ok) throw new Error("Failed to add medication");
  return res.json();
};

export const updateMedication = async ({
  id,
  data,
}: {
  id: string;
  data: Partial<Medication>;
}) => {
  const res = await fetch(`${API_URL}/medications/${id}`, {
    method: "PUT",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(data),
    credentials: "include",
  });
  if (!res.ok) throw new Error("Failed to update medication");
  return res.json();
};

export const deleteMedication = async (id: string) => {
  const res = await fetch(`${API_URL}/medications/${id}`, {
    method: "DELETE",
    credentials: "include",
  });
  if (!res.ok) throw new Error("Failed to delete medication");
  return res.json();
};

// --- Pharmacy: Prescriptions ---

export const getPrescriptions = async (params?: {
  status?: string;
  page?: number;
  limit?: number;
}): Promise<PaginatedResponse<Prescription>> => {
  const query = new URLSearchParams({
    status: params?.status || "all",
    page: (params?.page || 1).toString(),
    limit: (params?.limit || 20).toString(),
  }).toString();
  const res = await fetch(`${API_URL}/prescriptions?${query}`, {
    credentials: "include",
  });
  if (!res.ok) throw new Error("Failed to fetch prescriptions");
  return res.json();
};

export const createPrescription = async (data: {
  patient: string;
  patientName: string;
  items: Prescription["items"];
  notes?: string;
}) => {
  const res = await fetch(`${API_URL}/prescriptions`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(data),
    credentials: "include",
  });
  if (!res.ok) throw new Error("Failed to create prescription");
  return res.json();
};

export const dispensePrescription = async (id: string) => {
  const res = await fetch(`${API_URL}/prescriptions/${id}/dispense`, {
    method: "POST",
    credentials: "include",
  });
  if (!res.ok) {
    const error = await res.json();
    throw new Error(error.message || "Failed to dispense prescription");
  }
  return res.json();
};

export const cancelPrescription = async (id: string) => {
  const res = await fetch(`${API_URL}/prescriptions/${id}/cancel`, {
    method: "POST",
    credentials: "include",
  });
  if (!res.ok) throw new Error("Failed to cancel prescription");
  return res.json();
};

// --- Appointments ---

export const requestAppointment = async (data: {
  patientName: string;
  patientEmail: string;
  patientPhone?: string;
  department: string;
  date: string;
  time?: string;
  reason?: string;
}) => {
  const res = await fetch(`${API_URL}/appointments/request`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(data),
  });
  if (!res.ok) throw new Error("Failed to submit appointment request");
  return res.json();
};

export const getAppointments = async (params?: {
  status?: string;
  isVirtual?: boolean;
  page?: number;
  limit?: number;
}): Promise<PaginatedResponse<appointment>> => {
  const query = new URLSearchParams({
    status: params?.status || "all",
    ...(params?.isVirtual ? { isVirtual: "true" } : {}),
    page: (params?.page || 1).toString(),
    limit: (params?.limit || 20).toString(),
  }).toString();
  const res = await fetch(`${API_URL}/appointments?${query}`, {
    credentials: "include",
  });
  if (!res.ok) throw new Error("Failed to fetch appointments");
  return res.json();
};

export const createAppointment = async (data: Partial<appointment>) => {
  const res = await fetch(`${API_URL}/appointments`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(data),
    credentials: "include",
  });
  if (!res.ok) throw new Error("Failed to create appointment");
  return res.json();
};

export const updateAppointment = async ({
  id,
  data,
}: {
  id: string;
  data: Partial<appointment>;
}) => {
  const res = await fetch(`${API_URL}/appointments/${id}`, {
    method: "PUT",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(data),
    credentials: "include",
  });
  if (!res.ok) throw new Error("Failed to update appointment");
  return res.json();
};

// --- Settings ---

export const getSetting = async (
  key: string,
): Promise<{ key: string; data: Record<string, any> }> => {
  const res = await fetch(`${API_URL}/settings/${key}`, {
    credentials: "include",
  });
  if (!res.ok) throw new Error("Failed to fetch settings");
  return res.json();
};

export const updateSetting = async ({
  key,
  data,
}: {
  key: string;
  data: Record<string, any>;
}) => {
  const res = await fetch(`${API_URL}/settings/${key}`, {
    method: "PUT",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ data }),
    credentials: "include",
  });
  if (!res.ok) throw new Error("Failed to update settings");
  return res.json();
};

// --- Support & Feedback ---

export const getSupportTickets = async (): Promise<SupportTicket[]> => {
  const res = await fetch(`${API_URL}/support/tickets`, {
    credentials: "include",
  });
  if (!res.ok) throw new Error("Failed to fetch support tickets");
  return res.json();
};

export const createSupportTicket = async (data: {
  subject: string;
  message: string;
  priority?: string;
}) => {
  const res = await fetch(`${API_URL}/support/tickets`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(data),
    credentials: "include",
  });
  if (!res.ok) throw new Error("Failed to submit ticket");
  return res.json();
};

export const updateSupportTicketStatus = async ({
  id,
  status,
}: {
  id: string;
  status: string;
}) => {
  const res = await fetch(`${API_URL}/support/tickets/${id}`, {
    method: "PUT",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ status }),
    credentials: "include",
  });
  if (!res.ok) throw new Error("Failed to update ticket");
  return res.json();
};

export const getFeedbackList = async (): Promise<Feedback[]> => {
  const res = await fetch(`${API_URL}/support/feedback`, {
    credentials: "include",
  });
  if (!res.ok) throw new Error("Failed to fetch feedback");
  return res.json();
};

export const createFeedback = async (data: {
  category: string;
  message: string;
  rating?: number;
}) => {
  const res = await fetch(`${API_URL}/support/feedback`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(data),
    credentials: "include",
  });
  if (!res.ok) throw new Error("Failed to submit feedback");
  return res.json();
};
