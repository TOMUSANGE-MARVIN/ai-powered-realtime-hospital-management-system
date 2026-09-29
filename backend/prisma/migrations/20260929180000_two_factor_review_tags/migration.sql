-- AlterTable
ALTER TABLE `user` ADD COLUMN `twoFactorEnabled` BOOLEAN NULL DEFAULT false;

-- AlterTable
ALTER TABLE `review` ADD COLUMN `helpedWith` TEXT NULL;

-- CreateTable
CREATE TABLE `twoFactor` (
    `id` VARCHAR(191) NOT NULL,
    `secret` TEXT NOT NULL,
    `backupCodes` TEXT NOT NULL,
    `userId` VARCHAR(191) NOT NULL,
    `verified` BOOLEAN NULL DEFAULT true,
    `failedVerificationCount` INTEGER NULL DEFAULT 0,
    `lockedUntil` DATETIME(3) NULL,

    INDEX `twoFactor_userId_idx`(`userId`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- AddForeignKey
ALTER TABLE `twoFactor` ADD CONSTRAINT `twoFactor_userId_fkey` FOREIGN KEY (`userId`) REFERENCES `user`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;
