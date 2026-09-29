-- AlterTable
ALTER TABLE `payment` ADD COLUMN `refundStatus` VARCHAR(191) NULL,
    ADD COLUMN `refundAmount` INTEGER NULL,
    ADD COLUMN `refundReason` TEXT NULL,
    ADD COLUMN `refundRequestedAt` DATETIME(3) NULL,
    ADD COLUMN `refundRequestedBy` VARCHAR(191) NULL;
