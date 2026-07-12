-- AlterTable
ALTER TABLE `review` ADD COLUMN `doctorRepliedAt` DATETIME(3) NULL,
    ADD COLUMN `doctorReply` TEXT NULL;
