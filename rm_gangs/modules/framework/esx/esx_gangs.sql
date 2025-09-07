CREATE TABLE IF NOT EXISTS `rm_gangs_esx_players` (
	`identifier` VARCHAR(60) NOT NULL,
	`name` VARCHAR(50) NULL DEFAULT 'none',
	`grade` SMALLINT(5) NULL DEFAULT '0',
	PRIMARY KEY (`identifier`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET='utf8mb4' COLLATE='utf8mb4_unicode_ci';
