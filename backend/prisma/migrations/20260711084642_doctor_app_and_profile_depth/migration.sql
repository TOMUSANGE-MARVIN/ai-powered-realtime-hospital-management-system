-- AlterTable
ALTER TABLE `appointment` ADD COLUMN `fee` INTEGER NULL;

-- AlterTable
ALTER TABLE `prescription` ADD COLUMN `imageUrl` TEXT NULL,
    ADD COLUMN `signatureUrl` TEXT NULL;

-- AlterTable
ALTER TABLE `user` ADD COLUMN `bio` TEXT NULL,
    ADD COLUMN `consultationFee` INTEGER NULL,
    ADD COLUMN `emergencyContactName` TEXT NULL,
    ADD COLUMN `emergencyContactPhone` TEXT NULL,
    ADD COLUMN `emergencyContactRelation` TEXT NULL,
    ADD COLUMN `hospitalAddress` TEXT NULL,
    ADD COLUMN `hospitalName` TEXT NULL;

-- CreateTable
CREATE TABLE `medical_document` (
    `id` VARCHAR(191) NOT NULL,
    `patientId` VARCHAR(191) NOT NULL,
    `title` VARCHAR(191) NOT NULL,
    `url` TEXT NOT NULL,
    `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),

    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
