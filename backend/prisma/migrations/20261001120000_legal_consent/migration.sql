-- AlterTable
ALTER TABLE `user` ADD COLUMN `legalAcceptedVersion` VARCHAR(40) NULL;

-- CreateTable
CREATE TABLE `consent` (
    `id` VARCHAR(191) NOT NULL,
    `userId` VARCHAR(191) NOT NULL,
    `type` VARCHAR(20) NOT NULL,
    `version` VARCHAR(40) NOT NULL,
    `doctorId` VARCHAR(191) NULL,
    `paymentId` VARCHAR(191) NULL,
    `appointmentId` VARCHAR(191) NULL,
    `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),

    INDEX `consent_userId_type_idx`(`userId`, `type`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
