-- AlterTable
ALTER TABLE `user` ADD COLUMN `yearsOfExperience` INTEGER NULL,
    ADD COLUMN `qualifications` TEXT NULL,
    ADD COLUMN `boardCertified` BOOLEAN NULL DEFAULT false,
    ADD COLUMN `treatments` TEXT NULL,
    ADD COLUMN `availabilityDays` TEXT NULL,
    ADD COLUMN `availabilityHours` TEXT NULL,
    ADD COLUMN `availableToday` BOOLEAN NULL DEFAULT false;
