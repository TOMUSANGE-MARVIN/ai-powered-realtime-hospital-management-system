import { betterAuth } from "better-auth";
import { prismaAdapter } from "better-auth/adapters/prisma";
import { admin } from "better-auth/plugins";
import {
  polar,
  checkout,
  portal,
  usage,
  webhooks,
} from "@polar-sh/better-auth";
import { Polar } from "@polar-sh/sdk";
import { prisma } from "./prisma";

export const polarClient = new Polar({
  accessToken: process.env.POLAR_ACCESS_TOKEN,
  // Use 'sandbox' if you're using the Polar Sandbox environment
  // Remember that access tokens, products, etc. are completely separated between environments.
  // Access tokens obtained in Production are for instance not usable in the Sandbox environment.
  server: "sandbox",
});

export const auth = betterAuth({
  database: prismaAdapter(prisma, { provider: "mysql" }),
  baseURL: process.env.BETTER_AUTH_URL || "http://localhost:5000",
  // if you comment this out, thunder client will be able to create user, but let add origin on thunder client to test it out
  // "askmusawo://mobile" is a synthetic origin for the Flutter app — native
  // HTTP clients don't have a real browser origin, so the app sends this as
  // a static Origin header (see mobile/lib/core/api/api_client.dart) to
  // satisfy better-auth's origin-check middleware, which otherwise rejects
  // any cookie-bearing request (including the sign-in request itself, once
  // a session cookie already exists in the app's persisted cookie jar) that
  // arrives without a recognized Origin header.
  trustedOrigins: [
    process.env.FRONTEND_URL || "http://localhost:5173",
    "askmusawo://mobile",
  ],
  emailAndPassword: { enabled: true },
  plugins: [
    admin({
      defaultRole: "patient",
      // but we are going to work without it since will have a middleware to check permissions based on the role in the session
      adminRole: ["admin", "superadmin"],
    }),
    polar({
      client: polarClient,
      createCustomerOnSignUp: !!process.env.POLAR_ACCESS_TOKEN,
      use: [
        checkout({
          authenticatedUsersOnly: true,
        }),
        portal({
          returnUrl: `${process.env.FRONTEND_URL}/dashboard`,
        }),
        usage(),
        webhooks({
          secret: process.env.POLAR_WEBHOOK_SECRET!,
          onPayload: async ({ data, type }) => {
            // console.log("Received Polar webhook:", type, data);
            if (type === "order.paid" && data.paid) {
              const invoiceId = data.metadata?.hospitalInvoiceId;
              if (invoiceId) {
                await prisma.invoice.update({
                  where: { id: invoiceId as string },
                  data: { status: "paid" },
                });
                console.log(
                  `✅ Invoice ${invoiceId} marked as PAID via Polar!`,
                );
              }
            }
          },
        }),
      ],
    }),
  ],
  user: {
    additionalFields: {
      specialization: {
        type: "string",
        required: false, // Only for doctors
      },
      department: {
        type: "string",
        required: false,
      },
      gender: {
        type: "string",
        required: false,
      },
      bloodgroup: {
        type: "string",
        required: false,
      },
      maritalStatus: {
        type: "string",
        required: false,
      },
      medicalHistory: {
        type: "string",
        required: false,
      },
      age: {
        type: "string",
        required: false,
      },
      status: {
        type: "string",
        required: false,
        defaultValue: "active",
      },
      admissionReason: {
        type: "string",
        required: false,
      },
      assignedDoctorId: {
        type: "string",
        required: false,
      },
      assignedDoctorName: {
        type: "string",
        required: false,
      },
      assignedNurseId: {
        type: "string",
        required: false,
      },
      assignedNurseName: {
        type: "string",
        required: false,
      },
      triageReasoning: {
        type: "string",
        required: false,
      },
      bio: {
        type: "string",
        required: false,
      },
      hospitalName: {
        type: "string",
        required: false,
      },
      hospitalAddress: {
        type: "string",
        required: false,
      },
      consultationFee: {
        type: "number",
        required: false,
      },
      emergencyContactName: {
        type: "string",
        required: false,
      },
      emergencyContactPhone: {
        type: "string",
        required: false,
      },
      emergencyContactRelation: {
        type: "string",
        required: false,
      },
    },
  },
});

// more advanced example with role-based access control using the admin plugin
// admin({
//       defaultRole: "patient",
//       // Define the authorized roles for the admin plugin
//       // This allows you to use authClient.admin.setRole() etc.
//       adminRole: ["admin", "superadmin"],

//       // Fine-grained permissions (Statements)
//       // This is helpful if you use auth.api.checkPermission() in your backend
//       roles: {
//         admin: {
//           statements: [{ resource: "all", action: "all" }]
//         },
//         doctor: {
//           statements: [
//             { resource: "patient", action: "read" },
//             { resource: "patient", action: "update" },
//             { resource: "lab_results", action: "all" },
//             { resource: "prescriptions", action: "all" }
//           ]
//         },
//         nurse: {
//           statements: [
//             { resource: "patient", action: "read" },
//             { resource: "vitals", action: "create" },
//             { resource: "lab_results", action: "read" }
//           ]
//         },
//         pharmacist: {
//           statements: [
//             { resource: "prescriptions", action: "read" },
//             { resource: "billing", action: "all" }
//           ]
//         },
//         lab_tech: {
//           statements: [
//             { resource: "lab_results", action: "create" },
//             { resource: "lab_results", action: "update" }
//           ]
//         },
//         patient: {
//           statements: [
//             { resource: "my_profile", action: "read" },
//             { resource: "my_billing", action: "read" }
//           ]
//         }
//       }
//     })
