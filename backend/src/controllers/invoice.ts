import type { Request, Response } from "express";
import { fromNodeHeaders } from "better-auth/node";
import { prisma } from "../lib/prisma";
import { auth, polarClient } from "../lib/auth";

export const getMyActiveInvoice = async (req: Request, res: Response) => {
  try {
    // 1. Get the current user from the session (populated by your requireAuth middleware)
    const currentUserId = (req as any).user.id;

    // 2. Find an active invoice for this specific patient
    // We look for 'draft' (still accumulating charges) or 'pending_payment' (ready to checkout)
    const activeInvoice = await prisma.invoice.findFirst({
      where: {
        patientId: currentUserId,
        status: { in: ["draft", "pending_payment"] },
      },
      include: { items: true },
    });
    // 3. Return 404 if no bill exists
    if (!activeInvoice) {
      return res.status(404).json({ message: "No active invoice found" });
    }
    // 4. Return the invoice data
    res.status(200).json(activeInvoice);
  } catch (error) {
    console.log(error);
    res.status(500).json({ message: "Internal server error" });
  }
};

// get billing history(you can remove status if you want to fetch all invoices)
export const getBillingHistory = async (req: Request, res: Response) => {
  try {
    const currentUserId = (req as any).user.id;
    const activeInvoice = await prisma.invoice.findMany({
      where: { patientId: currentUserId, status: "paid" },
      include: { items: true },
    });
    res.status(200).json(activeInvoice);
  } catch (error) {
    console.log(error);
    res.status(500).json({ message: "Internal server error" });
  }
};

export const allBilling = async (req: Request, res: Response) => {
  try {
    const page = Number(req.query.page) || 1;
    const limit = Number(req.query.limit) || 10;
    const skip = (page - 1) * limit;

    const [count, billings] = await Promise.all([
      prisma.invoice.count(),
      prisma.invoice.findMany({
        orderBy: { createdAt: "desc" },
        skip,
        take: limit,
        include: { items: true },
      }),
    ]);

    const users = await prisma.user.findMany({
      where: { role: "patient" },
      omit: { emailVerified: true },
    });

    // Create a Lookup Map for instant access
    const userMap = new Map(users.map((user) => [user.id, user]));

    const billingsWithUser = billings.map((billing) => ({
      ...billing,
      user: userMap.get(billing.patientId) || null,
    }));

    res.json({
      res: billingsWithUser,
      pagination: {
        currentPage: page,
        totalPages: Math.ceil(count / limit),
        totalData: count,
        limit,
      },
    });
  } catch (error) {
    console.error("Error fetching billing history:", error);
    res.status(500).json({ message: "Failed to fetch billing history" });
  }
};

export const createCheckoutSession = async (req: Request, res: Response) => {
  const id = req.params.id as string;
  try {
    // 1. Fetch the unique invoice from your database
    const userInvoice = await prisma.invoice.findUnique({ where: { id } });
    if (!userInvoice || userInvoice.status === "paid") {
      return res
        .status(400)
        .json({ message: "Invalid or already paid invoice" });
    }

    // 2. CREATE CHECKOUT USING THE POLAR SDK
    const session = await auth.api.getSession({
      headers: fromNodeHeaders(req.headers),
    });

    if (!session) {
      return res.status(401).json({ message: "Unauthorized" });
    }

    const checkout = await polarClient.checkouts.create({
      externalCustomerId: session.user.id, // Link the checkout to the authenticated user
      products: [process.env.POLAR_PRODUCT_ID!],
      prices: {
        [process.env.POLAR_PRODUCT_ID!]: [
          {
            amountType: "fixed",
            priceAmount: userInvoice.totalAmount, // e.g. 15000 = $150.00 (in cents)
            priceCurrency: "usd",
          },
        ],
      },
      metadata: {
        hospitalInvoiceId: userInvoice.id,
        patientId: userInvoice.patientId,
      },
      // Where to redirect after success
      successUrl: `${process.env.FRONTEND_URL}/profile/${userInvoice.patientId}?checkout_id={CHECKOUT_ID}`,
      returnUrl: `${process.env.FRONTEND_URL}/profile/${userInvoice.patientId}`,
    });

    // Save checkout ID to the DB
    await prisma.invoice.update({
      where: { id: userInvoice.id },
      data: { status: "pending_payment", polarCheckoutId: checkout.id },
    });

    // Return the checkout URL to the frontend
    res.json({ checkoutUrl: checkout.url });
  } catch (error) {
    console.error("Polar Checkout Error:", error);
    res.status(500).json({ error: "Failed to generate payment link" });
  }
};
