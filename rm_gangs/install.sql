CREATE TABLE IF NOT EXISTS `rm_gangs_wars` (
    `id` INT(11) NOT NULL AUTO_INCREMENT,
    `initiator` VARCHAR(50) NULL DEFAULT NULL,
    `target` VARCHAR(50) NULL DEFAULT NULL,
    `initiatorIdentifier` VARCHAR(50) NULL DEFAULT NULL,
    `targetIdentifier` VARCHAR(50) NULL DEFAULT NULL,
    `initiatorScore` INT(10) NULL DEFAULT '0',
    `targetScore` INT(10) NULL DEFAULT '0',
    `killGoal` INT(10) NULL DEFAULT '15',
    `wager` INT(10) NULL DEFAULT '250',
    `accepted` TINYINT(2) NULL DEFAULT NULL,
    `cancelled` TINYINT(2) NULL DEFAULT NULL,
    `surrendered` TINYINT(2) NULL DEFAULT NULL,
    `declareDate` TIMESTAMP NULL DEFAULT current_timestamp(),
    `acceptRejectDate` TIMESTAMP NULL DEFAULT NULL,
    `finishDate` TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET='utf8mb4' COLLATE='utf8mb4_unicode_ci';

CREATE TABLE IF NOT EXISTS `rm_gangs_tribute_zone_bans` (
    `id` INT(11) NOT NULL AUTO_INCREMENT,
    `gang_name` VARCHAR(50) NOT NULL,
    `banned_until` TIMESTAMP NOT NULL,
    `reason` VARCHAR(255) NULL DEFAULT NULL,
    `banned_by` VARCHAR(100) NULL DEFAULT NULL,
    `banned_date` TIMESTAMP NULL DEFAULT current_timestamp(),
    PRIMARY KEY (`id`),
    INDEX `gang_name_tribute_banned_until` (`gang_name`, `banned_until`)
) ENGINE=InnoDB DEFAULT CHARSET='utf8mb4' COLLATE='utf8mb4_unicode_ci';

CREATE TABLE IF NOT EXISTS `rm_gangs_turf_wars` (
    `id` INT(11) NOT NULL AUTO_INCREMENT,
    `initiator` VARCHAR(50) NULL DEFAULT NULL,
    `target` VARCHAR(50) NULL DEFAULT NULL,
    `initiatorPersonCount` INT(10) NULL DEFAULT NULL,
    `targetPersonCount` INT(10) NULL DEFAULT NULL,
    `successful` TINYINT(2) NULL DEFAULT '0',
    `declareDate` TIMESTAMP NULL DEFAULT current_timestamp(),
    `startDate` TIMESTAMP NULL DEFAULT NULL,
    `finishDate` TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET='utf8mb4' COLLATE='utf8mb4_unicode_ci';

CREATE TABLE IF NOT EXISTS `rm_gangs_tribute_zones` (
    `name` VARCHAR(100) NULL DEFAULT NULL,
    `owner` VARCHAR(50) NULL DEFAULT NULL,
    `lastReceiptDate` TIMESTAMP NULL DEFAULT NULL,
    `captureDate` TIMESTAMP NULL DEFAULT current_timestamp(),
    PRIMARY KEY (`name`)
) ENGINE=InnoDB DEFAULT CHARSET='utf8mb4';

CREATE TABLE IF NOT EXISTS `rm_gangs_main` (
    `name` VARCHAR(50) NULL DEFAULT NULL,
    `logoURL` LONGTEXT NULL DEFAULT NULL,
    `loyalty` INT(11) NULL DEFAULT '0',
    `money` INT(11) NULL DEFAULT '0',
    PRIMARY KEY (`name`)
) ENGINE=InnoDB DEFAULT CHARSET='utf8mb4' COLLATE='utf8mb4_unicode_ci';
