-- AlterTable
ALTER TABLE `message` ADD COLUMN `attachmentName` VARCHAR(191) NULL,
    ADD COLUMN `attachmentType` VARCHAR(191) NULL,
    ADD COLUMN `attachmentUrl` TEXT NULL,
    ADD COLUMN `deletedAt` DATETIME(3) NULL;
