import mongoose, { Schema, Document } from "mongoose";

export interface IFeedback extends Document {
  userId: string;
  userName: string;
  category: "bug" | "feature" | "general";
  message: string;
  rating?: number;
  createdAt: Date;
}

const FeedbackSchema = new Schema(
  {
    userId: { type: String, required: true },
    userName: { type: String, required: true },
    category: {
      type: String,
      enum: ["bug", "feature", "general"],
      default: "general",
    },
    message: { type: String, required: true },
    rating: { type: Number, min: 1, max: 5 },
  },
  { timestamps: true },
);

export default mongoose.model<IFeedback>("Feedback", FeedbackSchema);
