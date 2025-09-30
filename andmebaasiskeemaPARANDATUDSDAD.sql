-- phpMyAdmin SQL Dump (täiendatud skeem)


SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
SET time_zone = "+00:00";
START TRANSACTION;



CREATE TABLE `users` (
  `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT,
  `username` varchar(50) NOT NULL,
  `email` varchar(100) NOT NULL,
  `password` varchar(255) NOT NULL,
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_users_username` (`username`),
  UNIQUE KEY `uq_users_email` (`email`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;

INSERT INTO `users` (`id`, `username`, `email`, `password`, `created_at`) VALUES
(1, 'anna', 'anna@example.com', 'hash1', '2025-09-23 12:28:48'),
(2, 'mart', 'mart@example.com', 'hash2', '2025-09-23 12:28:48');

CREATE TABLE `models` (
  `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` varchar(100) NOT NULL,          -- nt "Model 1"
  `version` varchar(50) DEFAULT NULL,    -- nt "1.5"
  `provider` varchar(100) DEFAULT NULL,  -- nt "OpenAI", "Local"
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_models_name_version` (`name`,`version`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;

INSERT INTO `models` (`id`, `name`, `version`, `provider`, `created_at`) VALUES
(1, 'Model 1', '1.0', 'Demo', current_timestamp()),
(2, 'Model 1.5', '1.5', 'Demo', current_timestamp());


CREATE TABLE `conversations` (
  `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT,
  `userId` int(10) UNSIGNED NOT NULL, -- vestluse omanik
  `title` varchar(150) NOT NULL,
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_conversations_userId` (`userId`),
  CONSTRAINT `fk_conversations_user` FOREIGN KEY (`userId`)
    REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;

INSERT INTO `conversations` (`id`, `userId`, `title`, `created_at`) VALUES
(1, 1, 'Esimene vestlus ChatGPT-ga', '2025-09-23 12:28:48'),
(2, 2, 'SQL kodutöö abi', '2025-09-23 12:28:48');


CREATE TABLE `messages` (
  `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT,
  `conversationId` int(10) UNSIGNED NOT NULL,
  `sender_type` enum('user','ai','system') NOT NULL, -- uus: sõnumi päritolu
  `userId` int(10) UNSIGNED DEFAULT NULL,            -- kui sender_type='user'; muidu NULL
  `modelId` int(10) UNSIGNED DEFAULT NULL,           -- kui sender_type='ai' või 'system' (vajadusel)
  `message` longtext NOT NULL,
  `sent_at` timestamp NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_messages_conversationId` (`conversationId`),
  KEY `idx_messages_userId` (`userId`),
  KEY `idx_messages_modelId` (`modelId`),
  CONSTRAINT `fk_messages_conversation` FOREIGN KEY (`conversationId`)
    REFERENCES `conversations` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_messages_user` FOREIGN KEY (`userId`)
    REFERENCES `users` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_messages_model` FOREIGN KEY (`modelId`)
    REFERENCES `models` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;

INSERT INTO `messages` (`id`, `conversationId`, `sender_type`, `userId`, `modelId`, `message`, `sent_at`) VALUES
(1, 1, 'user',   1, NULL, 'Tere ChatGPT!', '2025-09-23 12:28:48'),
(2, 1, 'ai',   NULL, 1, 'Tere Anna! Kuidas saan aidata?', '2025-09-23 12:28:48'),
(3, 2, 'user',   2, NULL, 'Palun aita mul teha andmebaasi skeem.', '2025-09-23 12:28:48');


CREATE TABLE `likes` (
  `messageId` int(10) UNSIGNED NOT NULL,
  `userId` int(10) UNSIGNED NOT NULL,
  `reaction` enum('like','dislike') NOT NULL DEFAULT 'like',
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`messageId`, `userId`),
  KEY `idx_likes_userId` (`userId`),
  CONSTRAINT `fk_likes_message` FOREIGN KEY (`messageId`)
    REFERENCES `messages` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_likes_user` FOREIGN KEY (`userId`)
    REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;

-- Näidisandmed (sama kasutaja ei saa sama sõnumit topelt laikida)
INSERT INTO `likes` (`messageId`, `userId`, `reaction`, `created_at`) VALUES
(1, 2, 'like', '2025-09-23 12:28:48'),
(2, 1, 'like', '2025-09-23 12:28:48');


CREATE TABLE `message_usage` (
  `messageId` int(10) UNSIGNED NOT NULL,
  `prompt_tokens` int UNSIGNED DEFAULT 0,
  `completion_tokens` int UNSIGNED DEFAULT 0,
  `total_tokens` int UNSIGNED GENERATED ALWAYS AS (`prompt_tokens` + `completion_tokens`) VIRTUAL,
  `currency` char(3) DEFAULT 'USD',
  `cost` decimal(18,6) DEFAULT NULL, -- arvuta rakenduses või triggeriga
  `measured_at` timestamp NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`messageId`),
  CONSTRAINT `fk_usage_message` FOREIGN KEY (`messageId`)
    REFERENCES `messages` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;

-- Näide: märgime AI-sõnumile tokenid
INSERT INTO `message_usage` (`messageId`, `prompt_tokens`, `completion_tokens`, `currency`, `cost`)
VALUES (2, 12, 8, 'USD', 0.00050);


CREATE TABLE `conversation_shares` (
  `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT,
  `conversationId` int(10) UNSIGNED NOT NULL,
  `shared_by_userId` int(10) UNSIGNED NOT NULL,
  `visibility` enum('private','link','public') NOT NULL DEFAULT 'private',
  `share_token` varchar(100) DEFAULT NULL, -- kui visibility='link'
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_shares_token` (`share_token`),
  KEY `idx_shares_conversationId` (`conversationId`),
  KEY `idx_shares_userId` (`shared_by_userId`),
  CONSTRAINT `fk_shares_conversation` FOREIGN KEY (`conversationId`)
    REFERENCES `conversations` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_shares_user` FOREIGN KEY (`shared_by_userId`)
    REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;

-- Näidis: vestlus #1 on lingiga jagatud
INSERT INTO `conversation_shares`
(`conversationId`,`shared_by_userId`,`visibility`,`share_token`)
VALUES (1, 1, 'link', 'share_abc123');

COMMIT;
