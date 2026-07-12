-- AlterTable
ALTER TABLE `message` ADD COLUMN `replyToAttachmentType` VARCHAR(191) NULL,
    ADD COLUMN `replyToId` VARCHAR(191) NULL,
    ADD COLUMN `replyToSenderId` VARCHAR(191) NULL,
    ADD COLUMN `replyToText` TEXT NULL;
