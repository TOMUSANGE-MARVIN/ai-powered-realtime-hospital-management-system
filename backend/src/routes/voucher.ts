import { Router } from "express";
import { requireAuth } from "../middleware/auth";
import { checkRole } from "../middleware/checkRole";
import {
  createVoucher,
  listVouchers,
  updateVoucher,
  validateVoucher,
} from "../controllers/voucher";

const voucherRouter = Router();

voucherRouter.post("/validate", requireAuth, checkRole(["patient"]), validateVoucher);
voucherRouter.get("/", requireAuth, checkRole(["admin"]), listVouchers);
voucherRouter.post("/", requireAuth, checkRole(["admin"]), createVoucher);
voucherRouter.patch("/:id", requireAuth, checkRole(["admin"]), updateVoucher);

export default voucherRouter;
