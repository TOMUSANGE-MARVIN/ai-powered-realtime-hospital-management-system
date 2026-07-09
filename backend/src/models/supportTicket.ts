import mongoose, { Schema, Document } from "mongoose";

export interface ISupportTicket extends Document {
  userId: string;
  userName: string;
  subject: string;
  message: string;
  priority: "low" | "medium" | "high";
  status: "open" | "in_progress" | "resolved";
  createdAt: Date;
  updatedAt: Date;
}

const SupportTicketSchema = new Schema(
  {
    userId: { type: String, required: true },
    userName: { type: String, required: true },
    subject: { type: String, required: true },
    message: { type: String, required: true },
    priority: {
      type: String,
      enum: ["low", "medium", "high"],
      default: "medium",
    },
    status: {
      type: String,
      enum: ["open", "in_progress", "resolved"],
      default: "open",
    },
  },
  { timestamps: true },
);

export default mongoose.model<ISupportTicket>(
  "SupportTicket",
  SupportTicketSchema,
);
