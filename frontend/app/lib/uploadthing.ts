import {
  generateUploadButton,
  generateUploadDropzone,
} from "@uploadthing/react";

const API_BASE = import.meta.env.VITE_API_URL || "http://localhost:5000";

export const UploadButton = generateUploadButton({
  url: `${API_BASE}/api/uploadthing`,
});
export const UploadDropzone = generateUploadDropzone({
  url: `${API_BASE}/api/uploadthing`,
});
