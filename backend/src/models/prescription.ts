import mongoose, { Schema, Document } from "mongoose";

export interface IPrescriptionItem {
  medication: mongoose.Types.ObjectId;
  medicationName: string;
  dosage: string;
  quantity: number;
  instructions?: string;
}

export interface IPrescription extends Document {
  patient: mongoose.Types.ObjectId;
  doctor: mongoose.Types.ObjectId;
  doctorName: string;
  patientName: string;
  items: IPrescriptionItem[];
  status: "pending" | "dispensed" | "cancelled";
  dispensedBy?: string;
  dispensedAt?: Date;
  notes?: string;
  createdAt: Date;
  updatedAt: Date;
}

const PrescriptionSchema = new Schema(
  {
    patient: { type: Schema.Types.ObjectId, ref: "user", required: true },
    doctor: { type: Schema.Types.ObjectId, ref: "user", required: true },
    doctorName: { type: String, required: true },
    patientName: { type: String, required: true },
    items: [
      {
        medication: { type: Schema.Types.ObjectId, ref: "Medication" },
        medicationName: { type: String, required: true },
        dosage: { type: String, required: true },
        quantity: { type: Number, required: true, default: 1 },
        instructions: { type: String },
      },
    ],
    status: {
      type: String,
      enum: ["pending", "dispensed", "cancelled"],
      default: "pending",
    },
    dispensedBy: { type: String },
    dispensedAt: { type: Date },
    notes: { type: String },
  },
  { timestamps: true },
);

export default mongoose.model<IPrescription>(
  "Prescription",
  PrescriptionSchema,
);
