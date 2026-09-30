-- AlterTable
ALTER TABLE `appointment` ADD COLUMN `proposedDate` DATETIME(3) NULL,
    ADD COLUMN `proposedTime` VARCHAR(191) NULL,
    MODIFY `status` ENUM('requested', 'scheduled', 'confirmed', 'completed', 'cancelled', 'in_progress', 'no_show') NOT NULL DEFAULT 'requested';

-- CreateTable
CREATE TABLE `doctor_time_off` (
    `id` VARCHAR(191) NOT NULL,
    `doctorId` VARCHAR(191) NOT NULL,
    `startDate` DATETIME(3) NOT NULL,
    `endDate` DATETIME(3) NOT NULL,
    `reason` VARCHAR(191) NULL,
    `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),

INDEX `doctor_time_off_doctorId_endDate_idx`(`doctorId`, `endDate`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
