-- AlterTable
ALTER TABLE `notification` MODIFY `type` ENUM('system', 'assignment', 'lab_result', 'alert', 'appointment', 'prescription', 'payment', 'review', 'payout') NOT NULL DEFAULT 'system';

-- CreateIndex
CREATE INDEX `notification_user_createdAt_idx` ON `notification`(`user`, `createdAt`);
