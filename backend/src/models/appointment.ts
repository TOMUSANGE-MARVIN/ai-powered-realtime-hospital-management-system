import mongoose, { Schema, Document } from "mongoose";

export interface IAppointment extends Document {
  patientId?: string;
  patientName: string;
  patientEmail?: string;
  patientPhone?: string;
  doctorId?: string;
  doctorName?: string;
  nurseId?: string;
  department?: string;
  date: Date;
  time?: string;
  reason?: string;
  status:
    | "requested"
    | "scheduled"
    | "confirmed"
    | "completed"
    | "cancelled"
    | "in-progress";
  isVirtual: boolean;
  meetingId?: string;
  notes?: string;
  createdAt: Date;
  updatedAt: Date;
}

const AppointmentSchema = new Schema(
  {
    patientId: { type: String },
    patientName: { type: String, required: true },
    patientEmail: { type: String },
    patientPhone: { type: String },
    doctorId: { type: String },
    doctorName: { type: String },
    nurseId: { type: String },
    department: { type: String },
    date: { type: Date, required: true },
    time: { type: String },
    reason: { type: String },
    status: {
      type: String,
      enum: [
        "requested",
        "scheduled",
        "confirmed",
        "completed",
        "cancelled",
        "in-progress",
      ],
      default: "requested",
    },
    isVirtual: { type: Boolean, default: false },
    meetingId: { type: String },
    notes: { type: String },
  },
  { timestamps: true },
);

export default mongoose.model<IAppointment>("Appointment", AppointmentSchema);
