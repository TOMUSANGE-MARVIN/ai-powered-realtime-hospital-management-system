-- CreateTable
CREATE TABLE `record_access` (
    `id` VARCHAR(191) NOT NULL,
    `patientId` VARCHAR(191) NOT NULL,
    `viewerId` VARCHAR(191) NOT NULL,
    `viewerName` VARCHAR(191) NOT NULL,
    `viewerRole` VARCHAR(30) NOT NULL,
    `resource` VARCHAR(30) NOT NULL,
    `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),

    INDEX `record_access_patientId_createdAt_idx`(`patientId`, `createdAt`),
    INDEX `record_access_viewerId_createdAt_idx`(`viewerId`, `createdAt`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
