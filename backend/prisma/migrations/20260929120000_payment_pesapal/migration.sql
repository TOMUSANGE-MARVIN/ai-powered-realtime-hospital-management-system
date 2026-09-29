-- AlterTable
ALTER TABLE `payment` ADD COLUMN `orderTrackingId` VARCHAR(191) NULL;

-- CreateIndex
CREATE UNIQUE INDEX `payment_orderTrackingId_key` ON `payment`(`orderTrackingId`);
