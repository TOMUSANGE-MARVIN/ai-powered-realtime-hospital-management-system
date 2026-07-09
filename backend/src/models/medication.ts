import mongoose, { Schema, Document } from "mongoose";

export interface IMedication extends Document {
  name: string;
  category: string;
  unit: string; // e.g. "tablet", "bottle", "vial"
  stock: number;
  reorderLevel: number;
  unitPrice: number; // in cents
  expiryDate?: Date;
  supplier?: string;
  createdAt: Date;
  updatedAt: Date;
}

const MedicationSchema = new Schema(
  {
    name: { type: String, required: true },
    category: { type: String, default: "General" },
    unit: { type: String, default: "tablet" },
    stock: { type: Number, default: 0 },
    reorderLevel: { type: Number, default: 10 },
    unitPrice: { type: Number, default: 0 },
    expiryDate: { type: Date },
    supplier: { type: String },
  },
  { timestamps: true },
);

export default mongoose.model<IMedication>("Medication", MedicationSchema);
