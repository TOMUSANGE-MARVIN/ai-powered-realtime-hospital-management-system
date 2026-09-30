-- AlterTable
ALTER TABLE `appointment` ADD COLUMN `cancellationReason` TEXT NULL,
    ADD COLUMN `cancelledBy` VARCHAR(191) NULL;
