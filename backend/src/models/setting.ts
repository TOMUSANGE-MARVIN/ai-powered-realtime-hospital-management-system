import mongoose, { Schema, Document } from "mongoose";

export interface ISetting extends Document {
  key: string; // e.g. "general", "billing"
  data: Record<string, any>;
  updatedAt: Date;
}

const SettingSchema = new Schema(
  {
    key: { type: String, required: true, unique: true },
    data: { type: Schema.Types.Mixed, default: {} },
  },
  { timestamps: true },
);

export default mongoose.model<ISetting>("Setting", SettingSchema);
