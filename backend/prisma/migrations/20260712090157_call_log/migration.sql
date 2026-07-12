-- CreateTable
CREATE TABLE `call_log` (
    `id` VARCHAR(191) NOT NULL,
    `callerId` VARCHAR(191) NOT NULL,
    `callerName` VARCHAR(191) NOT NULL,
    `calleeId` VARCHAR(191) NOT NULL,
    `calleeName` VARCHAR(191) NOT NULL,
    `type` VARCHAR(191) NOT NULL,
    `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),

    INDEX `call_log_callerId_idx`(`callerId`),
    INDEX `call_log_calleeId_idx`(`calleeId`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
