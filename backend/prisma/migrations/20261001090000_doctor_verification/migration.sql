-- AlterTable
ALTER TABLE `user` ADD COLUMN `doctorVerificationStatus` VARCHAR(20) NULL,
    ADD COLUMN `licenseNumber` TEXT NULL,
    ADD COLUMN `licenseDocumentUrl` TEXT NULL,
    ADD COLUMN `verificationSubmittedAt` DATETIME(3) NULL,
    ADD COLUMN `verificationReviewedAt` DATETIME(3) NULL,
    ADD COLUMN `verificationReviewedBy` TEXT NULL,
    ADD COLUMN `verificationNote` TEXT NULL;

-- Doctors that exist before verification launched are approved as they are
-- (decided 2026-09-30); admins can still review them later.
UPDATE `user`
SET `doctorVerificationStatus` = 'approved',
    `verificationReviewedAt` = CURRENT_TIMESTAMP(3),
    `verificationNote` = 'Approved automatically when licence verification launched'
WHERE `role` = 'doctor';
