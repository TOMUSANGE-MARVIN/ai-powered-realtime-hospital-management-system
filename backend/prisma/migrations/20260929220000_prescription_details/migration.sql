-- AlterTable
ALTER TABLE `prescription` ADD COLUMN `appointmentId` VARCHAR(191) NULL,
    ADD COLUMN `licenseNo` VARCHAR(191) NULL,
    ADD COLUMN `dateIssued` VARCHAR(191) NULL;
