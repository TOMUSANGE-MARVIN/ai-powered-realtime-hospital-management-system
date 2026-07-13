-- AlterTable
ALTER TABLE `call_log` ADD COLUMN `durationSeconds` INTEGER NULL,
    ADD COLUMN `status` VARCHAR(191) NOT NULL DEFAULT 'answered';
