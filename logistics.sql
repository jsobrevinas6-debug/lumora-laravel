-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: Oct 31, 2026 at 05:20 AM
-- Server version: 10.4.32-MariaDB
-- PHP Version: 8.2.12

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `logistics`
--

-- --------------------------------------------------------

--
-- Table structure for table `audit_logs`
--

CREATE TABLE `audit_logs` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `user_id` bigint(20) UNSIGNED DEFAULT NULL,
  `event` varchar(255) NOT NULL,
  `auditable_type` varchar(255) DEFAULT NULL,
  `auditable_id` bigint(20) UNSIGNED DEFAULT NULL,
  `metadata` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`metadata`)),
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `cache`
--

CREATE TABLE `cache` (
  `key` varchar(255) NOT NULL,
  `value` mediumtext NOT NULL,
  `expiration` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `cache_locks`
--

CREATE TABLE `cache_locks` (
  `key` varchar(255) NOT NULL,
  `owner` varchar(255) NOT NULL,
  `expiration` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `commission_transactions`
--

CREATE TABLE `commission_transactions` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `rider_profile_id` bigint(20) UNSIGNED NOT NULL,
  `parcel_id` bigint(20) UNSIGNED DEFAULT NULL,
  `amount` decimal(12,2) NOT NULL DEFAULT 0.00,
  `status` varchar(255) NOT NULL DEFAULT 'pending',
  `description` varchar(255) DEFAULT NULL,
  `earned_at` timestamp NULL DEFAULT NULL,
  `paid_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `commission_transactions`
--

INSERT INTO `commission_transactions` (`id`, `rider_profile_id`, `parcel_id`, `amount`, `status`, `description`, `earned_at`, `paid_at`, `created_at`, `updated_at`) VALUES
(1, 5, 1, 20.00, 'pending', 'Delivery commission for LM-TRK-000015', '2026-10-15 00:17:31', NULL, '2026-10-15 00:17:31', '2026-10-15 00:17:31'),
(2, 5, 2, 150.00, 'pending', 'Delivery payout for LM-TRK-000016', '2026-10-15 00:56:05', NULL, '2026-10-15 00:56:05', '2026-10-15 00:56:05'),
(3, 6, 3, 150.00, 'pending', 'Delivery payout for LM-TRK-000017', '2026-10-15 01:19:19', NULL, '2026-10-15 01:19:19', '2026-10-15 01:19:19'),
(4, 6, 5, 150.00, 'pending', 'Delivery payout for LM-TRK-000019', '2026-10-15 01:25:18', NULL, '2026-10-15 01:25:18', '2026-10-15 01:25:18'),
(5, 5, 6, 150.00, 'pending', 'Delivery payout for LM-TRK-000020', '2026-10-15 03:03:34', NULL, '2026-10-15 03:03:34', '2026-10-15 03:03:34'),
(6, 5, 4, 150.00, 'pending', 'Delivery payout for LM-TRK-000018', '2026-10-15 05:42:29', NULL, '2026-10-15 05:42:29', '2026-10-15 05:42:29'),
(7, 5, 10, 150.00, 'pending', 'Delivery payout for LM-TRK-000024', '2026-10-15 08:07:32', NULL, '2026-10-15 08:07:32', '2026-10-15 08:07:32'),
(8, 5, 13, 10.00, 'pending', 'Delivery commission for LM-TRK-000027', '2026-10-15 23:38:09', NULL, '2026-10-15 23:38:09', '2026-10-15 23:38:09'),
(9, 5, 17, 150.00, 'pending', 'Delivery payout for LM-TRK-000031', '2026-10-16 04:43:45', NULL, '2026-10-16 04:43:45', '2026-10-16 04:43:45'),
(10, 5, 23, 150.00, 'pending', 'Delivery payout for LM-TRK-000037', '2026-10-16 06:17:01', NULL, '2026-10-16 06:17:01', '2026-10-16 06:17:01'),
(11, 6, 24, 150.00, 'pending', 'Delivery payout for LM-TRK-000038', '2026-10-16 06:24:03', NULL, '2026-10-16 06:24:03', '2026-10-16 06:24:03'),
(12, 5, 26, 150.00, 'pending', 'Delivery payout for LM-TRK-000040', '2026-10-16 17:07:09', NULL, '2026-10-16 17:07:09', '2026-10-16 17:07:09'),
(13, 5, 12, 150.00, 'pending', 'Delivery payout for LM-TRK-000026', '2026-10-16 17:45:48', NULL, '2026-10-16 17:45:48', '2026-10-16 17:45:48'),
(14, 6, 20, 150.00, 'pending', 'Delivery payout for LM-TRK-000034', '2026-10-19 16:26:11', NULL, '2026-10-19 16:26:11', '2026-10-19 16:26:11'),
(15, 5, 11, 150.00, 'pending', 'Delivery payout for LM-TRK-000025', '2026-10-29 06:10:07', NULL, '2026-10-29 06:10:07', '2026-10-29 06:10:07'),
(16, 5, 33, 150.00, 'pending', 'Delivery payout for LM-TRK-000047', '2026-10-30 18:44:46', NULL, '2026-10-30 18:44:46', '2026-10-30 18:44:46'),
(17, 1, 30, 150.00, 'pending', 'Delivery payout for LM-TRK-000044', '2026-10-30 18:50:35', NULL, '2026-10-30 18:50:35', '2026-10-30 18:50:35');

-- --------------------------------------------------------

--
-- Table structure for table `destination_areas`
--

CREATE TABLE `destination_areas` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `store_id` bigint(20) UNSIGNED NOT NULL,
  `name` varchar(255) NOT NULL,
  `branch` varchar(255) DEFAULT NULL,
  `province` varchar(255) DEFAULT NULL,
  `code` varchar(255) DEFAULT NULL,
  `coverage_rules` text DEFAULT NULL,
  `cities` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`cities`)),
  `postal_codes` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`postal_codes`)),
  `is_active` tinyint(1) NOT NULL DEFAULT 1,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `destination_areas`
--

INSERT INTO `destination_areas` (`id`, `store_id`, `name`, `branch`, `province`, `code`, `coverage_rules`, `cities`, `postal_codes`, `is_active`, `created_at`, `updated_at`) VALUES
(1, 1, 'Area A — Santa Cruz', 'Santa Cruz', 'Laguna', 'LAG-A', NULL, '[\"Santa Cruz\"]', NULL, 1, '2026-08-29 23:00:03', '2026-10-17 07:12:01'),
(4, 1, 'SCN-PILA', 'Pila', 'Laguna', 'LAG-4', NULL, '[\"PILA\"]', '[\"4010\"]', 1, '2026-10-14 23:56:55', '2026-10-17 07:12:01'),
(10, 1, 'SCS-PILA', 'Pila', 'Laguna', 'LAG', NULL, '[\"PILA\"]', '[\"4010\"]', 1, '2026-10-15 04:28:38', '2026-10-17 07:12:01'),
(11, 1, 'BBN-PILA', 'Pila', 'Laguna', 'LAG1', NULL, '[\"PILA\"]', '[\"4010\"]', 1, '2026-10-15 04:29:10', '2026-10-17 07:12:01'),
(12, 1, 'BBS-PILA', 'Pila', 'Laguna', 'LAG-2', NULL, '[\"PILA\"]', '[\"4010\"]', 1, '2026-10-15 04:29:49', '2026-10-17 07:12:01');

-- --------------------------------------------------------

--
-- Table structure for table `email_otp_verifications`
--

CREATE TABLE `email_otp_verifications` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `email` varchar(255) NOT NULL,
  `otp` varchar(6) NOT NULL,
  `expires_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `is_verified` tinyint(1) NOT NULL DEFAULT 0,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `email_otp_verifications`
--

INSERT INTO `email_otp_verifications` (`id`, `email`, `otp`, `expires_at`, `is_verified`, `created_at`, `updated_at`) VALUES
(3, 'cjrubiales12@gmail.com', '669281', '2026-10-28 19:41:09', 0, '2026-10-28 18:30:06', '2026-10-28 19:31:09'),
(4, 'carljohnrubiales@gmail.com', '619386', '2026-10-29 04:04:01', 1, '2026-10-28 20:03:21', '2026-10-28 20:04:01'),
(5, 'cjrbls12@gmail.com', '498079', '2026-10-29 09:09:11', 1, '2026-10-29 01:07:23', '2026-10-29 01:09:11'),
(6, 'crlrbls12@gmail.com', '918126', '2026-10-29 01:23:44', 0, '2026-10-29 01:13:44', '2026-10-29 01:13:44'),
(7, 'rubialesarceli@gmail.com', '470803', '2026-10-29 14:21:17', 1, '2026-10-29 06:20:40', '2026-10-29 06:21:17'),
(8, 'jsobrevinas6@gmail.com', '854501', '2026-10-31 03:20:44', 1, '2026-10-30 19:20:16', '2026-10-30 19:20:44');

-- --------------------------------------------------------

--
-- Table structure for table `erp_messages`
--

CREATE TABLE `erp_messages` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `sender_id` bigint(20) UNSIGNED DEFAULT NULL,
  `recipient_id` bigint(20) UNSIGNED DEFAULT NULL,
  `parcel_id` bigint(20) UNSIGNED DEFAULT NULL,
  `message` text NOT NULL,
  `read_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `erp_messages`
--

INSERT INTO `erp_messages` (`id`, `sender_id`, `recipient_id`, `parcel_id`, `message`, `read_at`, `created_at`, `updated_at`) VALUES
(1, 1, 3, NULL, 'nasan kana?', NULL, '2026-09-26 21:18:37', '2026-09-26 21:18:37'),
(2, 7, 1, NULL, 'hello', '2026-10-15 05:38:52', '2026-10-14 23:13:56', '2026-10-15 05:38:52'),
(3, 1, 16, NULL, 'Hello Master Admin, Pila branch has sorted all incoming manifest packages today.', '2026-10-17 07:54:46', '2026-10-17 07:50:58', '2026-10-17 07:54:46'),
(4, 16, 1, NULL, 'Acknowledged Pila Hub. Excellent work on the timely sorting.', '2026-10-17 08:06:48', '2026-10-17 07:50:58', '2026-10-17 08:06:48'),
(5, 16, 1, NULL, 'inamo', '2026-10-28 18:41:37', '2026-10-28 18:40:57', '2026-10-28 18:41:37'),
(6, 1, 16, NULL, 'pakyu', '2026-10-29 01:04:20', '2026-10-28 18:41:45', '2026-10-29 01:04:20'),
(7, 1, 8, NULL, 'deliver mo na loko', NULL, '2026-10-29 21:26:18', '2026-10-29 21:26:18');

-- --------------------------------------------------------

--
-- Table structure for table `failed_jobs`
--

CREATE TABLE `failed_jobs` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `uuid` varchar(255) NOT NULL,
  `connection` text NOT NULL,
  `queue` text NOT NULL,
  `payload` longtext NOT NULL,
  `exception` longtext NOT NULL,
  `failed_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `fulfillment_locations`
--

CREATE TABLE `fulfillment_locations` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `store_id` bigint(20) UNSIGNED NOT NULL,
  `name` varchar(255) NOT NULL,
  `code` varchar(255) NOT NULL,
  `address_line` varchar(255) DEFAULT NULL,
  `city` varchar(255) DEFAULT NULL,
  `state` varchar(255) DEFAULT NULL,
  `postal_code` varchar(255) DEFAULT NULL,
  `country` varchar(2) NOT NULL DEFAULT 'US',
  `is_active` tinyint(1) NOT NULL DEFAULT 1,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `fulfillment_locations`
--

INSERT INTO `fulfillment_locations` (`id`, `store_id`, `name`, `code`, `address_line`, `city`, `state`, `postal_code`, `country`, `is_active`, `created_at`, `updated_at`) VALUES
(1, 1, 'Brooklyn Fulfillment Studio', 'NYC-01', NULL, 'Brooklyn', 'NY', '11201', 'US', 1, '2026-08-29 23:00:03', '2026-08-29 23:00:03');

-- --------------------------------------------------------

--
-- Table structure for table `hubs`
--

CREATE TABLE `hubs` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `name` varchar(255) NOT NULL,
  `branch` varchar(255) DEFAULT NULL,
  `address` varchar(255) DEFAULT NULL,
  `city` varchar(255) DEFAULT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT 1,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `hubs`
--

INSERT INTO `hubs` (`id`, `name`, `branch`, `address`, `city`, `is_active`, `created_at`, `updated_at`) VALUES
(1, 'Sta Cruz Hub', 'Santa Cruz', 'Santa Cruz Distribution Center, Laguna', 'Santa Cruz', 1, '2026-10-28 20:26:59', '2026-10-29 01:33:23'),
(2, 'Pila Hub', 'Pila', 'Pila Sorting Facility, Laguna', 'Pila', 1, '2026-10-28 20:26:59', '2026-10-29 01:33:25'),
(3, 'Main Hub', 'Main', 'Main Logistics Center', 'Main', 1, '2026-10-28 20:26:59', '2026-10-28 20:55:43');

-- --------------------------------------------------------

--
-- Table structure for table `inventory_items`
--

CREATE TABLE `inventory_items` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `store_id` bigint(20) UNSIGNED NOT NULL,
  `fulfillment_location_id` bigint(20) UNSIGNED DEFAULT NULL,
  `sku` varchar(255) NOT NULL,
  `name` varchar(255) NOT NULL,
  `quantity_on_hand` int(10) UNSIGNED NOT NULL DEFAULT 0,
  `quantity_reserved` int(10) UNSIGNED NOT NULL DEFAULT 0,
  `reorder_point` int(10) UNSIGNED NOT NULL DEFAULT 5,
  `status` varchar(255) NOT NULL DEFAULT 'in_stock',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `inventory_items`
--

INSERT INTO `inventory_items` (`id`, `store_id`, `fulfillment_location_id`, `sku`, `name`, `quantity_on_hand`, `quantity_reserved`, `reorder_point`, `status`, `created_at`, `updated_at`) VALUES
(1, 1, 1, 'asas', 'shampoo', 3, 1, 2, 'low_stock', '2026-09-01 05:54:49', '2026-09-01 05:54:49');

-- --------------------------------------------------------

--
-- Table structure for table `jobs`
--

CREATE TABLE `jobs` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `queue` varchar(255) NOT NULL,
  `payload` longtext NOT NULL,
  `attempts` tinyint(3) UNSIGNED NOT NULL,
  `reserved_at` int(10) UNSIGNED DEFAULT NULL,
  `available_at` int(10) UNSIGNED NOT NULL,
  `created_at` int(10) UNSIGNED NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `job_batches`
--

CREATE TABLE `job_batches` (
  `id` varchar(255) NOT NULL,
  `name` varchar(255) NOT NULL,
  `total_jobs` int(11) NOT NULL,
  `pending_jobs` int(11) NOT NULL,
  `failed_jobs` int(11) NOT NULL,
  `failed_job_ids` longtext NOT NULL,
  `options` mediumtext DEFAULT NULL,
  `cancelled_at` int(11) DEFAULT NULL,
  `created_at` int(11) NOT NULL,
  `finished_at` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `migrations`
--

CREATE TABLE `migrations` (
  `id` int(10) UNSIGNED NOT NULL,
  `migration` varchar(255) NOT NULL,
  `batch` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `migrations`
--

INSERT INTO `migrations` (`id`, `migration`, `batch`) VALUES
(1, '0001_01_01_000000_create_users_table', 1),
(2, '0001_01_01_000001_create_cache_table', 1),
(3, '0001_01_01_000002_create_jobs_table', 1),
(4, '2026_08_27_020000_create_logistics_tables', 1),
(5, '2026_08_27_020100_add_role_to_users_table', 1),
(6, '2026_08_27_020200_create_inventory_items_table', 1),
(7, '2026_08_27_020300_create_sorting_center_erp_tables', 1),
(8, '2026_10_14_032510_create_personal_access_tokens_table', 2),
(9, '2026_10_15_111459_add_documents_to_rider_profiles_table', 3),
(10, '2026_10_15_205000_update_destination_areas_use_province', 4),
(11, '2026_10_17_230000_add_branch_to_users_areas_and_parcels', 5),
(12, '2026_10_29_095000_create_email_otp_verifications_table', 6),
(13, '2026_10_29_120000_create_hubs_table', 7),
(14, '2026_10_29_124500_add_branch_to_hubs_table', 8);

-- --------------------------------------------------------

--
-- Table structure for table `orders`
--

CREATE TABLE `orders` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `store_id` bigint(20) UNSIGNED NOT NULL,
  `external_id` varchar(255) NOT NULL,
  `order_number` varchar(255) DEFAULT NULL,
  `customer_name` varchar(255) NOT NULL,
  `customer_email` varchar(255) DEFAULT NULL,
  `shipping_address` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`shipping_address`)),
  `status` varchar(255) NOT NULL DEFAULT 'paid',
  `total` decimal(12,2) NOT NULL DEFAULT 0.00,
  `ordered_at` timestamp NULL DEFAULT NULL,
  `metadata` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`metadata`)),
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `orders`
--

INSERT INTO `orders` (`id`, `store_id`, `external_id`, `order_number`, `customer_name`, `customer_email`, `shipping_address`, `status`, `total`, `ordered_at`, `metadata`, `created_at`, `updated_at`) VALUES
(1, 1, 'LM-2187', 'LM-2187', 'Sophia Chen', 'sophia.chen@example.com', '{\"line1\":\"Sample delivery address\",\"city\":\"Makati City\",\"state\":\"Metro Manila\",\"postal_code\":\"1200\",\"country\":\"PH\"}', 'paid', 48.00, '2026-08-29 23:14:11', '{\"source\":\"lumora-demo-seeder\"}', '2026-08-29 23:00:04', '2026-08-29 23:14:11'),
(2, 1, 'LM-2186', 'LM-2186', 'James Robinson', 'james.robinson@example.com', '{\"line1\":\"Sample delivery address\",\"city\":\"Taguig City\",\"state\":\"Metro Manila\",\"postal_code\":\"1630\",\"country\":\"PH\"}', 'paid', 55.50, '2026-08-29 22:51:11', '{\"source\":\"lumora-demo-seeder\"}', '2026-08-29 23:00:04', '2026-08-29 23:14:11'),
(3, 1, 'LM-2185', 'LM-2185', 'Olivia Valdez', 'olivia.valdez@example.com', '{\"line1\":\"Sample delivery address\",\"city\":\"Pasig City\",\"state\":\"Metro Manila\",\"postal_code\":\"1600\",\"country\":\"PH\"}', 'paid', 63.00, '2026-08-29 22:28:11', '{\"source\":\"lumora-demo-seeder\"}', '2026-08-29 23:00:04', '2026-08-29 23:14:11'),
(4, 1, 'LM-2184', 'LM-2184', 'Noah Kim', 'noah.kim@example.com', '{\"line1\":\"Sample delivery address\",\"city\":\"Quezon City\",\"state\":\"Metro Manila\",\"postal_code\":\"1100\",\"country\":\"PH\"}', 'paid', 70.50, '2026-08-29 22:05:11', '{\"source\":\"lumora-demo-seeder\"}', '2026-08-29 23:00:04', '2026-08-29 23:14:11'),
(5, 1, 'LM-2183', 'LM-2183', 'Maya Patel', 'maya.patel@example.com', '{\"line1\":\"Sample delivery address\",\"city\":\"Manila\",\"state\":\"Metro Manila\",\"postal_code\":\"1000\",\"country\":\"PH\"}', 'paid', 78.00, '2026-08-29 21:42:11', '{\"source\":\"lumora-demo-seeder\"}', '2026-08-29 23:00:04', '2026-08-29 23:14:11'),
(6, 1, 'LM-2182', 'LM-2182', 'Evelyn Hart', 'evelyn.hart@example.com', '{\"line1\":\"Sample delivery address\",\"city\":\"Mandaluyong City\",\"state\":\"Metro Manila\",\"postal_code\":\"1550\",\"country\":\"PH\"}', 'paid', 85.50, '2026-08-29 21:19:11', '{\"source\":\"lumora-demo-seeder\"}', '2026-08-29 23:00:04', '2026-08-29 23:14:11'),
(7, 1, 'LM-2181', 'LM-2181', 'Liam Brooks', 'liam.brooks@example.com', '{\"line1\":\"Sample delivery address\",\"city\":\"Calamba City\",\"state\":\"Laguna\",\"postal_code\":\"4027\",\"country\":\"PH\"}', 'paid', 93.00, '2026-08-29 20:56:11', '{\"source\":\"lumora-demo-seeder\"}', '2026-08-29 23:00:05', '2026-08-29 23:14:11'),
(8, 1, 'LM-2180', 'LM-2180', 'Amara Williams', 'amara.williams@example.com', '{\"line1\":\"Sample delivery address\",\"city\":\"Antipolo City\",\"state\":\"Rizal\",\"postal_code\":\"1870\",\"country\":\"PH\"}', 'paid', 100.50, '2026-08-29 20:33:11', '{\"source\":\"lumora-demo-seeder\"}', '2026-08-29 23:00:05', '2026-08-29 23:14:11'),
(9, 1, 'LM-2179', 'LM-2179', 'Elena Rossi', 'elena.rossi@example.com', '{\"line1\":\"Sample delivery address\",\"city\":\"Batangas City\",\"state\":\"Batangas\",\"postal_code\":\"4200\",\"country\":\"PH\"}', 'paid', 108.00, '2026-08-29 20:10:11', '{\"source\":\"lumora-demo-seeder\"}', '2026-08-29 23:00:05', '2026-08-29 23:14:11'),
(10, 1, 'LM-2178', 'LM-2178', 'Aiden Smith', 'aiden.smith@example.com', '{\"line1\":\"Sample delivery address\",\"city\":\"Santa Rosa City\",\"state\":\"Laguna\",\"postal_code\":\"4026\",\"country\":\"PH\"}', 'paid', 115.50, '2026-08-29 19:47:11', '{\"source\":\"lumora-demo-seeder\"}', '2026-08-29 23:00:05', '2026-08-29 23:14:11'),
(11, 1, 'LM-2177', 'LM-2177', 'Nora Anderson', 'nora.anderson@example.com', '{\"line1\":\"Sample delivery address\",\"city\":\"Imus City\",\"state\":\"Cavite\",\"postal_code\":\"4103\",\"country\":\"PH\"}', 'paid', 123.00, '2026-08-29 19:24:11', '{\"source\":\"lumora-demo-seeder\"}', '2026-08-29 23:00:05', '2026-08-29 23:14:11'),
(12, 1, 'LM-2176', 'LM-2176', 'Theo Martin', 'theo.martin@example.com', '{\"line1\":\"Sample delivery address\",\"city\":\"Bacoor City\",\"state\":\"Cavite\",\"postal_code\":\"4102\",\"country\":\"PH\"}', 'paid', 130.50, '2026-08-29 19:01:11', '{\"source\":\"lumora-demo-seeder\"}', '2026-08-29 23:00:05', '2026-08-29 23:14:11'),
(13, 1, 'intake-c9716c4a-a5b2-4fa7-ae1f-fe4102d246dd', NULL, 'jasenj', NULL, '{\"line1\":\"brgy,bbn\",\"city\":\"pila\",\"state\":\"Laguna\",\"postal_code\":\"4010\",\"country\":\"PH\",\"phone\":\"09101292902\"}', 'pending', 0.00, '2026-10-14 20:52:31', '{\"source\":\"parcel_intake\"}', '2026-10-14 20:52:31', '2026-10-14 20:52:31'),
(14, 1, 'intake-9c4f956c-22f3-46fe-93e2-cef7134c4bbb', NULL, 'cj', NULL, '{\"line1\":\"SCN\",\"city\":\"pila\",\"state\":\"Laguna\",\"postal_code\":\"4010\",\"country\":\"PH\",\"phone\":\"09755667472\"}', 'pending', 0.00, '2026-10-14 23:57:35', '{\"source\":\"parcel_intake\"}', '2026-10-14 23:57:35', '2026-10-14 23:57:35'),
(15, 1, 'intake-3a328f67-4a87-45b5-b41e-c72d99d4238a', NULL, 'erin', NULL, '{\"line1\":\"scn\",\"city\":\"pila\",\"state\":\"Laguna\",\"postal_code\":\"4010\",\"country\":\"PH\",\"phone\":\"09091072577\"}', 'pending', 0.00, '2026-10-15 00:17:01', '{\"source\":\"parcel_intake\"}', '2026-10-15 00:17:01', '2026-10-15 00:17:01'),
(16, 1, 'intake-4c068b42-0d04-4201-8b14-1ff592ba6cce', NULL, 'totoy', NULL, '{\"line1\":\"250 bonifacio st\",\"city\":\"pila\",\"state\":\"Laguna\",\"postal_code\":\"4010\",\"country\":\"PH\",\"phone\":\"09101292902\"}', 'pending', 0.00, '2026-10-15 00:51:58', '{\"source\":\"parcel_intake\"}', '2026-10-15 00:51:58', '2026-10-15 00:51:58'),
(17, 1, 'intake-5afae49b-cd6d-4449-ab7a-7fb080c2654c', NULL, 'totoy', NULL, '{\"line1\":\"sta clara norte bonifacio st 250\",\"city\":\"pila\",\"state\":\"Laguna\",\"postal_code\":\"4010\",\"country\":\"PH\",\"phone\":\"09101292902\"}', 'pending', 0.00, '2026-10-15 01:16:26', '{\"source\":\"parcel_intake\"}', '2026-10-15 01:16:26', '2026-10-15 01:16:26'),
(18, 1, 'intake-246c38d1-9e46-4533-9ca4-1eec0dcf4bd5', NULL, 'joyce', NULL, '{\"line1\":\"scn\",\"city\":\"pila\",\"state\":\"Laguna\",\"postal_code\":\"4010\",\"country\":\"PH\",\"phone\":\"09755667472\"}', 'pending', 0.00, '2026-10-15 01:20:35', '{\"source\":\"parcel_intake\"}', '2026-10-15 01:20:35', '2026-10-15 01:20:35'),
(19, 1, 'intake-911ec0ca-c44c-484c-8177-55c57824c155', NULL, 'cj', NULL, '{\"line1\":\"brgy,bbn\",\"city\":\"pila\",\"state\":\"Laguna\",\"postal_code\":\"4010\",\"country\":\"PH\",\"phone\":\"09755667472\"}', 'pending', 0.00, '2026-10-15 01:23:36', '{\"source\":\"parcel_intake\"}', '2026-10-15 01:23:36', '2026-10-15 01:23:36'),
(20, 1, 'intake-d03d9996-bf2b-4c41-abf4-fb7707d6e801', NULL, 'ange', NULL, '{\"line1\":\"scn\",\"city\":\"pila\",\"state\":\"Laguna\",\"postal_code\":\"4010\",\"country\":\"PH\",\"phone\":\"09755667472\"}', 'pending', 0.00, '2026-10-15 03:02:09', '{\"source\":\"parcel_intake\"}', '2026-10-15 03:02:09', '2026-10-15 03:02:09'),
(21, 1, 'intake-1aa02dad-2615-4ec5-aeb6-2c2f4c560fde', NULL, 'cj', NULL, '{\"line1\":\"BONIFACIO ST\",\"city\":\"pila\",\"state\":\"Laguna\",\"postal_code\":\"4010\",\"country\":\"PH\",\"phone\":\"09755667472\"}', 'pending', 0.00, '2026-10-15 06:36:52', '{\"source\":\"parcel_intake\"}', '2026-10-15 06:36:52', '2026-10-15 06:36:52'),
(22, 1, 'intake-7cac58cf-d46a-4f5c-8235-e6fd35927f5e', NULL, 'joyce', NULL, '{\"line1\":\"brgy,bbn\",\"city\":\"pila\",\"state\":\"Laguna\",\"postal_code\":\"4010\",\"country\":\"PH\",\"phone\":\"09755667472\"}', 'pending', 0.00, '2026-10-15 07:11:15', '{\"source\":\"parcel_intake\"}', '2026-10-15 07:11:15', '2026-10-15 07:11:15'),
(23, 1, 'intake-f0872c9d-4658-497a-ba56-95a494b9925b', NULL, 'ange', NULL, '{\"line1\":\"brgy,bbn\",\"city\":\"pila\",\"state\":\"Laguna\",\"postal_code\":\"4010\",\"country\":\"PH\",\"phone\":\"09755667472\"}', 'pending', 0.00, '2026-10-15 07:13:28', '{\"source\":\"parcel_intake\"}', '2026-10-15 07:13:28', '2026-10-15 07:13:28'),
(24, 1, 'intake-c2c624d8-1796-4414-9084-5f4c5ceabde1', NULL, 'jasenj', NULL, '{\"line1\":\"brgy,bbn\",\"city\":\"pila\",\"state\":\"Laguna\",\"postal_code\":\"4010\",\"country\":\"PH\",\"phone\":\"09755667472\"}', 'pending', 0.00, '2026-10-15 07:44:05', '{\"source\":\"parcel_intake\"}', '2026-10-15 07:44:05', '2026-10-15 07:44:05'),
(25, 1, 'intake-942fa7ee-7d12-406d-a619-3c41eb2f521b', NULL, 'totoy', NULL, '{\"line1\":\"brgy,bbn\",\"city\":\"pila\",\"state\":\"Laguna\",\"postal_code\":\"4010\",\"country\":\"PH\",\"phone\":\"09755667472\"}', 'pending', 0.00, '2026-10-15 08:09:20', '{\"source\":\"parcel_intake\"}', '2026-10-15 08:09:20', '2026-10-15 08:09:20'),
(26, 1, 'intake-38f38bc7-592f-4910-bb06-e9710833f8cf', NULL, 'ange', NULL, '{\"line1\":\"brgy,SCN\",\"city\":\"pila\",\"state\":\"Laguna\",\"postal_code\":\"4010\",\"country\":\"PH\",\"phone\":\"09755667472\"}', 'pending', 0.00, '2026-10-15 08:11:06', '{\"source\":\"parcel_intake\"}', '2026-10-15 08:11:06', '2026-10-15 08:11:06'),
(27, 1, 'intake-fbb484ac-6868-49aa-b2f9-0efff424c6d6', NULL, 'Intake Package', NULL, '{\"line1\":\"Delivery destination, Santa Cruz, Laguna\",\"city\":\"Santa Cruz\",\"state\":\"Laguna\",\"postal_code\":\"4009\",\"country\":\"PH\",\"phone\":\"09170000000\"}', 'pending', 0.00, '2026-10-15 22:13:13', '{\"source\":\"parcel_intake\"}', '2026-10-15 22:13:13', '2026-10-15 22:13:13'),
(28, 1, 'intake-5db41d18-4c87-46dd-ae1d-b8fc6e26e311', NULL, 'Intake Package', NULL, '{\"line1\":\"Delivery destination, Santa Cruz, Laguna\",\"city\":\"Santa Cruz\",\"state\":\"Laguna\",\"postal_code\":\"4009\",\"country\":\"PH\",\"phone\":\"09170000000\"}', 'pending', 0.00, '2026-10-15 23:53:05', '{\"source\":\"parcel_intake\"}', '2026-10-15 23:53:05', '2026-10-15 23:53:05'),
(29, 1, 'intake-d1bbb66c-fae4-4f4a-b3ff-cb8998264e77', NULL, 'Intake Package', NULL, '{\"line1\":\"Delivery destination, Santa Cruz, Laguna\",\"city\":\"Santa Cruz\",\"state\":\"Laguna\",\"postal_code\":\"4009\",\"country\":\"PH\",\"phone\":\"09170000000\"}', 'pending', 0.00, '2026-10-15 23:53:05', '{\"source\":\"parcel_intake\"}', '2026-10-15 23:53:05', '2026-10-15 23:53:05'),
(30, 1, 'intake-006bf96c-1e11-40f1-91e9-f5e99bbd7514', NULL, 'Intake Package', NULL, '{\"line1\":\"Delivery destination, Santa Cruz, Laguna\",\"city\":\"Santa Cruz\",\"state\":\"Laguna\",\"postal_code\":\"4009\",\"country\":\"PH\",\"phone\":\"09170000000\"}', 'pending', 0.00, '2026-10-16 04:15:49', '{\"source\":\"parcel_intake\"}', '2026-10-16 04:15:49', '2026-10-16 04:15:49'),
(31, 1, 'intake-f9bc053a-5e36-4986-850f-d77532e6b105', NULL, 'Intake Package', NULL, '{\"line1\":\"Delivery destination, Santa Cruz, Laguna\",\"city\":\"Santa Cruz\",\"state\":\"Laguna\",\"postal_code\":\"4009\",\"country\":\"PH\",\"phone\":\"09170000000\"}', 'pending', 0.00, '2026-10-16 04:40:53', '{\"source\":\"parcel_intake\"}', '2026-10-16 04:40:53', '2026-10-16 04:40:53'),
(32, 1, 'intake-4964182d-43c8-4260-bbb6-4d42d206bfa7', NULL, 'Intake Package', NULL, '{\"line1\":\"Delivery destination, Santa Cruz, Laguna\",\"city\":\"Santa Cruz\",\"state\":\"Laguna\",\"postal_code\":\"4009\",\"country\":\"PH\",\"phone\":\"09170000000\"}', 'pending', 0.00, '2026-10-16 05:53:58', '{\"source\":\"parcel_intake\"}', '2026-10-16 05:53:58', '2026-10-16 05:53:58'),
(33, 1, 'intake-6051619d-f985-4679-9b12-ff1c2d9bd407', NULL, 'Intake Package', NULL, '{\"line1\":\"Delivery destination, Santa Cruz, Laguna\",\"city\":\"Santa Cruz\",\"state\":\"Laguna\",\"postal_code\":\"4009\",\"country\":\"PH\",\"phone\":\"09170000000\"}', 'pending', 0.00, '2026-10-16 06:06:38', '{\"source\":\"parcel_intake\"}', '2026-10-16 06:06:38', '2026-10-16 06:06:38'),
(34, 1, 'intake-d11d3141-67b8-45c3-815a-4d1de2baa900', NULL, 'joyce', NULL, '{\"line1\":\"brgy,bbn\",\"city\":\"pila\",\"state\":\"Laguna\",\"postal_code\":\"4010\",\"country\":\"PH\",\"phone\":\"09755667472\"}', 'pending', 0.00, '2026-10-16 06:11:05', '{\"source\":\"parcel_intake\"}', '2026-10-16 06:11:05', '2026-10-16 06:11:05'),
(35, 1, 'intake-ca034be0-b568-4c70-bc62-89da4b97a6c8', NULL, 'Intake Package', NULL, '{\"line1\":\"Delivery destination, Santa Cruz, Laguna\",\"city\":\"Santa Cruz\",\"state\":\"Laguna\",\"postal_code\":\"4009\",\"country\":\"PH\",\"phone\":\"09170000000\"}', 'pending', 0.00, '2026-10-16 06:14:12', '{\"source\":\"parcel_intake\"}', '2026-10-16 06:14:12', '2026-10-16 06:14:12'),
(36, 1, 'intake-3cc3a71e-7f18-4eb4-919f-12a38e2a9282', NULL, 'Intake Package', NULL, '{\"line1\":\"Delivery destination, Santa Cruz, Laguna\",\"city\":\"Santa Cruz\",\"state\":\"Laguna\",\"postal_code\":\"4009\",\"country\":\"PH\",\"phone\":\"09170000000\"}', 'pending', 0.00, '2026-10-16 06:14:12', '{\"source\":\"parcel_intake\"}', '2026-10-16 06:14:12', '2026-10-16 06:14:12'),
(37, 1, 'intake-448e1fcd-f6c5-4a47-9d73-cab63db19028', NULL, 'Intake Package', NULL, '{\"line1\":\"Delivery destination, Santa Cruz, Laguna\",\"city\":\"Santa Cruz\",\"state\":\"Laguna\",\"postal_code\":\"4009\",\"country\":\"PH\",\"phone\":\"09170000000\"}', 'pending', 0.00, '2026-10-16 06:14:38', '{\"source\":\"parcel_intake\"}', '2026-10-16 06:14:38', '2026-10-16 06:14:38'),
(38, 1, 'intake-c070f9cd-8508-470b-b98f-075fec80209b', NULL, 'Intake Package', NULL, '{\"line1\":\"Delivery destination, Santa Cruz, Laguna\",\"city\":\"Santa Cruz\",\"state\":\"Laguna\",\"postal_code\":\"4009\",\"country\":\"PH\",\"phone\":\"09170000000\"}', 'pending', 0.00, '2026-10-16 06:22:06', '{\"source\":\"parcel_intake\"}', '2026-10-16 06:22:06', '2026-10-16 06:22:06'),
(39, 1, 'intake-2d4c00ec-ccbb-4742-992a-fc211b09bbc8', NULL, 'Intake Package', NULL, '{\"line1\":\"Delivery destination, Santa Cruz, Laguna\",\"city\":\"Santa Cruz\",\"state\":\"Laguna\",\"postal_code\":\"4009\",\"country\":\"PH\",\"phone\":\"09170000000\"}', 'pending', 0.00, '2026-10-16 17:03:48', '{\"source\":\"parcel_intake\"}', '2026-10-16 17:03:48', '2026-10-16 17:03:48'),
(40, 1, 'intake-b145d65a-c1d3-4243-8562-75dbc2a8ebbe', NULL, 'Intake Package', NULL, '{\"line1\":\"Delivery destination, Santa Cruz, Laguna\",\"city\":\"Santa Cruz\",\"state\":\"Laguna\",\"postal_code\":\"4009\",\"country\":\"PH\",\"phone\":\"09170000000\"}', 'pending', 0.00, '2026-10-16 17:05:17', '{\"source\":\"parcel_intake\"}', '2026-10-16 17:05:17', '2026-10-16 17:05:17'),
(41, 1, 'intake-sc-5caeaf39-690c-4e5e-b42a-248df49f412c', NULL, 'Maria Santos', NULL, '{\"line1\":\"Brgy. Sto. Angel Central, Santa Cruz\",\"city\":\"Santa Cruz\",\"state\":\"Laguna\",\"postal_code\":\"4009\",\"country\":\"PH\",\"phone\":\"09171234567\"}', 'pending', 0.00, '2026-10-17 07:13:31', NULL, '2026-10-17 07:13:31', '2026-10-17 07:13:31'),
(42, 1, 'intake-sc-1add1a90-4018-4aa7-8f25-2604a8504fc3', NULL, 'Juan Dela Cruz', NULL, '{\"line1\":\"Poblacion IV, Santa Cruz\",\"city\":\"Santa Cruz\",\"state\":\"Laguna\",\"postal_code\":\"4009\",\"country\":\"PH\",\"phone\":\"09181234567\"}', 'pending', 0.00, '2026-10-17 07:13:31', NULL, '2026-10-17 07:13:31', '2026-10-17 07:13:31'),
(43, 1, 'intake-sc-e2d1c9b0-fd59-4521-9443-d3f40ccf754d', NULL, 'Ricardo Dalisay', NULL, '{\"line1\":\"Brgy. Bagumbayan, Santa Cruz\",\"city\":\"Santa Cruz\",\"state\":\"Laguna\",\"postal_code\":\"4009\",\"country\":\"PH\",\"phone\":\"09191234567\"}', 'pending', 0.00, '2026-10-17 07:13:31', NULL, '2026-10-17 07:13:31', '2026-10-17 07:13:31'),
(44, 1, 'intake-sc-7af1b9af-05be-45cd-bc8f-6ec2cdeaa97f', NULL, 'Clara Rivera', NULL, '{\"line1\":\"Brgy. Santisima Cruz, Santa Cruz\",\"city\":\"Santa Cruz\",\"state\":\"Laguna\",\"postal_code\":\"4009\",\"country\":\"PH\",\"phone\":\"09201234567\"}', 'pending', 0.00, '2026-10-17 07:13:31', NULL, '2026-10-17 07:13:31', '2026-10-17 07:13:31'),
(45, 1, 'intake-sc-5d7790b9-94c1-4071-a375-1b1b01828394', NULL, 'Ferdinand Marcos', NULL, '{\"line1\":\"Brgy. Bubukal, Santa Cruz\",\"city\":\"Santa Cruz\",\"state\":\"Laguna\",\"postal_code\":\"4009\",\"country\":\"PH\",\"phone\":\"09211234567\"}', 'pending', 0.00, '2026-10-17 07:13:31', NULL, '2026-10-17 07:13:31', '2026-10-17 07:13:31'),
(46, 1, 'intake-34f3dbcc-08f3-4f8f-b58c-036685ad0768', NULL, 'Intake Package', NULL, '{\"line1\":\"Delivery destination, Santa Cruz, Laguna\",\"city\":\"Santa Cruz\",\"state\":\"Laguna\",\"postal_code\":\"4009\",\"country\":\"PH\",\"phone\":\"09170000000\"}', 'pending', 0.00, '2026-10-19 16:27:47', '{\"source\":\"parcel_intake\"}', '2026-10-19 16:27:47', '2026-10-19 16:27:47'),
(47, 1, 'intake-a1df1739-dfaa-4962-bfd3-eda4cea4ddb1', NULL, 'totoy', NULL, '{\"line1\":\"brgy,bbn\",\"city\":\"pila\",\"state\":\"Laguna\",\"postal_code\":\"4010\",\"country\":\"PH\",\"phone\":\"09755667472\"}', 'pending', 0.00, '2026-10-30 16:27:35', '{\"source\":\"parcel_intake\"}', '2026-10-30 16:27:35', '2026-10-30 16:27:35'),
(48, 1, 'intake-3ad5d8e2-46bf-4727-a93d-a68828d64097', NULL, 'Intake Package', NULL, '{\"line1\":\"Delivery destination, Santa Cruz, Laguna\",\"city\":\"Santa Cruz\",\"state\":\"Laguna\",\"postal_code\":\"4009\",\"country\":\"PH\",\"phone\":\"09170000000\"}', 'pending', 0.00, '2026-10-30 18:47:33', '{\"source\":\"parcel_intake\"}', '2026-10-30 18:47:33', '2026-10-30 18:47:33');

-- --------------------------------------------------------

--
-- Table structure for table `order_items`
--

CREATE TABLE `order_items` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `order_id` bigint(20) UNSIGNED NOT NULL,
  `external_id` varchar(255) DEFAULT NULL,
  `sku` varchar(255) DEFAULT NULL,
  `name` varchar(255) NOT NULL,
  `quantity` int(10) UNSIGNED NOT NULL DEFAULT 1,
  `quantity_fulfilled` int(10) UNSIGNED NOT NULL DEFAULT 0,
  `unit_price` decimal(12,2) NOT NULL DEFAULT 0.00,
  `metadata` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`metadata`)),
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `order_items`
--

INSERT INTO `order_items` (`id`, `order_id`, `external_id`, `sku`, `name`, `quantity`, `quantity_fulfilled`, `unit_price`, `metadata`, `created_at`, `updated_at`) VALUES
(1, 1, NULL, 'LUM-SERUM-01', 'Velvet Glow Serum', 1, 0, 48.00, NULL, '2026-08-29 23:00:04', '2026-08-29 23:00:04'),
(2, 2, NULL, 'LUM-SERUM-01', 'Velvet Glow Serum', 2, 0, 48.00, NULL, '2026-08-29 23:00:04', '2026-08-29 23:00:04'),
(3, 3, NULL, 'LUM-SERUM-01', 'Velvet Glow Serum', 1, 0, 48.00, NULL, '2026-08-29 23:00:04', '2026-08-29 23:00:04'),
(4, 4, NULL, 'LUM-SERUM-01', 'Velvet Glow Serum', 2, 0, 48.00, NULL, '2026-08-29 23:00:04', '2026-08-29 23:00:04'),
(5, 5, NULL, 'LUM-SERUM-01', 'Velvet Glow Serum', 1, 0, 48.00, NULL, '2026-08-29 23:00:04', '2026-08-29 23:00:04'),
(6, 6, NULL, 'LUM-SERUM-01', 'Velvet Glow Serum', 2, 0, 48.00, NULL, '2026-08-29 23:00:05', '2026-08-29 23:00:05'),
(7, 7, NULL, 'LUM-SERUM-01', 'Velvet Glow Serum', 1, 0, 48.00, NULL, '2026-08-29 23:00:05', '2026-08-29 23:00:05'),
(8, 8, NULL, 'LUM-SERUM-01', 'Velvet Glow Serum', 2, 0, 48.00, NULL, '2026-08-29 23:00:05', '2026-08-29 23:00:05'),
(9, 9, NULL, 'LUM-SERUM-01', 'Velvet Glow Serum', 1, 0, 48.00, NULL, '2026-08-29 23:00:05', '2026-08-29 23:00:05'),
(10, 10, NULL, 'LUM-SERUM-01', 'Velvet Glow Serum', 2, 0, 48.00, NULL, '2026-08-29 23:00:05', '2026-08-29 23:00:05'),
(11, 11, NULL, 'LUM-SERUM-01', 'Velvet Glow Serum', 1, 0, 48.00, NULL, '2026-08-29 23:00:05', '2026-08-29 23:00:05'),
(12, 12, NULL, 'LUM-SERUM-01', 'Velvet Glow Serum', 2, 0, 48.00, NULL, '2026-08-29 23:00:05', '2026-08-29 23:00:05');

-- --------------------------------------------------------

--
-- Table structure for table `parcels`
--

CREATE TABLE `parcels` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `order_id` bigint(20) UNSIGNED DEFAULT NULL,
  `shipment_id` bigint(20) UNSIGNED DEFAULT NULL,
  `store_id` bigint(20) UNSIGNED NOT NULL,
  `destination_area_id` bigint(20) UNSIGNED DEFAULT NULL,
  `branch` varchar(255) DEFAULT NULL,
  `assigned_rider_id` bigint(20) UNSIGNED DEFAULT NULL,
  `parcel_number` varchar(255) NOT NULL,
  `barcode` varchar(255) DEFAULT NULL,
  `recipient_name` varchar(255) NOT NULL,
  `recipient_phone` varchar(255) DEFAULT NULL,
  `address_line` text DEFAULT NULL,
  `city` varchar(255) DEFAULT NULL,
  `province` varchar(255) DEFAULT NULL,
  `postal_code` varchar(255) DEFAULT NULL,
  `status` varchar(255) NOT NULL DEFAULT 'received',
  `sort_bin` varchar(255) DEFAULT NULL,
  `received_at` timestamp NULL DEFAULT NULL,
  `scanned_at` timestamp NULL DEFAULT NULL,
  `sorted_at` timestamp NULL DEFAULT NULL,
  `assigned_at` timestamp NULL DEFAULT NULL,
  `rider_received_at` timestamp NULL DEFAULT NULL,
  `metadata` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`metadata`)),
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `parcels`
--

INSERT INTO `parcels` (`id`, `order_id`, `shipment_id`, `store_id`, `destination_area_id`, `branch`, `assigned_rider_id`, `parcel_number`, `barcode`, `recipient_name`, `recipient_phone`, `address_line`, `city`, `province`, `postal_code`, `status`, `sort_bin`, `received_at`, `scanned_at`, `sorted_at`, `assigned_at`, `rider_received_at`, `metadata`, `created_at`, `updated_at`) VALUES
(1, 15, 15, 1, 4, 'Pila', 5, 'LM-TRK-000015', '0201909192', 'erin', '09091072577', 'scn', 'Pila', 'Laguna', '4010', 'delivered', NULL, '2026-10-15 00:17:01', NULL, '2026-10-15 00:17:15', '2026-10-15 00:17:31', '2026-10-15 00:18:17', '{\"source\":\"parcel_intake\",\"last_status_code\":\"DELIVERED\",\"latitude\":14.5839,\"longitude\":121.0543,\"last_updated_at\":\"2026-10-15T16:19:12.822893\",\"proof_url\":\"\\/data\\/user\\/0\\/com.example.flutter_app\\/cache\\/scaled_b3efcae5-efab-461c-82bc-7da19166a6817272245853589687629.jpg\",\"cod_amount\":250,\"is_cod\":true}', '2026-10-15 00:17:01', '2026-10-17 07:12:01'),
(2, 16, 16, 1, 4, 'Pila', 5, 'LM-TRK-000016', '039403403', 'totoy', '09101292902', '250 bonifacio st', 'Pila', 'Laguna', '4010', 'delivered', NULL, '2026-10-15 00:51:58', '2026-10-15 00:52:08', '2026-10-15 00:52:16', '2026-10-15 00:54:31', '2026-10-15 00:54:55', '{\"source\":\"parcel_intake\",\"last_status_code\":\"delivered\",\"latitude\":14.5839,\"longitude\":121.0543,\"last_updated_at\":\"2026-10-15T08:56:06+00:00\",\"proof_url\":\"\\/data\\/user\\/0\\/com.example.flutter_app\\/cache\\/scaled_1c6b173b-0dd9-4084-8743-7ec51c4d664d5269596013997934697.jpg\",\"cod_amount\":250,\"is_cod\":true}', '2026-10-15 00:51:58', '2026-10-17 07:12:01'),
(3, 17, 17, 1, 4, 'Pila', 6, 'LM-TRK-000017', '09201920192', 'totoy', '09101292902', 'sta clara norte bonifacio st 250', 'Pila', 'Laguna', '4010', 'delivered', NULL, '2026-10-15 01:16:26', NULL, '2026-10-15 01:16:35', '2026-10-15 01:17:33', '2026-10-15 01:18:35', '{\"source\":\"parcel_intake\",\"last_status_code\":\"delivered\",\"latitude\":14.5839,\"longitude\":121.0543,\"last_updated_at\":\"2026-10-15T09:19:19+00:00\",\"proof_url\":\"\\/data\\/user\\/0\\/com.example.flutter_app\\/cache\\/scaled_9d9acd7f-6ce1-4152-b052-15d3b56aec6a4177975427531147734.jpg\",\"cod_amount\":250,\"is_cod\":true}', '2026-10-15 01:16:26', '2026-10-17 07:12:01'),
(4, 18, 18, 1, 4, 'Pila', 5, 'LM-TRK-000018', '983923772', 'joyce', '09755667472', 'scn', 'Pila', 'Laguna', '4010', 'delivered', NULL, '2026-10-15 01:20:35', NULL, '2026-10-15 01:20:42', '2026-10-15 01:20:55', '2026-10-15 01:21:24', '{\"source\":\"parcel_intake\",\"last_status_code\":\"delivered\",\"latitude\":14.5839,\"longitude\":121.0543,\"last_updated_at\":\"2026-10-15T13:42:29+00:00\",\"proof_url\":\"\\/data\\/user\\/0\\/com.example.flutter_app\\/cache\\/scaled_2234e56c-39b1-48d2-ad91-350996fdc4308252997214523724249.jpg\",\"cod_amount\":250,\"is_cod\":true}', '2026-10-15 01:20:35', '2026-10-17 07:12:01'),
(5, 19, 19, 1, 4, 'Pila', 6, 'LM-TRK-000019', '29382984923942', 'cj', '09755667472', 'brgy,bbn', 'Pila', 'Laguna', '4010', 'delivered', NULL, '2026-10-15 01:23:36', NULL, '2026-10-15 01:23:42', '2026-10-15 01:24:11', '2026-10-15 01:25:04', '{\"source\":\"parcel_intake\",\"last_status_code\":\"delivered\",\"latitude\":14.5839,\"longitude\":121.0543,\"last_updated_at\":\"2026-10-15T09:25:19+00:00\",\"proof_url\":\"\\/data\\/user\\/0\\/com.example.flutter_app\\/cache\\/scaled_3d7377fb-739b-4a66-9602-e28dc10aef551961446248044464858.jpg\",\"cod_amount\":250,\"is_cod\":true}', '2026-10-15 01:23:36', '2026-10-17 07:12:01'),
(6, 20, 20, 1, 4, 'Pila', 5, 'LM-TRK-000020', '988976445', 'ange', '09755667472', 'scn', 'Pila', 'Laguna', '4010', 'delivered', NULL, '2026-10-15 03:02:09', NULL, '2026-10-15 03:02:19', '2026-10-15 03:02:31', '2026-10-15 03:03:15', '{\"source\":\"parcel_intake\",\"last_status_code\":\"delivered\",\"latitude\":14.5839,\"longitude\":121.0543,\"last_updated_at\":\"2026-10-15T11:03:35+00:00\",\"proof_url\":\"\\/data\\/user\\/0\\/com.example.flutter_app\\/cache\\/scaled_fda6e1e7-2b0a-48a5-996c-97024fae33807199897301648072788.jpg\",\"cod_amount\":250,\"is_cod\":true}', '2026-10-15 03:02:09', '2026-10-17 07:12:01'),
(7, 21, 21, 1, 4, 'Pila', 5, 'LM-TRK-000021', 'PKG202610150001', 'cj', '09755667472', 'BONIFACIO ST', 'Pila', 'Laguna', '4010', 'out_for_delivery', NULL, '2026-10-15 06:36:53', NULL, '2026-10-15 06:37:52', '2026-10-15 06:38:25', '2026-10-15 06:56:23', '{\"source\":\"parcel_intake\",\"last_status_code\":\"outForDelivery\",\"latitude\":14.5839,\"longitude\":121.0543,\"last_updated_at\":\"2026-10-15T16:13:01+00:00\"}', '2026-10-15 06:36:53', '2026-10-17 07:12:01'),
(8, 22, 22, 1, 4, 'Pila', 5, 'LM-TRK-000022', '2382738917238', 'joyce', '09755667472', 'brgy,bbn', 'Pila', 'Laguna', '4010', 'out_for_delivery', NULL, '2026-10-15 07:11:15', NULL, '2026-10-15 07:11:40', '2026-10-15 07:11:49', '2026-10-15 07:12:29', '{\"source\":\"parcel_intake\",\"last_status_code\":\"OUT_FOR_DELIVERY\",\"latitude\":14.5839,\"longitude\":121.0543,\"last_updated_at\":\"2026-10-15T23:12:41.263641\"}', '2026-10-15 07:11:15', '2026-10-17 07:12:01'),
(9, 23, 23, 1, 4, 'Pila', 5, 'LM-TRK-000023', '3948294092', 'ange', '09755667472', 'brgy,bbn', 'Pila', 'Laguna', '4010', 'out_for_delivery', NULL, '2026-10-15 07:13:28', NULL, '2026-10-15 07:13:36', '2026-10-15 07:13:43', '2026-10-15 07:19:03', '{\"source\":\"parcel_intake\",\"last_status_code\":\"OUT_FOR_DELIVERY\",\"latitude\":14.5839,\"longitude\":121.0543,\"last_updated_at\":\"2026-10-16T00:12:57.811922\"}', '2026-10-15 07:13:28', '2026-10-17 07:12:01'),
(10, 24, 24, 1, 11, 'Pila', 5, 'LM-TRK-000024', 'PKG202610150003', 'jasenj', '09755667472', 'brgy,bbn', 'Pila', 'Laguna', '4010', 'delivered', NULL, '2026-10-15 07:44:05', NULL, '2026-10-15 07:44:35', '2026-10-15 08:05:35', '2026-10-15 08:06:24', '{\"source\":\"parcel_intake\",\"last_status_code\":\"delivered\",\"latitude\":14.5839,\"longitude\":121.0543,\"last_updated_at\":\"2026-10-15T16:07:33+00:00\",\"proof_url\":\"\\/data\\/user\\/0\\/com.example.flutter_app\\/cache\\/scaled_fd40fa19-4aa0-4f25-8ed1-943302071b6c7260187452935821775.jpg\",\"cod_amount\":250,\"is_cod\":true}', '2026-10-15 07:44:05', '2026-10-17 07:12:01'),
(11, 25, 25, 1, 4, 'Pila', 5, 'LM-TRK-000025', 'JT002556892205', 'totoy', '09755667472', 'brgy,bbn', 'Pila', 'Laguna', '4010', 'delivered', NULL, '2026-10-15 08:09:20', NULL, '2026-10-15 08:09:27', '2026-10-15 08:09:36', '2026-10-15 08:18:59', '{\"source\":\"parcel_intake\",\"last_status_code\":\"DELIVERED\",\"latitude\":14.5839,\"longitude\":121.0543,\"last_updated_at\":\"2026-10-29T22:10:04.969381\",\"proof_url\":\"\\/data\\/user\\/0\\/com.example.flutter_app\\/cache\\/scaled_0600de26-2e50-4fbc-a5e7-d2e99c31c1206408522494778241100.jpg\",\"cod_amount\":250,\"is_cod\":true}', '2026-10-15 08:09:20', '2026-10-29 06:10:14'),
(12, 26, 26, 1, 4, 'Pila', 5, 'LM-TRK-000026', 'PKG202610150005', 'ange', '09755667472', 'brgy,SCN', 'Pila', 'Laguna', '4010', 'delivered', NULL, '2026-10-15 08:11:06', NULL, '2026-10-15 08:11:14', '2026-10-15 08:11:19', '2026-10-15 08:12:53', '{\"source\":\"parcel_intake\",\"last_status_code\":\"delivered\",\"latitude\":14.5839,\"longitude\":121.0543,\"last_updated_at\":\"2026-10-17T01:45:48+00:00\",\"proof_url\":\"\\/data\\/user\\/0\\/com.example.flutter_app\\/cache\\/scaled_da590ead-e359-4027-8260-0b7d49e0838b8842238284818575045.jpg\",\"cod_amount\":250,\"is_cod\":true}', '2026-10-15 08:11:06', '2026-10-17 07:12:01'),
(13, 27, 27, 1, 4, 'Pila', 5, 'LM-TRK-000027', 'LM-SCAN-TEST-001', 'Intake Package', '09170000000', 'Delivery destination, Santa Cruz, Laguna', 'Pila', 'Laguna', '4009', 'delivered', NULL, '2026-10-15 22:13:13', '2026-10-15 22:13:14', '2026-10-15 23:37:55', '2026-10-15 23:38:09', '2026-10-15 23:39:23', '{\"source\":\"parcel_intake\",\"last_status_code\":\"delivered\",\"latitude\":14.5839,\"longitude\":121.0543,\"last_updated_at\":\"2026-10-16T13:13:11+00:00\",\"proof_url\":\"\\/data\\/user\\/0\\/com.example.flutter_app\\/cache\\/scaled_cc096460-dc5d-4613-9354-4ee0436c81886677733742072222242.jpg\",\"cod_amount\":250,\"is_cod\":true}', '2026-10-15 22:13:13', '2026-10-17 07:12:01'),
(14, 28, 28, 1, NULL, NULL, NULL, 'LM-TRK-000028', 'LM-TEST-OFFLINE-01', 'Intake Package', '09170000000', 'Delivery destination, Santa Cruz, Laguna', 'Santa Cruz', 'Laguna', '4009', 'scanned', NULL, '2026-10-15 23:53:05', '2026-10-15 23:53:05', NULL, NULL, NULL, '{\"source\":\"parcel_intake\"}', '2026-10-15 23:53:05', '2026-10-15 23:53:05'),
(15, 29, 29, 1, NULL, NULL, NULL, 'LM-TRK-000029', 'LM-TEST-OFFLINE-02', 'Intake Package', '09170000000', 'Delivery destination, Santa Cruz, Laguna', 'Santa Cruz', 'Laguna', '4009', 'scanned', NULL, '2026-10-15 23:53:05', '2026-10-15 23:53:05', NULL, NULL, NULL, '{\"source\":\"parcel_intake\"}', '2026-10-15 23:53:05', '2026-10-15 23:53:05'),
(16, 30, 30, 1, NULL, NULL, NULL, 'LM-TRK-000030', 'TEST-BARCODE-999', 'Intake Package', '09170000000', 'Delivery destination, Santa Cruz, Laguna', 'Santa Cruz', 'Laguna', '4009', 'scanned', NULL, '2026-10-16 04:15:49', '2026-10-16 04:15:49', NULL, NULL, NULL, '{\"source\":\"parcel_intake\"}', '2026-10-16 04:15:49', '2026-10-16 04:15:49'),
(17, 31, 31, 1, 11, 'Pila', 5, 'LM-TRK-000031', 'Recipient name: CJ\nPhone: 09755667472\nDelivery address: SCN\nCity/Municipality: Pila\nPostal code: 4010', 'Intake Package', '09170000000', 'Delivery destination, Santa Cruz, Laguna', 'Pila', 'Laguna', '4009', 'delivered', NULL, '2026-10-16 04:40:53', '2026-10-16 04:40:53', '2026-10-16 04:42:32', '2026-10-16 04:42:37', '2026-10-16 04:42:56', '{\"source\":\"parcel_intake\",\"last_status_code\":\"delivered\",\"latitude\":14.5839,\"longitude\":121.0543,\"last_updated_at\":\"2026-10-16T12:43:46+00:00\",\"proof_url\":\"\\/data\\/user\\/0\\/com.example.flutter_app\\/cache\\/scaled_4a938d9e-e8bb-40b0-96ee-4f29525ba7e3473532064298652721.jpg\",\"cod_amount\":250,\"is_cod\":true}', '2026-10-16 04:40:53', '2026-10-17 07:12:01'),
(18, 32, 32, 1, NULL, NULL, NULL, 'LM-TRK-000032', 'WIRELESS-TEST-12345', 'Intake Package', '09170000000', 'Delivery destination, Santa Cruz, Laguna', 'Santa Cruz', 'Laguna', '4009', 'scanned', NULL, '2026-10-16 05:53:58', '2026-10-16 05:53:59', NULL, NULL, NULL, '{\"source\":\"parcel_intake\"}', '2026-10-16 05:53:58', '2026-10-16 05:53:59'),
(20, 34, 34, 1, 10, 'Pila', 6, 'LM-TRK-000034', '87987899', 'joyce', '09755667472', 'brgy,bbn', 'Pila', 'Laguna', '4010', 'delivered', NULL, '2026-10-16 06:11:05', NULL, '2026-10-19 16:21:38', '2026-10-19 16:22:23', '2026-10-19 16:25:54', '{\"source\":\"parcel_intake\",\"last_status_code\":\"delivered\",\"latitude\":14.5839,\"longitude\":121.0543,\"last_updated_at\":\"2026-10-20T00:26:11+00:00\",\"proof_url\":\"\\/data\\/user\\/0\\/com.example.flutter_app\\/cache\\/scaled_0bf4bd47-1fe6-4c9e-bc12-41a05b9d81fc7748809245926900280.jpg\",\"cod_amount\":250,\"is_cod\":true}', '2026-10-16 06:11:05', '2026-10-19 16:26:11'),
(21, 35, 35, 1, NULL, NULL, NULL, 'LM-TRK-000035', 'PKG202610150007', 'Intake Package', '09170000000', 'Delivery destination, Santa Cruz, Laguna', 'Santa Cruz', 'Laguna', '4009', 'scanned', NULL, '2026-10-16 06:14:12', '2026-10-16 06:14:12', NULL, NULL, NULL, '{\"source\":\"parcel_intake\"}', '2026-10-16 06:14:12', '2026-10-16 06:14:12'),
(22, 36, 36, 1, NULL, NULL, NULL, 'LM-TRK-000036', 'PKG202610150020', 'Intake Package', '09170000000', 'Delivery destination, Santa Cruz, Laguna', 'Santa Cruz', 'Laguna', '4009', 'scanned', NULL, '2026-10-16 06:14:12', '2026-10-16 06:14:12', NULL, NULL, NULL, '{\"source\":\"parcel_intake\"}', '2026-10-16 06:14:12', '2026-10-16 06:14:12'),
(23, 37, 37, 1, 4, 'Pila', 5, 'LM-TRK-000037', 'PKG202610150016', 'Intake Package', '09170000000', 'Delivery destination, Santa Cruz, Laguna', 'Pila', 'Laguna', '4009', 'delivered', NULL, '2026-10-16 06:14:38', '2026-10-16 06:14:38', '2026-10-16 06:15:50', '2026-10-16 06:16:00', '2026-10-16 06:16:21', '{\"source\":\"parcel_intake\",\"last_status_code\":\"DELIVERED\",\"latitude\":14.5839,\"longitude\":121.0543,\"last_updated_at\":\"2026-10-16T22:17:00.278834\",\"proof_url\":\"\\/data\\/user\\/0\\/com.example.flutter_app\\/cache\\/scaled_c85af338-b519-4a0d-94f5-0b615c195adc8689276335002630979.jpg\",\"cod_amount\":250,\"is_cod\":true}', '2026-10-16 06:14:38', '2026-10-17 07:12:01'),
(24, 38, 38, 1, 10, 'Pila', 6, 'LM-TRK-000038', 'PKG202610150014', 'Intake Package', '09170000000', 'Delivery destination, Santa Cruz, Laguna', 'Pila', 'Laguna', '4009', 'delivered', NULL, '2026-10-16 06:22:07', '2026-10-16 06:22:07', '2026-10-16 06:22:23', '2026-10-16 06:22:30', '2026-10-16 06:23:05', '{\"source\":\"parcel_intake\",\"last_status_code\":\"delivered\",\"latitude\":14.5839,\"longitude\":121.0543,\"last_updated_at\":\"2026-10-16T14:24:03+00:00\",\"proof_url\":\"\\/data\\/user\\/0\\/com.example.flutter_app\\/cache\\/scaled_6eab8932-38aa-4d66-8175-9e37e90302127840280559731713811.jpg\",\"cod_amount\":250,\"is_cod\":true}', '2026-10-16 06:22:07', '2026-10-17 07:12:01'),
(25, 39, 39, 1, NULL, NULL, NULL, 'LM-TRK-000039', 'PKG202610150010', 'Intake Package', '09170000000', 'Delivery destination, Santa Cruz, Laguna', 'Santa Cruz', 'Laguna', '4009', 'scanned', NULL, '2026-10-16 17:03:48', '2026-10-16 17:03:48', NULL, NULL, NULL, '{\"source\":\"parcel_intake\"}', '2026-10-16 17:03:48', '2026-10-16 17:03:48'),
(26, 40, 40, 1, 10, 'Pila', 5, 'LM-TRK-000040', 'PKG202610150004', 'Intake Package', '09170000000', 'Delivery destination, Santa Cruz, Laguna', 'Pila', 'Laguna', '4009', 'delivered', NULL, '2026-10-16 17:05:17', '2026-10-16 17:05:17', '2026-10-16 17:05:34', '2026-10-16 17:05:46', '2026-10-16 17:06:14', '{\"source\":\"parcel_intake\",\"last_status_code\":\"DELIVERED\",\"latitude\":14.5839,\"longitude\":121.0543,\"last_updated_at\":\"2026-10-17T09:07:06.685648\",\"proof_url\":\"\\/data\\/user\\/0\\/com.example.flutter_app\\/cache\\/scaled_b21de4df-bc2c-4309-92d9-4ff1bd5477ae3897314725947294125.jpg\",\"cod_amount\":250,\"is_cod\":true}', '2026-10-16 17:05:17', '2026-10-17 07:12:01'),
(27, 41, 41, 1, 1, 'Santa Cruz', NULL, 'LM-TRK-000041', 'SC-BARCODE-100', 'Maria Santos', '09171234567', 'Brgy. Sto. Angel Central, Santa Cruz', 'Santa Cruz', 'Laguna', '4009', 'received', NULL, '2026-10-17 07:13:31', NULL, NULL, NULL, NULL, NULL, '2026-10-17 07:13:31', '2026-10-17 07:13:31'),
(28, 42, 42, 1, 1, 'Santa Cruz', NULL, 'LM-TRK-000042', 'SC-BARCODE-101', 'Juan Dela Cruz', '09181234567', 'Poblacion IV, Santa Cruz', 'Santa Cruz', 'Laguna', '4009', 'scanned', NULL, '2026-10-17 07:13:31', '2026-10-17 07:13:31', NULL, NULL, NULL, NULL, '2026-10-17 07:13:31', '2026-10-17 07:13:31'),
(29, 43, 43, 1, 1, 'Santa Cruz', NULL, 'LM-TRK-000043', 'SC-BARCODE-102', 'Ricardo Dalisay', '09191234567', 'Brgy. Bagumbayan, Santa Cruz', 'Santa Cruz', 'Laguna', '4009', 'sorted', 'BIN-SC-01', '2026-10-17 07:13:31', '2026-10-17 07:13:31', '2026-10-17 07:13:31', NULL, NULL, NULL, '2026-10-17 07:13:31', '2026-10-17 07:13:31'),
(30, 44, 44, 1, 1, 'Santa Cruz', 1, 'LM-TRK-000044', 'SC-BARCODE-103', 'Clara Rivera', '09201234567', 'Brgy. Santisima Cruz, Santa Cruz', 'Santa Cruz', 'Laguna', '4009', 'delivered', 'BIN-SC-02', '2026-10-17 07:13:31', '2026-10-17 07:13:31', '2026-10-17 07:13:31', '2026-10-17 07:13:31', '2026-10-30 18:50:18', '{\"last_status_code\":\"delivered\",\"latitude\":14.5839,\"longitude\":121.0543,\"last_updated_at\":\"2026-10-31T02:50:36+00:00\",\"proof_url\":\"\\/data\\/user\\/0\\/com.example.flutter_app\\/cache\\/scaled_9d0aa92a-786d-49e6-9184-e1db837d23df5648038163278201520.jpg\",\"cod_amount\":250,\"is_cod\":true}', '2026-10-17 07:13:31', '2026-10-30 18:50:36'),
(31, 45, 45, 1, 1, 'Santa Cruz', 1, 'LM-TRK-000045', 'SC-BARCODE-104', 'Ferdinand Marcos', '09211234567', 'Brgy. Bubukal, Santa Cruz', 'Santa Cruz', 'Laguna', '4009', 'delivered', 'BIN-SC-03', '2026-10-17 07:13:31', '2026-10-17 07:13:31', '2026-10-17 07:13:31', '2026-10-17 07:13:31', NULL, NULL, '2026-10-17 07:13:31', '2026-10-17 07:13:31'),
(32, 46, 46, 1, 1, NULL, NULL, 'LM-TRK-000046', 'PKG202610150008', 'Intake Package', '09170000000', 'Delivery destination, Santa Cruz, Laguna', 'Santa Cruz', 'Laguna', '4009', 'scanned', NULL, '2026-10-19 16:27:47', '2026-10-19 16:27:47', NULL, NULL, NULL, '{\"source\":\"parcel_intake\"}', '2026-10-19 16:27:47', '2026-10-19 16:27:47'),
(33, 47, 47, 1, 11, 'Pila', 5, 'LM-TRK-000047', '02030122', 'totoy', '09755667472', 'brgy,bbn', 'pila', 'Laguna', '4010', 'delivered', NULL, '2026-10-30 16:27:35', NULL, '2026-10-30 16:27:54', '2026-10-30 16:28:02', '2026-10-30 16:30:33', '{\"source\":\"parcel_intake\",\"last_status_code\":\"delivered\",\"latitude\":14.5839,\"longitude\":121.0543,\"last_updated_at\":\"2026-10-31T02:44:47+00:00\",\"proof_url\":\"\\/data\\/user\\/0\\/com.example.flutter_app\\/cache\\/scaled_fdf3088c-3654-4890-b8cd-4ade75bb8d793730984049668311162.jpg\",\"cod_amount\":250,\"is_cod\":true}', '2026-10-30 16:27:35', '2026-10-30 18:44:47'),
(34, 48, 48, 1, 1, NULL, NULL, 'LM-TRK-000048', 'PKG202610150015', 'Intake Package', '09170000000', 'Delivery destination, Santa Cruz, Laguna', 'Santa Cruz', 'Laguna', '4009', 'scanned', NULL, '2026-10-30 18:47:33', '2026-10-30 18:47:33', NULL, NULL, NULL, '{\"source\":\"parcel_intake\"}', '2026-10-30 18:47:33', '2026-10-30 18:47:33');

-- --------------------------------------------------------

--
-- Table structure for table `parcel_scans`
--

CREATE TABLE `parcel_scans` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `parcel_id` bigint(20) UNSIGNED NOT NULL,
  `user_id` bigint(20) UNSIGNED DEFAULT NULL,
  `scan_type` varchar(255) NOT NULL,
  `barcode` varchar(255) DEFAULT NULL,
  `result` varchar(255) NOT NULL DEFAULT 'success',
  `note` text DEFAULT NULL,
  `scanned_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `parcel_scans`
--

INSERT INTO `parcel_scans` (`id`, `parcel_id`, `user_id`, `scan_type`, `barcode`, `result`, `note`, `scanned_at`, `created_at`, `updated_at`) VALUES
(1, 1, 1, 'receive', '0201909192', 'success', NULL, '2026-10-15 00:17:01', '2026-10-15 00:17:01', '2026-10-15 00:17:01'),
(2, 1, 1, 'sort', NULL, 'success', 'Sorted to bin unassigned', '2026-10-15 00:17:15', '2026-10-15 00:17:15', '2026-10-15 00:17:15'),
(3, 1, 1, 'assign', NULL, 'success', 'Assigned to cj rubiales', '2026-10-15 00:17:31', '2026-10-15 00:17:31', '2026-10-15 00:17:31'),
(4, 1, 7, 'out_for_delivery', '0201909192', 'success', 'Status updated to Out For Delivery by rider cj rubiales [GPS: 14.5839, 121.0543]', '2026-10-15 00:18:17', '2026-10-15 00:18:17', '2026-10-15 00:18:17'),
(5, 1, 7, 'out_for_delivery', '0201909192', 'success', 'Status updated to Out For Delivery by rider cj rubiales [GPS: 14.5839, 121.0543]', '2026-10-15 00:18:18', '2026-10-15 00:18:18', '2026-10-15 00:18:18'),
(6, 1, 7, 'out_for_delivery', '0201909192', 'success', 'Status updated to Out For Delivery by rider cj rubiales [GPS: 14.5839, 121.0543]', '2026-10-15 00:18:22', '2026-10-15 00:18:22', '2026-10-15 00:18:22'),
(7, 1, 7, 'delivered', '0201909192', 'success', 'Status updated to Delivered by rider cj rubiales [GPS: 14.5839, 121.0543]', '2026-10-15 00:19:12', '2026-10-15 00:19:12', '2026-10-15 00:19:12'),
(8, 1, 7, 'delivered', '0201909192', 'success', 'Status updated to Delivered by rider cj rubiales [GPS: 14.5839, 121.0543]', '2026-10-15 00:19:13', '2026-10-15 00:19:13', '2026-10-15 00:19:13'),
(9, 1, 7, 'delivered', '0201909192', 'success', 'Status updated to Delivered by rider cj rubiales [GPS: 14.5839, 121.0543]', '2026-10-15 00:19:17', '2026-10-15 00:19:17', '2026-10-15 00:19:17'),
(10, 2, 1, 'receive', '039403403', 'success', NULL, '2026-10-15 00:51:58', '2026-10-15 00:51:58', '2026-10-15 00:51:58'),
(11, 2, 1, 'scan', '039403403', 'success', NULL, '2026-10-15 00:52:08', '2026-10-15 00:52:08', '2026-10-15 00:52:08'),
(12, 2, 1, 'sort', NULL, 'success', 'Sorted to bin unassigned', '2026-10-15 00:52:16', '2026-10-15 00:52:16', '2026-10-15 00:52:16'),
(13, 2, 1, 'assign', NULL, 'success', 'Assigned to cj rubiales', '2026-10-15 00:54:31', '2026-10-15 00:54:31', '2026-10-15 00:54:31'),
(14, 2, 7, 'out_for_delivery', '039403403', 'success', 'Status updated to Out For Delivery by rider cj rubiales [GPS: 14.5839, 121.0543]', '2026-10-15 00:54:55', '2026-10-15 00:54:55', '2026-10-15 00:54:55'),
(15, 2, 7, 'out_for_delivery', '039403403', 'success', 'Status updated to Out For Delivery by rider cj rubiales [GPS: 14.5839, 121.0543]', '2026-10-15 00:54:56', '2026-10-15 00:54:56', '2026-10-15 00:54:56'),
(16, 2, 7, 'delivered', '039403403', 'success', 'Status updated to Delivered by rider cj rubiales [GPS: 14.5839, 121.0543]', '2026-10-15 00:56:05', '2026-10-15 00:56:05', '2026-10-15 00:56:05'),
(17, 2, 7, 'delivered', '039403403', 'success', 'Status updated to Delivered by rider cj rubiales [GPS: 14.5839, 121.0543]', '2026-10-15 00:56:06', '2026-10-15 00:56:06', '2026-10-15 00:56:06'),
(18, 3, 1, 'receive', '09201920192', 'success', NULL, '2026-10-15 01:16:26', '2026-10-15 01:16:26', '2026-10-15 01:16:26'),
(19, 3, 1, 'sort', NULL, 'success', 'Sorted to bin unassigned', '2026-10-15 01:16:35', '2026-10-15 01:16:35', '2026-10-15 01:16:35'),
(20, 3, 1, 'assign', NULL, 'success', 'Assigned to jasen jumarang', '2026-10-15 01:17:33', '2026-10-15 01:17:33', '2026-10-15 01:17:33'),
(21, 3, 8, 'out_for_delivery', '09201920192', 'success', 'Status updated to Out For Delivery by rider jasen jumarang [GPS: 14.5839, 121.0543]', '2026-10-15 01:18:35', '2026-10-15 01:18:35', '2026-10-15 01:18:35'),
(22, 3, 8, 'out_for_delivery', '09201920192', 'success', 'Status updated to Out For Delivery by rider jasen jumarang [GPS: 14.5839, 121.0543]', '2026-10-15 01:18:36', '2026-10-15 01:18:36', '2026-10-15 01:18:36'),
(23, 3, 8, 'delivered', '09201920192', 'success', 'Status updated to Delivered by rider jasen jumarang [GPS: 14.5839, 121.0543]', '2026-10-15 01:19:19', '2026-10-15 01:19:19', '2026-10-15 01:19:19'),
(24, 3, 8, 'delivered', '09201920192', 'success', 'Status updated to Delivered by rider jasen jumarang [GPS: 14.5839, 121.0543]', '2026-10-15 01:19:19', '2026-10-15 01:19:19', '2026-10-15 01:19:19'),
(25, 4, 1, 'receive', '983923772', 'success', NULL, '2026-10-15 01:20:35', '2026-10-15 01:20:35', '2026-10-15 01:20:35'),
(26, 4, 1, 'sort', NULL, 'success', 'Sorted to bin unassigned', '2026-10-15 01:20:42', '2026-10-15 01:20:42', '2026-10-15 01:20:42'),
(27, 4, 1, 'assign', NULL, 'success', 'Assigned to cj rubiales', '2026-10-15 01:20:55', '2026-10-15 01:20:55', '2026-10-15 01:20:55'),
(28, 4, 7, 'out_for_delivery', '983923772', 'success', 'Status updated to Out For Delivery by rider cj rubiales [GPS: 14.5839, 121.0543]', '2026-10-15 01:21:24', '2026-10-15 01:21:24', '2026-10-15 01:21:24'),
(29, 4, 7, 'out_for_delivery', '983923772', 'success', 'Status updated to Out For Delivery by rider cj rubiales [GPS: 14.5839, 121.0543]', '2026-10-15 01:21:26', '2026-10-15 01:21:26', '2026-10-15 01:21:26'),
(30, 4, 7, 'out_for_delivery', '983923772', 'success', 'Status updated to Out For Delivery by rider cj rubiales [GPS: 14.5839, 121.0543]', '2026-10-15 01:21:33', '2026-10-15 01:21:33', '2026-10-15 01:21:33'),
(31, 5, 1, 'receive', '29382984923942', 'success', NULL, '2026-10-15 01:23:36', '2026-10-15 01:23:36', '2026-10-15 01:23:36'),
(32, 5, 1, 'sort', NULL, 'success', 'Sorted to bin unassigned', '2026-10-15 01:23:42', '2026-10-15 01:23:42', '2026-10-15 01:23:42'),
(33, 5, 1, 'assign', NULL, 'success', 'Assigned to jasen jumarang', '2026-10-15 01:24:11', '2026-10-15 01:24:11', '2026-10-15 01:24:11'),
(34, 5, 8, 'out_for_delivery', '29382984923942', 'success', 'Status updated to Out For Delivery by rider jasen jumarang [GPS: 14.5839, 121.0543]', '2026-10-15 01:25:04', '2026-10-15 01:25:04', '2026-10-15 01:25:04'),
(35, 5, 8, 'out_for_delivery', '29382984923942', 'success', 'Status updated to Out For Delivery by rider jasen jumarang [GPS: 14.5839, 121.0543]', '2026-10-15 01:25:05', '2026-10-15 01:25:05', '2026-10-15 01:25:05'),
(36, 5, 8, 'out_for_delivery', '29382984923942', 'success', 'Status updated to Out For Delivery by rider jasen jumarang [GPS: 14.5839, 121.0543]', '2026-10-15 01:25:11', '2026-10-15 01:25:11', '2026-10-15 01:25:11'),
(37, 5, 8, 'delivered', '29382984923942', 'success', 'Status updated to Delivered by rider jasen jumarang [GPS: 14.5839, 121.0543]', '2026-10-15 01:25:18', '2026-10-15 01:25:18', '2026-10-15 01:25:18'),
(38, 5, 8, 'delivered', '29382984923942', 'success', 'Status updated to Delivered by rider jasen jumarang [GPS: 14.5839, 121.0543]', '2026-10-15 01:25:19', '2026-10-15 01:25:19', '2026-10-15 01:25:19'),
(39, 6, 1, 'receive', '988976445', 'success', NULL, '2026-10-15 03:02:09', '2026-10-15 03:02:09', '2026-10-15 03:02:09'),
(40, 6, 1, 'sort', NULL, 'success', 'Sorted to bin unassigned', '2026-10-15 03:02:20', '2026-10-15 03:02:20', '2026-10-15 03:02:20'),
(41, 6, 1, 'assign', NULL, 'success', 'Assigned to cj rubiales', '2026-10-15 03:02:31', '2026-10-15 03:02:31', '2026-10-15 03:02:31'),
(42, 6, 7, 'out_for_delivery', '988976445', 'success', 'Status updated to Out For Delivery by rider cj rubiales [GPS: 14.5839, 121.0543]', '2026-10-15 03:03:15', '2026-10-15 03:03:15', '2026-10-15 03:03:15'),
(43, 6, 7, 'out_for_delivery', '988976445', 'success', 'Status updated to Out For Delivery by rider cj rubiales [GPS: 14.5839, 121.0543]', '2026-10-15 03:03:16', '2026-10-15 03:03:16', '2026-10-15 03:03:16'),
(44, 6, 7, 'delivered', '988976445', 'success', 'Status updated to Delivered by rider cj rubiales [GPS: 14.5839, 121.0543]', '2026-10-15 03:03:34', '2026-10-15 03:03:34', '2026-10-15 03:03:34'),
(45, 6, 7, 'delivered', '988976445', 'success', 'Status updated to Delivered by rider cj rubiales [GPS: 14.5839, 121.0543]', '2026-10-15 03:03:35', '2026-10-15 03:03:35', '2026-10-15 03:03:35'),
(46, 4, 7, 'delivered', '983923772', 'success', 'Status updated to Delivered by rider cj rubiales [GPS: 14.5839, 121.0543]', '2026-10-15 05:42:29', '2026-10-15 05:42:29', '2026-10-15 05:42:29'),
(47, 4, 7, 'delivered', '983923772', 'success', 'Status updated to Delivered by rider cj rubiales [GPS: 14.5839, 121.0543]', '2026-10-15 05:42:29', '2026-10-15 05:42:29', '2026-10-15 05:42:29'),
(48, 7, 1, 'receive', 'PKG202610150001', 'success', NULL, '2026-10-15 06:36:53', '2026-10-15 06:36:53', '2026-10-15 06:36:53'),
(49, 7, 1, 'sort', NULL, 'success', 'Sorted to bin unassigned', '2026-10-15 06:37:34', '2026-10-15 06:37:34', '2026-10-15 06:37:34'),
(50, 7, 1, 'sort', NULL, 'success', 'Sorted to bin unassigned', '2026-10-15 06:37:52', '2026-10-15 06:37:52', '2026-10-15 06:37:52'),
(51, 7, 1, 'assign', NULL, 'success', 'Assigned to cj rubiales', '2026-10-15 06:38:25', '2026-10-15 06:38:25', '2026-10-15 06:38:25'),
(52, 7, 7, 'rider_received', 'PKG202610150001', 'success', 'Status updated to Rider Received by rider cj rubiales [GPS: 14.5839, 121.0543]', '2026-10-15 06:56:23', '2026-10-15 06:56:23', '2026-10-15 06:56:23'),
(53, 7, 7, 'rider_received', 'PKG202610150001', 'success', 'Status updated to Rider Received by rider cj rubiales [GPS: 14.5839, 121.0543]', '2026-10-15 06:56:23', '2026-10-15 06:56:23', '2026-10-15 06:56:23'),
(54, 7, 7, 'rider_received', 'PKG202610150001', 'success', 'Status updated to Rider Received by rider cj rubiales [GPS: 14.5839, 121.0543]', '2026-10-15 06:56:24', '2026-10-15 06:56:24', '2026-10-15 06:56:24'),
(55, 7, 7, 'rider_received', 'PKG202610150001', 'success', 'Status updated to Rider Received by rider cj rubiales [GPS: 14.5839, 121.0543]', '2026-10-15 06:56:25', '2026-10-15 06:56:25', '2026-10-15 06:56:25'),
(56, 8, 1, 'receive', '2382738917238', 'success', NULL, '2026-10-15 07:11:15', '2026-10-15 07:11:15', '2026-10-15 07:11:15'),
(57, 8, 1, 'sort', NULL, 'success', 'Sorted to bin unassigned', '2026-10-15 07:11:40', '2026-10-15 07:11:40', '2026-10-15 07:11:40'),
(58, 8, 1, 'assign', NULL, 'success', 'Assigned to cj rubiales', '2026-10-15 07:11:49', '2026-10-15 07:11:49', '2026-10-15 07:11:49'),
(59, 8, 7, 'rider_received', '2382738917238', 'success', 'Status updated to Rider Received by rider cj rubiales [GPS: 14.5839, 121.0543]', '2026-10-15 07:12:29', '2026-10-15 07:12:29', '2026-10-15 07:12:29'),
(60, 8, 7, 'rider_received', '2382738917238', 'success', 'Status updated to Rider Received by rider cj rubiales [GPS: 14.5839, 121.0543]', '2026-10-15 07:12:29', '2026-10-15 07:12:29', '2026-10-15 07:12:29'),
(61, 8, 7, 'out_for_delivery', '2382738917238', 'success', 'Status updated to Out For Delivery by rider cj rubiales [GPS: 14.5839, 121.0543]', '2026-10-15 07:12:42', '2026-10-15 07:12:42', '2026-10-15 07:12:42'),
(62, 8, 7, 'out_for_delivery', '2382738917238', 'success', 'Status updated to Out For Delivery by rider cj rubiales [GPS: 14.5839, 121.0543]', '2026-10-15 07:12:43', '2026-10-15 07:12:43', '2026-10-15 07:12:43'),
(63, 8, 7, 'out_for_delivery', '2382738917238', 'success', 'Status updated to Out For Delivery by rider cj rubiales [GPS: 14.5839, 121.0543]', '2026-10-15 07:12:49', '2026-10-15 07:12:49', '2026-10-15 07:12:49'),
(64, 9, 1, 'receive', '3948294092', 'success', NULL, '2026-10-15 07:13:28', '2026-10-15 07:13:28', '2026-10-15 07:13:28'),
(65, 9, 1, 'sort', NULL, 'success', 'Sorted to bin unassigned', '2026-10-15 07:13:36', '2026-10-15 07:13:36', '2026-10-15 07:13:36'),
(66, 9, 1, 'assign', NULL, 'success', 'Assigned to cj rubiales', '2026-10-15 07:13:43', '2026-10-15 07:13:43', '2026-10-15 07:13:43'),
(67, 9, 7, 'rider_received', '3948294092', 'success', 'Status updated to Rider Received by rider cj rubiales [GPS: 14.5839, 121.0543]', '2026-10-15 07:19:03', '2026-10-15 07:19:03', '2026-10-15 07:19:03'),
(68, 9, 7, 'rider_received', '3948294092', 'success', 'Status updated to Rider Received by rider cj rubiales [GPS: 14.5839, 121.0543]', '2026-10-15 07:19:04', '2026-10-15 07:19:04', '2026-10-15 07:19:04'),
(69, 10, 1, 'receive', 'PKG202610150003', 'success', NULL, '2026-10-15 07:44:05', '2026-10-15 07:44:05', '2026-10-15 07:44:05'),
(70, 10, 1, 'sort', NULL, 'success', 'Sorted to bin unassigned', '2026-10-15 07:44:35', '2026-10-15 07:44:35', '2026-10-15 07:44:35'),
(71, 10, 1, 'assign', NULL, 'success', 'Assigned to cj rubiales', '2026-10-15 08:05:35', '2026-10-15 08:05:35', '2026-10-15 08:05:35'),
(72, 10, 7, 'rider_received', 'PKG202610150003', 'success', 'Status updated to Rider Received by rider cj rubiales [GPS: 14.5839, 121.0543]', '2026-10-15 08:06:24', '2026-10-15 08:06:24', '2026-10-15 08:06:24'),
(73, 10, 7, 'rider_received', 'PKG202610150003', 'success', 'Status updated to Rider Received by rider cj rubiales [GPS: 14.5839, 121.0543]', '2026-10-15 08:06:25', '2026-10-15 08:06:25', '2026-10-15 08:06:25'),
(74, 10, 7, 'rider_received', 'PKG202610150003', 'success', 'Status updated to Rider Received by rider cj rubiales [GPS: 14.5839, 121.0543]', '2026-10-15 08:06:28', '2026-10-15 08:06:28', '2026-10-15 08:06:28'),
(75, 10, 7, 'rider_received', 'PKG202610150003', 'success', 'Status updated to Rider Received by rider cj rubiales [GPS: 14.5839, 121.0543]', '2026-10-15 08:06:29', '2026-10-15 08:06:29', '2026-10-15 08:06:29'),
(76, 10, 7, 'rider_received', 'PKG202610150003', 'success', 'Status updated to Rider Received by rider cj rubiales [GPS: 14.5839, 121.0543]', '2026-10-15 08:06:34', '2026-10-15 08:06:34', '2026-10-15 08:06:34'),
(77, 10, 7, 'out_for_delivery', 'PKG202610150003', 'success', 'Status updated to Out For Delivery by rider cj rubiales [GPS: 14.5839, 121.0543]', '2026-10-15 08:07:12', '2026-10-15 08:07:12', '2026-10-15 08:07:12'),
(78, 10, 7, 'out_for_delivery', 'PKG202610150003', 'success', 'Status updated to Out For Delivery by rider cj rubiales [GPS: 14.5839, 121.0543]', '2026-10-15 08:07:13', '2026-10-15 08:07:13', '2026-10-15 08:07:13'),
(79, 10, 7, 'delivered', 'PKG202610150003', 'success', 'Status updated to Delivered by rider cj rubiales [GPS: 14.5839, 121.0543]', '2026-10-15 08:07:32', '2026-10-15 08:07:32', '2026-10-15 08:07:32'),
(80, 10, 7, 'delivered', 'PKG202610150003', 'success', 'Status updated to Delivered by rider cj rubiales [GPS: 14.5839, 121.0543]', '2026-10-15 08:07:33', '2026-10-15 08:07:33', '2026-10-15 08:07:33'),
(81, 11, 1, 'receive', 'JT002556892205', 'success', NULL, '2026-10-15 08:09:20', '2026-10-15 08:09:20', '2026-10-15 08:09:20'),
(82, 11, 1, 'sort', NULL, 'success', 'Sorted to bin unassigned', '2026-10-15 08:09:27', '2026-10-15 08:09:27', '2026-10-15 08:09:27'),
(83, 11, 1, 'assign', NULL, 'success', 'Assigned to cj rubiales', '2026-10-15 08:09:36', '2026-10-15 08:09:36', '2026-10-15 08:09:36'),
(84, 12, 1, 'receive', 'PKG202610150005', 'success', NULL, '2026-10-15 08:11:06', '2026-10-15 08:11:06', '2026-10-15 08:11:06'),
(85, 12, 1, 'sort', NULL, 'success', 'Sorted to bin unassigned', '2026-10-15 08:11:14', '2026-10-15 08:11:14', '2026-10-15 08:11:14'),
(86, 12, 1, 'assign', NULL, 'success', 'Assigned to cj rubiales', '2026-10-15 08:11:19', '2026-10-15 08:11:19', '2026-10-15 08:11:19'),
(87, 12, 7, 'rider_received', 'PKG202610150005', 'success', 'Status updated to Rider Received by rider cj rubiales [GPS: 14.5839, 121.0543]', '2026-10-15 08:12:53', '2026-10-15 08:12:53', '2026-10-15 08:12:53'),
(88, 12, 7, 'rider_received', 'PKG202610150005', 'success', 'Status updated to Rider Received by rider cj rubiales [GPS: 14.5839, 121.0543]', '2026-10-15 08:12:54', '2026-10-15 08:12:54', '2026-10-15 08:12:54'),
(89, 12, 7, 'rider_received', 'PKG202610150005', 'success', 'Status updated to Rider Received by rider cj rubiales [GPS: 14.5839, 121.0543]', '2026-10-15 08:12:57', '2026-10-15 08:12:57', '2026-10-15 08:12:57'),
(90, 12, 7, 'rider_received', 'PKG202610150005', 'success', 'Status updated to Rider Received by rider cj rubiales [GPS: 14.5839, 121.0543]', '2026-10-15 08:12:58', '2026-10-15 08:12:58', '2026-10-15 08:12:58'),
(91, 9, 7, 'out_for_delivery', '3948294092', 'success', 'Status updated to Out For Delivery by rider cj rubiales [GPS: 14.5839, 121.0543]', '2026-10-15 08:12:58', '2026-10-15 08:12:58', '2026-10-15 08:12:58'),
(92, 12, 7, 'rider_received', 'PKG202610150005', 'success', 'Status updated to Rider Received by rider cj rubiales [GPS: 14.5839, 121.0543]', '2026-10-15 08:12:59', '2026-10-15 08:12:59', '2026-10-15 08:12:59'),
(93, 9, 7, 'out_for_delivery', '3948294092', 'success', 'Status updated to Out For Delivery by rider cj rubiales [GPS: 14.5839, 121.0543]', '2026-10-15 08:12:59', '2026-10-15 08:12:59', '2026-10-15 08:12:59'),
(94, 7, 7, 'out_for_delivery', 'PKG202610150001', 'success', 'Status updated to Out For Delivery by rider cj rubiales [GPS: 14.5839, 121.0543]', '2026-10-15 08:13:00', '2026-10-15 08:13:00', '2026-10-15 08:13:00'),
(95, 7, 7, 'out_for_delivery', 'PKG202610150001', 'success', 'Status updated to Out For Delivery by rider cj rubiales [GPS: 14.5839, 121.0543]', '2026-10-15 08:13:01', '2026-10-15 08:13:01', '2026-10-15 08:13:01'),
(96, 9, 7, 'out_for_delivery', '3948294092', 'success', 'Status updated to Out For Delivery by rider cj rubiales [GPS: 14.5839, 121.0543]', '2026-10-15 08:13:04', '2026-10-15 08:13:04', '2026-10-15 08:13:04'),
(97, 11, 7, 'rider_received', 'JT002556892205', 'success', 'Status updated to Rider Received by rider cj rubiales [GPS: 14.5839, 121.0543]', '2026-10-15 08:18:59', '2026-10-15 08:18:59', '2026-10-15 08:18:59'),
(98, 11, 7, 'rider_received', 'JT002556892205', 'success', 'Status updated to Rider Received by rider cj rubiales [GPS: 14.5839, 121.0543]', '2026-10-15 08:18:59', '2026-10-15 08:18:59', '2026-10-15 08:18:59'),
(99, 12, 7, 'out_for_delivery', 'PKG202610150005', 'success', 'Status updated to Out For Delivery by rider cj rubiales [GPS: 14.5839, 121.0543]', '2026-10-15 18:32:28', '2026-10-15 18:32:28', '2026-10-15 18:32:28'),
(100, 12, 7, 'out_for_delivery', 'PKG202610150005', 'success', 'Status updated to Out For Delivery by rider cj rubiales [GPS: 14.5839, 121.0543]', '2026-10-15 18:32:29', '2026-10-15 18:32:29', '2026-10-15 18:32:29'),
(101, 12, 7, 'out_for_delivery', 'PKG202610150005', 'success', 'Status updated to Out For Delivery by rider cj rubiales [GPS: 14.5839, 121.0543]', '2026-10-15 18:32:39', '2026-10-15 18:32:39', '2026-10-15 18:32:39'),
(102, 13, 1, 'receive', 'LM-SCAN-TEST-001', 'success', NULL, '2026-10-15 22:13:13', '2026-10-15 22:13:13', '2026-10-15 22:13:13'),
(103, 13, 1, 'scanner_app_intake', 'LM-SCAN-TEST-001', 'success', 'New intake scan by Mobile Scanner. Sent to sorting center.', '2026-10-15 22:13:14', '2026-10-15 22:13:14', '2026-10-15 22:13:14'),
(104, 13, 1, 'camera_scan', 'LM-SCAN-TEST-001', 'success', 'Scanned by Mobile Scanner Station. Status: Scanned', '2026-10-15 22:14:34', '2026-10-15 22:14:34', '2026-10-15 22:14:34'),
(105, 13, 1, 'sort', NULL, 'success', 'Sorted to bin unassigned', '2026-10-15 23:37:55', '2026-10-15 23:37:55', '2026-10-15 23:37:55'),
(106, 13, 1, 'assign', NULL, 'success', 'Assigned to cj rubiales', '2026-10-15 23:38:09', '2026-10-15 23:38:09', '2026-10-15 23:38:09'),
(107, 13, 7, 'rider_received', 'LM-SCAN-TEST-001', 'success', 'Status updated to Rider Received by rider cj rubiales [GPS: 14.5839, 121.0543]', '2026-10-15 23:39:23', '2026-10-15 23:39:23', '2026-10-15 23:39:23'),
(108, 13, 7, 'rider_received', 'LM-SCAN-TEST-001', 'success', 'Status updated to Rider Received by rider cj rubiales [GPS: 14.5839, 121.0543]', '2026-10-15 23:39:23', '2026-10-15 23:39:23', '2026-10-15 23:39:23'),
(109, 13, 7, 'out_for_delivery', 'LM-SCAN-TEST-001', 'success', 'Status updated to Out For Delivery by rider cj rubiales [GPS: 14.5839, 121.0543]', '2026-10-15 23:39:26', '2026-10-15 23:39:26', '2026-10-15 23:39:26'),
(110, 13, 7, 'out_for_delivery', 'LM-SCAN-TEST-001', 'success', 'Status updated to Out For Delivery by rider cj rubiales [GPS: 14.5839, 121.0543]', '2026-10-15 23:39:26', '2026-10-15 23:39:26', '2026-10-15 23:39:26'),
(111, 11, 7, 'out_for_delivery', 'JT002556892205', 'success', 'Status updated to Out For Delivery by rider cj rubiales [GPS: 14.5839, 121.0543]', '2026-10-15 23:39:27', '2026-10-15 23:39:27', '2026-10-15 23:39:27'),
(112, 11, 7, 'out_for_delivery', 'JT002556892205', 'success', 'Status updated to Out For Delivery by rider cj rubiales [GPS: 14.5839, 121.0543]', '2026-10-15 23:39:28', '2026-10-15 23:39:28', '2026-10-15 23:39:28'),
(113, 14, 1, 'receive', 'LM-TEST-OFFLINE-01', 'success', NULL, '2026-10-15 23:53:05', '2026-10-15 23:53:05', '2026-10-15 23:53:05'),
(114, 14, 1, 'scanner_app_intake', 'LM-TEST-OFFLINE-01', 'success', 'New intake scan by Offline Sync Test. Sent to sorting center.', '2026-10-15 23:53:05', '2026-10-15 23:53:05', '2026-10-15 23:53:05'),
(115, 15, 1, 'receive', 'LM-TEST-OFFLINE-02', 'success', NULL, '2026-10-15 23:53:05', '2026-10-15 23:53:05', '2026-10-15 23:53:05'),
(116, 15, 1, 'scanner_app_intake', 'LM-TEST-OFFLINE-02', 'success', 'New intake scan by Offline Sync Test. Sent to sorting center.', '2026-10-15 23:53:05', '2026-10-15 23:53:05', '2026-10-15 23:53:05'),
(117, 11, 7, 'out_for_delivery', 'JT002556892205', 'success', 'Status updated to Out For Delivery by rider cj rubiales [GPS: 14.5839, 121.0543]', '2026-10-16 03:39:17', '2026-10-16 03:39:17', '2026-10-16 03:39:17'),
(118, 16, 1, 'receive', 'TEST-BARCODE-999', 'success', NULL, '2026-10-16 04:15:49', '2026-10-16 04:15:49', '2026-10-16 04:15:49'),
(119, 16, 1, 'scanner_app_intake', 'TEST-BARCODE-999', 'success', 'New intake scan by Scanner Device. Sent to sorting center.', '2026-10-16 04:15:49', '2026-10-16 04:15:49', '2026-10-16 04:15:49'),
(120, 17, 1, 'receive', 'Recipient name: CJ\nPhone: 09755667472\nDelivery address: SCN\nCity/Municipality: Pila\nPostal code: 4010', 'success', NULL, '2026-10-16 04:40:53', '2026-10-16 04:40:53', '2026-10-16 04:40:53'),
(121, 17, 1, 'scanner_app_intake', 'Recipient name: CJ\nPhone: 09755667472\nDelivery address: SCN\nCity/Municipality: Pila\nPostal code: 4010', 'success', 'New intake scan by Intake Scanner Unit #1. Sent to sorting center.', '2026-10-16 04:40:53', '2026-10-16 04:40:53', '2026-10-16 04:40:53'),
(122, 17, 1, 'sort', NULL, 'success', 'Sorted to bin unassigned', '2026-10-16 04:42:32', '2026-10-16 04:42:32', '2026-10-16 04:42:32'),
(123, 17, 1, 'assign', NULL, 'success', 'Assigned to cj rubiales', '2026-10-16 04:42:37', '2026-10-16 04:42:37', '2026-10-16 04:42:37'),
(124, 17, 7, 'rider_received', 'Recipient name: CJ\nPhone: 09755667472\nDelivery address: SCN\nCity/Municipality: Pila\nPostal code: 4010', 'success', 'Status updated to Rider Received by rider cj rubiales [GPS: 14.5839, 121.0543]', '2026-10-16 04:42:56', '2026-10-16 04:42:56', '2026-10-16 04:42:56'),
(125, 17, 7, 'rider_received', 'Recipient name: CJ\nPhone: 09755667472\nDelivery address: SCN\nCity/Municipality: Pila\nPostal code: 4010', 'success', 'Status updated to Rider Received by rider cj rubiales [GPS: 14.5839, 121.0543]', '2026-10-16 04:42:56', '2026-10-16 04:42:56', '2026-10-16 04:42:56'),
(126, 17, 7, 'rider_received', 'Recipient name: CJ\nPhone: 09755667472\nDelivery address: SCN\nCity/Municipality: Pila\nPostal code: 4010', 'success', 'Status updated to Rider Received by rider cj rubiales [GPS: 14.5839, 121.0543]', '2026-10-16 04:43:00', '2026-10-16 04:43:00', '2026-10-16 04:43:00'),
(127, 17, 7, 'rider_received', 'Recipient name: CJ\nPhone: 09755667472\nDelivery address: SCN\nCity/Municipality: Pila\nPostal code: 4010', 'success', 'Status updated to Rider Received by rider cj rubiales [GPS: 14.5839, 121.0543]', '2026-10-16 04:43:01', '2026-10-16 04:43:01', '2026-10-16 04:43:01'),
(128, 17, 7, 'out_for_delivery', 'Recipient name: CJ\nPhone: 09755667472\nDelivery address: SCN\nCity/Municipality: Pila\nPostal code: 4010', 'success', 'Status updated to Out For Delivery by rider cj rubiales [GPS: 14.5839, 121.0543]', '2026-10-16 04:43:23', '2026-10-16 04:43:23', '2026-10-16 04:43:23'),
(129, 17, 7, 'out_for_delivery', 'Recipient name: CJ\nPhone: 09755667472\nDelivery address: SCN\nCity/Municipality: Pila\nPostal code: 4010', 'success', 'Status updated to Out For Delivery by rider cj rubiales [GPS: 14.5839, 121.0543]', '2026-10-16 04:43:23', '2026-10-16 04:43:23', '2026-10-16 04:43:23'),
(130, 17, 7, 'delivered', 'Recipient name: CJ\nPhone: 09755667472\nDelivery address: SCN\nCity/Municipality: Pila\nPostal code: 4010', 'success', 'Status updated to Delivered by rider cj rubiales [GPS: 14.5839, 121.0543]', '2026-10-16 04:43:45', '2026-10-16 04:43:45', '2026-10-16 04:43:45'),
(131, 17, 7, 'delivered', 'Recipient name: CJ\nPhone: 09755667472\nDelivery address: SCN\nCity/Municipality: Pila\nPostal code: 4010', 'success', 'Status updated to Delivered by rider cj rubiales [GPS: 14.5839, 121.0543]', '2026-10-16 04:43:46', '2026-10-16 04:43:46', '2026-10-16 04:43:46'),
(132, 13, 7, 'delivered', 'LM-SCAN-TEST-001', 'success', 'Status updated to Delivered by rider cj rubiales [GPS: 14.5839, 121.0543]', '2026-10-16 05:12:44', '2026-10-16 05:12:44', '2026-10-16 05:12:44'),
(133, 13, 7, 'delivered', 'LM-SCAN-TEST-001', 'success', 'Status updated to Delivered by rider cj rubiales [GPS: 14.5839, 121.0543]', '2026-10-16 05:13:04', '2026-10-16 05:13:04', '2026-10-16 05:13:04'),
(134, 13, 7, 'delivered', 'LM-SCAN-TEST-001', 'success', 'Status updated to Delivered by rider cj rubiales [GPS: 14.5839, 121.0543]', '2026-10-16 05:13:04', '2026-10-16 05:13:04', '2026-10-16 05:13:04'),
(135, 13, 7, 'delivered', 'LM-SCAN-TEST-001', 'success', 'Status updated to Delivered by rider cj rubiales [GPS: 14.5839, 121.0543]', '2026-10-16 05:13:11', '2026-10-16 05:13:11', '2026-10-16 05:13:11'),
(136, 18, 1, 'receive', 'WIRELESS-TEST-12345', 'success', NULL, '2026-10-16 05:53:59', '2026-10-16 05:53:59', '2026-10-16 05:53:59'),
(137, 18, 1, 'scanner_app_intake', 'WIRELESS-TEST-12345', 'success', 'New intake scan by Scanner Device. Sent to sorting center.', '2026-10-16 05:53:59', '2026-10-16 05:53:59', '2026-10-16 05:53:59'),
(140, 20, 1, 'receive', '87987899', 'success', NULL, '2026-10-16 06:11:05', '2026-10-16 06:11:05', '2026-10-16 06:11:05'),
(141, 21, 1, 'receive', 'PKG202610150007', 'success', NULL, '2026-10-16 06:14:12', '2026-10-16 06:14:12', '2026-10-16 06:14:12'),
(142, 21, 1, 'scanner_app_intake', 'PKG202610150007', 'success', 'New intake scan by Intake Scanner Unit #1. Sent to sorting center.', '2026-10-16 06:14:12', '2026-10-16 06:14:12', '2026-10-16 06:14:12'),
(143, 22, 1, 'receive', 'PKG202610150020', 'success', NULL, '2026-10-16 06:14:12', '2026-10-16 06:14:12', '2026-10-16 06:14:12'),
(144, 22, 1, 'scanner_app_intake', 'PKG202610150020', 'success', 'New intake scan by Intake Scanner Unit #1. Sent to sorting center.', '2026-10-16 06:14:12', '2026-10-16 06:14:12', '2026-10-16 06:14:12'),
(145, 23, 1, 'receive', 'PKG202610150016', 'success', NULL, '2026-10-16 06:14:38', '2026-10-16 06:14:38', '2026-10-16 06:14:38'),
(146, 23, 1, 'scanner_app_intake', 'PKG202610150016', 'success', 'New intake scan by Intake Scanner Unit #1. Sent to sorting center.', '2026-10-16 06:14:38', '2026-10-16 06:14:38', '2026-10-16 06:14:38'),
(147, 23, 1, 'sort', NULL, 'success', 'Sorted to bin unassigned', '2026-10-16 06:15:50', '2026-10-16 06:15:50', '2026-10-16 06:15:50'),
(148, 23, 1, 'assign', NULL, 'success', 'Assigned to cj rubiales', '2026-10-16 06:16:00', '2026-10-16 06:16:00', '2026-10-16 06:16:00'),
(149, 23, 7, 'rider_received', 'PKG202610150016', 'success', 'Status updated to Rider Received by rider cj rubiales [GPS: 14.5839, 121.0543]', '2026-10-16 06:16:21', '2026-10-16 06:16:21', '2026-10-16 06:16:21'),
(150, 23, 7, 'rider_received', 'PKG202610150016', 'success', 'Status updated to Rider Received by rider cj rubiales [GPS: 14.5839, 121.0543]', '2026-10-16 06:16:26', '2026-10-16 06:16:26', '2026-10-16 06:16:26'),
(151, 23, 7, 'rider_received', 'PKG202610150016', 'success', 'Status updated to Rider Received by rider cj rubiales [GPS: 14.5839, 121.0543]', '2026-10-16 06:16:29', '2026-10-16 06:16:29', '2026-10-16 06:16:29'),
(152, 23, 7, 'out_for_delivery', 'PKG202610150016', 'success', 'Status updated to Out For Delivery by rider cj rubiales [GPS: 14.5839, 121.0543]', '2026-10-16 06:16:44', '2026-10-16 06:16:44', '2026-10-16 06:16:44'),
(153, 23, 7, 'out_for_delivery', 'PKG202610150016', 'success', 'Status updated to Out For Delivery by rider cj rubiales [GPS: 14.5839, 121.0543]', '2026-10-16 06:16:47', '2026-10-16 06:16:47', '2026-10-16 06:16:47'),
(154, 23, 7, 'delivered', 'PKG202610150016', 'success', 'Status updated to Delivered by rider cj rubiales [GPS: 14.5839, 121.0543]', '2026-10-16 06:17:01', '2026-10-16 06:17:01', '2026-10-16 06:17:01'),
(155, 23, 7, 'delivered', 'PKG202610150016', 'success', 'Status updated to Delivered by rider cj rubiales [GPS: 14.5839, 121.0543]', '2026-10-16 06:17:03', '2026-10-16 06:17:03', '2026-10-16 06:17:03'),
(156, 23, 7, 'delivered', 'PKG202610150016', 'success', 'Status updated to Delivered by rider cj rubiales [GPS: 14.5839, 121.0543]', '2026-10-16 06:17:10', '2026-10-16 06:17:10', '2026-10-16 06:17:10'),
(157, 24, 1, 'receive', 'PKG202610150014', 'success', NULL, '2026-10-16 06:22:07', '2026-10-16 06:22:07', '2026-10-16 06:22:07'),
(158, 24, 1, 'scanner_app_intake', 'PKG202610150014', 'success', 'New intake scan by Intake Scanner Unit #1. Sent to sorting center.', '2026-10-16 06:22:07', '2026-10-16 06:22:07', '2026-10-16 06:22:07'),
(159, 24, 1, 'sort', NULL, 'success', 'Sorted to bin unassigned', '2026-10-16 06:22:23', '2026-10-16 06:22:23', '2026-10-16 06:22:23'),
(160, 24, 1, 'assign', NULL, 'success', 'Assigned to jasen jumarang', '2026-10-16 06:22:30', '2026-10-16 06:22:30', '2026-10-16 06:22:30'),
(161, 24, 8, 'rider_received', 'PKG202610150014', 'success', 'Status updated to Rider Received by rider jasen jumarang [GPS: 14.5839, 121.0543]', '2026-10-16 06:23:05', '2026-10-16 06:23:05', '2026-10-16 06:23:05'),
(162, 24, 8, 'rider_received', 'PKG202610150014', 'success', 'Status updated to Rider Received by rider jasen jumarang [GPS: 14.5839, 121.0543]', '2026-10-16 06:23:06', '2026-10-16 06:23:06', '2026-10-16 06:23:06'),
(163, 24, 8, 'out_for_delivery', 'PKG202610150014', 'success', 'Status updated to Out For Delivery by rider jasen jumarang [GPS: 14.5839, 121.0543]', '2026-10-16 06:23:20', '2026-10-16 06:23:20', '2026-10-16 06:23:20'),
(164, 24, 8, 'out_for_delivery', 'PKG202610150014', 'success', 'Status updated to Out For Delivery by rider jasen jumarang [GPS: 14.5839, 121.0543]', '2026-10-16 06:23:20', '2026-10-16 06:23:20', '2026-10-16 06:23:20'),
(165, 24, 8, 'delivered', 'PKG202610150014', 'success', 'Status updated to Delivered by rider jasen jumarang [GPS: 14.5839, 121.0543]', '2026-10-16 06:24:03', '2026-10-16 06:24:03', '2026-10-16 06:24:03'),
(166, 24, 8, 'delivered', 'PKG202610150014', 'success', 'Status updated to Delivered by rider jasen jumarang [GPS: 14.5839, 121.0543]', '2026-10-16 06:24:03', '2026-10-16 06:24:03', '2026-10-16 06:24:03'),
(167, 25, 1, 'receive', 'PKG202610150010', 'success', NULL, '2026-10-16 17:03:48', '2026-10-16 17:03:48', '2026-10-16 17:03:48'),
(168, 25, 1, 'scanner_app_intake', 'PKG202610150010', 'success', 'New intake scan by Intake Scanner Unit #1. Sent to sorting center.', '2026-10-16 17:03:48', '2026-10-16 17:03:48', '2026-10-16 17:03:48'),
(169, 26, 1, 'receive', 'PKG202610150004', 'success', NULL, '2026-10-16 17:05:17', '2026-10-16 17:05:17', '2026-10-16 17:05:17'),
(170, 26, 1, 'scanner_app_intake', 'PKG202610150004', 'success', 'New intake scan by Intake Scanner Unit #1. Sent to sorting center.', '2026-10-16 17:05:17', '2026-10-16 17:05:17', '2026-10-16 17:05:17'),
(171, 26, 1, 'sort', NULL, 'success', 'Sorted to bin unassigned', '2026-10-16 17:05:34', '2026-10-16 17:05:34', '2026-10-16 17:05:34'),
(172, 26, 1, 'assign', NULL, 'success', 'Assigned to cj rubiales', '2026-10-16 17:05:47', '2026-10-16 17:05:47', '2026-10-16 17:05:47'),
(173, 26, 7, 'rider_received', 'PKG202610150004', 'success', 'Status updated to Rider Received by rider cj rubiales [GPS: 14.5839, 121.0543]', '2026-10-16 17:06:14', '2026-10-16 17:06:14', '2026-10-16 17:06:14'),
(174, 26, 7, 'rider_received', 'PKG202610150004', 'success', 'Status updated to Rider Received by rider cj rubiales [GPS: 14.5839, 121.0543]', '2026-10-16 17:06:16', '2026-10-16 17:06:16', '2026-10-16 17:06:16'),
(175, 26, 7, 'out_for_delivery', 'PKG202610150004', 'success', 'Status updated to Out For Delivery by rider cj rubiales [GPS: 14.5839, 121.0543]', '2026-10-16 17:06:44', '2026-10-16 17:06:44', '2026-10-16 17:06:44'),
(176, 26, 7, 'out_for_delivery', 'PKG202610150004', 'success', 'Status updated to Out For Delivery by rider cj rubiales [GPS: 14.5839, 121.0543]', '2026-10-16 17:06:46', '2026-10-16 17:06:46', '2026-10-16 17:06:46'),
(177, 26, 7, 'delivered', 'PKG202610150004', 'success', 'Status updated to Delivered by rider cj rubiales [GPS: 14.5839, 121.0543]', '2026-10-16 17:07:09', '2026-10-16 17:07:09', '2026-10-16 17:07:09'),
(178, 26, 7, 'delivered', 'PKG202610150004', 'success', 'Status updated to Delivered by rider cj rubiales [GPS: 14.5839, 121.0543]', '2026-10-16 17:07:11', '2026-10-16 17:07:11', '2026-10-16 17:07:11'),
(179, 26, 7, 'delivered', 'PKG202610150004', 'success', 'Status updated to Delivered by rider cj rubiales [GPS: 14.5839, 121.0543]', '2026-10-16 17:39:56', '2026-10-16 17:39:56', '2026-10-16 17:39:56'),
(180, 26, 7, 'delivered', 'PKG202610150004', 'success', 'Status updated to Delivered by rider cj rubiales [GPS: 14.5839, 121.0543]', '2026-10-16 17:40:04', '2026-10-16 17:40:04', '2026-10-16 17:40:04'),
(181, 26, 7, 'delivered', 'PKG202610150004', 'success', 'Status updated to Delivered by rider cj rubiales [GPS: 14.5839, 121.0543]', '2026-10-16 17:40:10', '2026-10-16 17:40:10', '2026-10-16 17:40:10'),
(182, 26, 7, 'delivered', 'PKG202610150004', 'success', 'Status updated to Delivered by rider cj rubiales [GPS: 14.5839, 121.0543]', '2026-10-16 17:40:14', '2026-10-16 17:40:14', '2026-10-16 17:40:14'),
(183, 26, 7, 'delivered', 'PKG202610150004', 'success', 'Status updated to Delivered by rider cj rubiales [GPS: 14.5839, 121.0543]', '2026-10-16 17:40:42', '2026-10-16 17:40:42', '2026-10-16 17:40:42'),
(184, 12, 7, 'delivered', 'PKG202610150005', 'success', 'Status updated to Delivered by rider cj rubiales [GPS: 14.5839, 121.0543]', '2026-10-16 17:45:48', '2026-10-16 17:45:48', '2026-10-16 17:45:48'),
(185, 12, 7, 'delivered', 'PKG202610150005', 'success', 'Status updated to Delivered by rider cj rubiales [GPS: 14.5839, 121.0543]', '2026-10-16 17:45:48', '2026-10-16 17:45:48', '2026-10-16 17:45:48'),
(186, 20, 1, 'sort', NULL, 'success', 'Sorted to bin unassigned', '2026-10-19 16:21:38', '2026-10-19 16:21:38', '2026-10-19 16:21:38'),
(187, 20, 1, 'assign', NULL, 'success', 'Assigned to jasen jumarang', '2026-10-19 16:22:23', '2026-10-19 16:22:23', '2026-10-19 16:22:23'),
(188, 20, 8, 'out_for_delivery', '87987899', 'success', 'Status updated to Out For Delivery by rider jasen jumarang [GPS: 14.5839, 121.0543]', '2026-10-19 16:25:54', '2026-10-19 16:25:54', '2026-10-19 16:25:54'),
(189, 20, 8, 'out_for_delivery', '87987899', 'success', 'Status updated to Out For Delivery by rider jasen jumarang [GPS: 14.5839, 121.0543]', '2026-10-19 16:25:55', '2026-10-19 16:25:55', '2026-10-19 16:25:55'),
(190, 20, 8, 'delivered', '87987899', 'success', 'Status updated to Delivered by rider jasen jumarang [GPS: 14.5839, 121.0543]', '2026-10-19 16:26:11', '2026-10-19 16:26:11', '2026-10-19 16:26:11'),
(191, 20, 8, 'delivered', '87987899', 'success', 'Status updated to Delivered by rider jasen jumarang [GPS: 14.5839, 121.0543]', '2026-10-19 16:26:11', '2026-10-19 16:26:11', '2026-10-19 16:26:11'),
(192, 32, 1, 'receive', 'PKG202610150008', 'success', NULL, '2026-10-19 16:27:47', '2026-10-19 16:27:47', '2026-10-19 16:27:47'),
(193, 32, 1, 'scanner_app_intake', 'PKG202610150008', 'success', 'New intake scan by Intake Scanner Unit #1. Sent to sorting center.', '2026-10-19 16:27:47', '2026-10-19 16:27:47', '2026-10-19 16:27:47'),
(194, 11, 7, 'delivered', 'JT002556892205', 'success', 'Status updated to Delivered by rider cj rubiales [GPS: 14.5839, 121.0543]', '2026-10-29 06:10:07', '2026-10-29 06:10:07', '2026-10-29 06:10:07'),
(195, 11, 7, 'delivered', 'JT002556892205', 'success', 'Status updated to Delivered by rider cj rubiales [GPS: 14.5839, 121.0543]', '2026-10-29 06:10:08', '2026-10-29 06:10:08', '2026-10-29 06:10:08'),
(196, 11, 7, 'delivered', 'JT002556892205', 'success', 'Status updated to Delivered by rider cj rubiales [GPS: 14.5839, 121.0543]', '2026-10-29 06:10:14', '2026-10-29 06:10:14', '2026-10-29 06:10:14'),
(197, 33, 1, 'receive', '02030122', 'success', NULL, '2026-10-30 16:27:35', '2026-10-30 16:27:35', '2026-10-30 16:27:35'),
(198, 33, 1, 'sort', NULL, 'success', 'Sorted to bin unassigned', '2026-10-30 16:27:54', '2026-10-30 16:27:54', '2026-10-30 16:27:54'),
(199, 33, 1, 'assign', NULL, 'success', 'Assigned to cj rubiales', '2026-10-30 16:28:02', '2026-10-30 16:28:02', '2026-10-30 16:28:02'),
(200, 33, 7, 'out_for_delivery', '02030122', 'success', 'Status updated to Out For Delivery by rider cj rubiales [GPS: 14.5839, 121.0543]', '2026-10-30 16:30:33', '2026-10-30 16:30:33', '2026-10-30 16:30:33'),
(201, 33, 7, 'out_for_delivery', '02030122', 'success', 'Status updated to Out For Delivery by rider cj rubiales [GPS: 14.5839, 121.0543]', '2026-10-30 16:30:34', '2026-10-30 16:30:34', '2026-10-30 16:30:34'),
(202, 33, 7, 'out_for_delivery', '02030122', 'success', 'Status updated to Out For Delivery by rider cj rubiales [GPS: 14.5839, 121.0543]', '2026-10-30 16:30:42', '2026-10-30 16:30:42', '2026-10-30 16:30:42'),
(203, 33, 7, 'delivered', '02030122', 'success', 'Status updated to Delivered by rider cj rubiales [GPS: 14.5839, 121.0543]', '2026-10-30 18:44:46', '2026-10-30 18:44:46', '2026-10-30 18:44:46'),
(204, 33, 7, 'delivered', '02030122', 'success', 'Status updated to Delivered by rider cj rubiales [GPS: 14.5839, 121.0543]', '2026-10-30 18:44:47', '2026-10-30 18:44:47', '2026-10-30 18:44:47'),
(205, 34, 1, 'receive', 'PKG202610150015', 'success', NULL, '2026-10-30 18:47:33', '2026-10-30 18:47:33', '2026-10-30 18:47:33'),
(206, 34, 1, 'scanner_app_intake', 'PKG202610150015', 'success', 'New intake scan by Intake Scanner Unit #1. Sent to sorting center.', '2026-10-30 18:47:33', '2026-10-30 18:47:33', '2026-10-30 18:47:33'),
(207, 30, 3, 'out_for_delivery', 'SC-BARCODE-103', 'success', 'Status updated to Out For Delivery by rider Rider 01 [GPS: 14.5839, 121.0543]', '2026-10-30 18:50:18', '2026-10-30 18:50:18', '2026-10-30 18:50:18'),
(208, 30, 3, 'out_for_delivery', 'SC-BARCODE-103', 'success', 'Status updated to Out For Delivery by rider Rider 01 [GPS: 14.5839, 121.0543]', '2026-10-30 18:50:19', '2026-10-30 18:50:19', '2026-10-30 18:50:19'),
(209, 30, 3, 'delivered', 'SC-BARCODE-103', 'success', 'Status updated to Delivered by rider Rider 01 [GPS: 14.5839, 121.0543]', '2026-10-30 18:50:35', '2026-10-30 18:50:35', '2026-10-30 18:50:35'),
(210, 30, 3, 'delivered', 'SC-BARCODE-103', 'success', 'Status updated to Delivered by rider Rider 01 [GPS: 14.5839, 121.0543]', '2026-10-30 18:50:36', '2026-10-30 18:50:36', '2026-10-30 18:50:36');

-- --------------------------------------------------------

--
-- Table structure for table `password_reset_tokens`
--

CREATE TABLE `password_reset_tokens` (
  `email` varchar(255) NOT NULL,
  `token` varchar(255) NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `personal_access_tokens`
--

CREATE TABLE `personal_access_tokens` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `tokenable_type` varchar(255) NOT NULL,
  `tokenable_id` bigint(20) UNSIGNED NOT NULL,
  `name` text NOT NULL,
  `token` varchar(64) NOT NULL,
  `abilities` text DEFAULT NULL,
  `last_used_at` timestamp NULL DEFAULT NULL,
  `expires_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `personal_access_tokens`
--

INSERT INTO `personal_access_tokens` (`id`, `tokenable_type`, `tokenable_id`, `name`, `token`, `abilities`, `last_used_at`, `expires_at`, `created_at`, `updated_at`) VALUES
(2, 'App\\Models\\User', 3, 'test', '4f13d3a16682902e9b329e9358fe4773693e0aa157655283c56b35a5df4f4327', '[\"*\"]', '2026-10-13 19:54:25', NULL, '2026-10-13 19:54:24', '2026-10-13 19:54:25'),
(3, 'App\\Models\\User', 3, 'test', 'd75c231634a57cf52b60f3d94ee1aad5913dfc95cfd6cde406f0f5ed77d7d5b3', '[\"*\"]', '2026-10-13 19:54:35', NULL, '2026-10-13 19:54:35', '2026-10-13 19:54:35');

-- --------------------------------------------------------

--
-- Table structure for table `rider_area_assignments`
--

CREATE TABLE `rider_area_assignments` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `rider_profile_id` bigint(20) UNSIGNED NOT NULL,
  `destination_area_id` bigint(20) UNSIGNED NOT NULL,
  `is_primary` tinyint(1) NOT NULL DEFAULT 1,
  `is_active` tinyint(1) NOT NULL DEFAULT 1,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `rider_area_assignments`
--

INSERT INTO `rider_area_assignments` (`id`, `rider_profile_id`, `destination_area_id`, `is_primary`, `is_active`, `created_at`, `updated_at`) VALUES
(1, 1, 1, 1, 1, '2026-08-29 23:00:04', '2026-08-29 23:00:04'),
(4, 2, 1, 0, 1, '2026-10-13 22:59:41', '2026-10-13 22:59:41'),
(8, 5, 4, 0, 1, '2026-10-14 23:58:03', '2026-10-14 23:58:03'),
(9, 6, 4, 0, 1, '2026-10-15 00:52:32', '2026-10-15 00:52:32'),
(11, 11, 10, 1, 1, '2026-10-15 04:30:04', '2026-10-15 04:30:04'),
(12, 5, 11, 0, 1, '2026-10-15 08:05:35', '2026-10-15 08:05:35'),
(13, 6, 10, 0, 1, '2026-10-16 06:22:30', '2026-10-16 06:22:30'),
(14, 5, 10, 0, 1, '2026-10-16 17:05:46', '2026-10-16 17:05:46'),
(15, 13, 1, 1, 1, '2026-10-28 23:27:02', '2026-10-28 23:27:02'),
(16, 15, 1, 1, 1, '2026-10-29 06:21:20', '2026-10-29 06:21:20'),
(17, 16, 1, 1, 1, '2026-10-30 19:20:46', '2026-10-30 19:20:46');

-- --------------------------------------------------------

--
-- Table structure for table `rider_profiles`
--

CREATE TABLE `rider_profiles` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `user_id` bigint(20) UNSIGNED NOT NULL,
  `phone` varchar(255) DEFAULT NULL,
  `vehicle_type` varchar(255) DEFAULT NULL,
  `license_number` varchar(255) DEFAULT NULL,
  `license_photo_path` varchar(255) DEFAULT NULL,
  `or_cr_photo_path` varchar(255) DEFAULT NULL,
  `registration_status` varchar(255) NOT NULL DEFAULT 'pending',
  `availability` varchar(255) NOT NULL DEFAULT 'offline',
  `approved_at` timestamp NULL DEFAULT NULL,
  `approved_by` bigint(20) UNSIGNED DEFAULT NULL,
  `registration_note` text DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `hub_id` bigint(20) UNSIGNED DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `rider_profiles`
--

INSERT INTO `rider_profiles` (`id`, `user_id`, `phone`, `vehicle_type`, `license_number`, `license_photo_path`, `or_cr_photo_path`, `registration_status`, `availability`, `approved_at`, `approved_by`, `registration_note`, `created_at`, `updated_at`, `hub_id`) VALUES
(1, 3, '09277115545', 'Motorcycle', NULL, NULL, NULL, 'approved', 'online', '2026-09-03 16:38:17', 1, NULL, '2026-08-29 23:00:04', '2026-10-13 23:24:48', NULL),
(2, 4, '09898282483', 'Motorcycle', NULL, NULL, NULL, 'disapproved', 'available', NULL, NULL, NULL, '2026-08-29 23:00:04', '2026-10-15 03:55:27', NULL),
(3, 5, '09519635088', 'Motorcycle', NULL, NULL, NULL, 'disapproved', 'available', NULL, NULL, NULL, '2026-08-29 23:00:04', '2026-10-15 03:55:35', NULL),
(4, 6, '09123456789', 'Motorcycle', 'N01-23-456789', NULL, NULL, 'disapproved', 'offline', NULL, 1, NULL, '2026-10-13 23:38:18', '2026-10-14 00:40:52', NULL),
(5, 7, '09755667472', 'Motorcycle', 'WH 5958', NULL, NULL, 'approved', 'online', '2026-10-16 17:56:58', 2, NULL, '2026-10-13 23:51:47', '2026-10-30 18:43:38', NULL),
(6, 8, '09456643122', 'Motorcycle', '1929390', NULL, NULL, 'approved', 'online', '2026-10-14 20:50:00', 1, NULL, '2026-10-14 20:49:44', '2026-10-15 20:02:30', NULL),
(7, 9, '09123456789', 'Motorcycle', 'LIC-TEST-888', NULL, NULL, 'approved', 'offline', '2026-10-16 17:54:56', 2, NULL, '2026-10-15 03:51:55', '2026-10-16 17:54:56', NULL),
(9, 11, '09123456789', 'Motorcycle', 'LIC-TEST-888', 'rider_documents/license_c3974524-07b0-4ef0-bd13-ad1943e45db7.jpg', 'rider_documents/or_cr_66fb2f94-a0d4-4af7-bd1a-79a6e79b11dd.jpg', 'approved', 'offline', '2026-10-16 17:54:17', 2, NULL, '2026-10-15 03:53:43', '2026-10-16 17:54:17', NULL),
(11, 13, '09433665274', 'Motorcycle', 'DGF 1039', 'rider_documents/license_e24918ca-229b-4e70-96b9-ffe94bd298a2.jpg', 'rider_documents/or_cr_a57ddd91-69fe-4f1d-8778-80d2c464e301.jpg', 'approved', 'offline', '2026-10-16 17:55:39', 2, NULL, '2026-10-15 04:03:12', '2026-10-16 17:55:39', NULL),
(12, 14, '09755667472', 'Motorcycle', '103iGSJ', 'rider_documents/license_8a626bf3-dd9a-4390-bff3-77facc11a75b.jpg', 'rider_documents/or_cr_264aa45d-f677-43d5-ab8c-ee6c590caaea.jpg', 'disapproved', 'offline', NULL, NULL, NULL, '2026-10-16 18:00:35', '2026-10-16 18:00:46', NULL),
(13, 17, '09755667472', 'Motorcycle', 'HSG 123', 'rider_documents/license_4995812d-5fd6-4da9-b2e7-4e9a864f394b.jpg', 'rider_documents/or_cr_f1970ad0-2008-4f91-a28f-06d86ad36650.jpg', 'approved', 'offline', '2026-10-28 23:26:59', NULL, NULL, '2026-10-28 20:04:03', '2026-10-28 23:26:59', NULL),
(14, 18, '09755667472', 'Motorcycle', 'FGB 865', 'rider_documents/license_995d4b2f-34ac-443e-881b-1e6da72d1634.jpg', 'rider_documents/or_cr_966623a3-b2fe-4063-a3b8-c8a6af33ba6b.jpg', 'approved', 'offline', '2026-10-29 01:16:14', 1, NULL, '2026-10-29 01:09:15', '2026-10-29 01:16:14', NULL),
(15, 19, '09755667472', 'Motorcycle', 'HSU YDJ', 'rider_documents/license_6b1a656a-24f5-40d7-8b6e-f6e6f2503583.jpg', 'rider_documents/or_cr_1f57eca9-3e73-45db-814d-8bb533d9e20f.jpg', 'approved', 'offline', '2026-10-29 06:21:50', 15, NULL, '2026-10-29 06:21:20', '2026-10-29 06:21:50', 1),
(16, 20, '09755667472', 'Motorcycle', 'HGB 123', 'rider_documents/license_8bf8bee9-19ab-48da-8c7b-512457c2b3d7.jpg', 'rider_documents/or_cr_3b0ae64b-97cb-405d-81f4-9f5b9b3c8348.jpg', 'approved', 'offline', '2026-10-30 19:21:26', 15, NULL, '2026-10-30 19:20:46', '2026-10-30 19:21:26', 1);

-- --------------------------------------------------------

--
-- Table structure for table `sessions`
--

CREATE TABLE `sessions` (
  `id` varchar(255) NOT NULL,
  `user_id` bigint(20) UNSIGNED DEFAULT NULL,
  `ip_address` varchar(45) DEFAULT NULL,
  `user_agent` text DEFAULT NULL,
  `payload` longtext NOT NULL,
  `last_activity` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `sessions`
--

INSERT INTO `sessions` (`id`, `user_id`, `ip_address`, `user_agent`, `payload`, `last_activity`) VALUES
('fhaNgCtDOqShHG6qzO86zylRC0s0BDyai4qRFK9i', NULL, '127.0.0.1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Code/1.144.0 Chrome/150.0.7871.250 Electron/43.8.3 Safari/537.36', 'YTo0OntzOjY6Il90b2tlbiI7czo0MDoiSmxQU1MzbFM2ZDR1MW54SUt3NTljeUU4MTdTU2xSR2pSZzNyekxsciI7czozOiJ1cmwiO2E6MTp7czo4OiJpbnRlbmRlZCI7czoyMToiaHR0cDovLzEyNy4wLjAuMTo4MDAwIjt9czo5OiJfcHJldmlvdXMiO2E6Mjp7czozOiJ1cmwiO3M6Mjc6Imh0dHA6Ly8xMjcuMC4wLjE6ODAwMC9sb2dpbiI7czo1OiJyb3V0ZSI7czo1OiJsb2dpbiI7fXM6NjoiX2ZsYXNoIjthOjI6e3M6Mzoib2xkIjthOjA6e31zOjM6Im5ldyI7YTowOnt9fX0=', 1793413964),
('fxlXDI3Wx6ZqcC5Drrh4BDlq3U8CpSzm36NFwXq7', 15, '127.0.0.1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/156.0.0.0 Safari/537.36', 'YTo0OntzOjY6Il90b2tlbiI7czo0MDoiT2kwOElEbXVxcUhDWDdveEpZU1ZOdWl6NUt2ekxOdThOVGV5eUM1NiI7czo2OiJfZmxhc2giO2E6Mjp7czozOiJvbGQiO2E6MDp7fXM6MzoibmV3IjthOjA6e319czo5OiJfcHJldmlvdXMiO2E6Mjp7czozOiJ1cmwiO3M6Mjg6Imh0dHA6Ly8xMjcuMC4wLjE6ODAwMC9yaWRlcnMiO3M6NToicm91dGUiO3M6MTI6InJpZGVycy5pbmRleCI7fXM6NTA6ImxvZ2luX3dlYl81OWJhMzZhZGRjMmIyZjk0MDE1ODBmMDE0YzdmNThlYTRlMzA5ODlkIjtpOjE1O30=', 1793416893),
('ug3eySM6jIAomwHmR2PWDmhEbz3fxhRn9UAflPOb', 1, '127.0.0.1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/156.0.0.0 Safari/537.36', 'YTo0OntzOjY6Il90b2tlbiI7czo0MDoiS3BTUGhIZFdhbmIzbHE3NzZYa01ydFRRNnFqZ2x6bGREYXVydmtnSSI7czo2OiJfZmxhc2giO2E6Mjp7czozOiJvbGQiO2E6MDp7fXM6MzoibmV3IjthOjA6e319czo5OiJfcHJldmlvdXMiO2E6Mjp7czozOiJ1cmwiO3M6Mjc6Imh0dHA6Ly8xMjcuMC4wLjE6ODAwMC9sb2dpbiI7czo1OiJyb3V0ZSI7czo1OiJsb2dpbiI7fXM6NTA6ImxvZ2luX3dlYl81OWJhMzZhZGRjMmIyZjk0MDE1ODBmMDE0YzdmNThlYTRlMzA5ODlkIjtpOjE7fQ==', 1793413091);

-- --------------------------------------------------------

--
-- Table structure for table `shipments`
--

CREATE TABLE `shipments` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `order_id` bigint(20) UNSIGNED NOT NULL,
  `fulfillment_location_id` bigint(20) UNSIGNED DEFAULT NULL,
  `external_id` varchar(255) DEFAULT NULL,
  `tracking_number` varchar(255) DEFAULT NULL,
  `carrier` varchar(255) DEFAULT NULL,
  `service_level` varchar(255) DEFAULT NULL,
  `status` varchar(255) NOT NULL DEFAULT 'pending',
  `destination_city` varchar(255) DEFAULT NULL,
  `destination_state` varchar(255) DEFAULT NULL,
  `destination_country` varchar(2) NOT NULL DEFAULT 'US',
  `weight` decimal(8,3) DEFAULT NULL,
  `label_url` varchar(255) DEFAULT NULL,
  `exception_type` varchar(255) DEFAULT NULL,
  `exception_note` text DEFAULT NULL,
  `shipped_at` timestamp NULL DEFAULT NULL,
  `delivered_at` timestamp NULL DEFAULT NULL,
  `metadata` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`metadata`)),
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `shipments`
--

INSERT INTO `shipments` (`id`, `order_id`, `fulfillment_location_id`, `external_id`, `tracking_number`, `carrier`, `service_level`, `status`, `destination_city`, `destination_state`, `destination_country`, `weight`, `label_url`, `exception_type`, `exception_note`, `shipped_at`, `delivered_at`, `metadata`, `created_at`, `updated_at`) VALUES
(1, 1, 1, 'SH-240912-081', 'TRK2187LUMORA', 'Lumora Express', 'Express', 'in_transit', 'Makati City', 'Metro Manila', 'PH', 0.350, NULL, NULL, NULL, '2026-08-29 22:14:11', NULL, NULL, '2026-08-29 23:00:04', '2026-08-29 23:14:11'),
(2, 2, 1, 'SH-240912-080', 'TRK2186LUMORA', 'J&T Express', 'Standard', 'packed', 'Taguig City', 'Metro Manila', 'PH', 0.450, NULL, NULL, NULL, NULL, NULL, NULL, '2026-08-29 23:00:04', '2026-08-29 23:00:04'),
(3, 3, 1, 'SH-240912-079', 'TRK2185LUMORA', 'LBC Express', 'Express', 'in_transit', 'Pasig City', 'Metro Manila', 'PH', 0.550, NULL, NULL, NULL, '2026-08-29 20:14:11', NULL, NULL, '2026-08-29 23:00:04', '2026-08-29 23:14:11'),
(4, 4, 1, 'SH-240912-078', 'TRK2184LUMORA', 'Lumora Express', 'Standard', 'exception', 'Quezon City', 'Metro Manila', 'PH', 0.650, NULL, 'Address review', 'Recipient address needs confirmation.', NULL, NULL, NULL, '2026-08-29 23:00:04', '2026-08-29 23:00:04'),
(5, 5, 1, 'SH-240912-077', 'TRK2183LUMORA', 'J&T Express', 'Express', 'delivered', 'Manila', 'Metro Manila', 'PH', 0.350, NULL, NULL, NULL, '2026-08-29 18:14:11', '2026-08-29 19:14:11', NULL, '2026-08-29 23:00:04', '2026-08-29 23:14:11'),
(6, 6, 1, 'SH-240912-076', 'TRK2182LUMORA', 'LBC Express', 'Standard', 'in_transit', 'Mandaluyong City', 'Metro Manila', 'PH', 0.450, NULL, NULL, NULL, '2026-08-29 17:14:11', NULL, NULL, '2026-08-29 23:00:05', '2026-08-29 23:14:11'),
(7, 7, 1, 'SH-240912-075', NULL, 'Lumora Express', 'Express', 'cancelled', 'Calamba City', 'Laguna', 'PH', 0.550, NULL, NULL, NULL, NULL, NULL, NULL, '2026-08-29 23:00:05', '2026-10-15 00:15:08'),
(8, 8, 1, 'SH-240912-074', 'TRK2180LUMORA', 'J&T Express', 'Standard', 'in_transit', 'Antipolo City', 'Rizal', 'PH', 0.650, NULL, NULL, NULL, '2026-08-29 15:14:11', NULL, NULL, '2026-08-29 23:00:05', '2026-08-29 23:14:11'),
(9, 9, 1, 'SH-240912-073', 'TRK2179LUMORA', 'LBC Express', 'Express', 'delivered', 'Batangas City', 'Batangas', 'PH', 0.350, NULL, NULL, NULL, '2026-08-29 14:14:11', '2026-08-29 15:14:11', NULL, '2026-08-29 23:00:05', '2026-08-29 23:14:11'),
(10, 10, 1, 'SH-240912-072', 'TRK2178LUMORA', 'Lumora Express', 'Standard', 'out_for_delivery', 'Santa Rosa City', 'Laguna', 'PH', 0.450, NULL, NULL, NULL, '2026-08-29 13:14:11', NULL, NULL, '2026-08-29 23:00:05', '2026-10-13 04:56:28'),
(11, 11, 1, 'SH-240912-071', 'TRK2177LUMORA', 'J&T Express', 'Express', 'delivered', 'Imus City', 'Cavite', 'PH', 0.550, NULL, NULL, NULL, '2026-09-22 04:18:53', '2026-09-22 04:19:10', NULL, '2026-08-29 23:00:05', '2026-09-22 04:19:10'),
(12, 12, 1, 'SH-240912-070', 'TRK2176LUMORA', 'LBC Express', 'Standard', 'delivered', 'Bacoor City', 'Cavite', 'PH', 0.650, NULL, NULL, NULL, '2026-08-29 11:14:11', '2026-09-27 04:15:56', NULL, '2026-08-29 23:00:05', '2026-09-27 04:15:56'),
(13, 13, NULL, NULL, 'LM-TRK-000013', 'Lumora Express', NULL, 'delivered', 'pila', 'Laguna', 'PH', NULL, NULL, NULL, NULL, '2026-10-14 23:10:55', '2026-10-14 23:46:27', '{\"source\":\"parcel_intake\"}', '2026-10-14 20:52:31', '2026-10-14 23:46:27'),
(14, 14, NULL, NULL, 'LM-TRK-000014', 'Lumora Express', NULL, 'delivered', 'pila', 'Laguna', 'PH', NULL, NULL, NULL, NULL, '2026-10-15 00:00:14', '2026-10-15 00:00:40', '{\"source\":\"parcel_intake\"}', '2026-10-14 23:57:35', '2026-10-15 00:00:40'),
(15, 15, NULL, NULL, 'LM-TRK-000015', 'Lumora Express', NULL, 'delivered', 'pila', 'Laguna', 'PH', NULL, NULL, NULL, NULL, '2026-10-15 00:18:17', '2026-10-15 00:19:12', '{\"source\":\"parcel_intake\"}', '2026-10-15 00:17:01', '2026-10-15 00:19:12'),
(16, 16, NULL, NULL, 'LM-TRK-000016', 'Lumora Express', NULL, 'delivered', 'pila', 'Laguna', 'PH', NULL, NULL, NULL, NULL, '2026-10-15 00:54:55', '2026-10-15 00:56:05', '{\"source\":\"parcel_intake\"}', '2026-10-15 00:51:58', '2026-10-15 00:56:05'),
(17, 17, NULL, NULL, 'LM-TRK-000017', 'Lumora Express', NULL, 'delivered', 'pila', 'Laguna', 'PH', NULL, NULL, NULL, NULL, '2026-10-15 01:17:48', '2026-10-15 01:19:19', '{\"source\":\"parcel_intake\"}', '2026-10-15 01:16:26', '2026-10-15 01:19:19'),
(18, 18, NULL, NULL, 'LM-TRK-000018', 'Lumora Express', NULL, 'delivered', 'pila', 'Laguna', 'PH', NULL, NULL, NULL, NULL, '2026-10-15 01:21:24', '2026-10-15 05:42:29', '{\"source\":\"parcel_intake\"}', '2026-10-15 01:20:35', '2026-10-15 05:42:29'),
(19, 19, NULL, NULL, 'LM-TRK-000019', 'Lumora Express', NULL, 'delivered', 'pila', 'Laguna', 'PH', NULL, NULL, NULL, NULL, '2026-10-15 01:24:53', '2026-10-15 01:25:18', '{\"source\":\"parcel_intake\"}', '2026-10-15 01:23:36', '2026-10-15 01:25:18'),
(20, 20, NULL, NULL, 'LM-TRK-000020', 'Lumora Express', NULL, 'delivered', 'pila', 'Laguna', 'PH', NULL, NULL, NULL, NULL, '2026-10-15 03:03:11', '2026-10-15 03:03:34', '{\"source\":\"parcel_intake\"}', '2026-10-15 03:02:09', '2026-10-15 03:03:34'),
(21, 21, NULL, NULL, 'LM-TRK-000021', 'Lumora Express', NULL, 'out_for_delivery', 'pila', 'Laguna', 'PH', NULL, NULL, NULL, NULL, '2026-10-15 06:56:23', NULL, '{\"source\":\"parcel_intake\"}', '2026-10-15 06:36:53', '2026-10-15 08:13:00'),
(22, 22, NULL, NULL, 'LM-TRK-000022', 'Lumora Express', NULL, 'out_for_delivery', 'pila', 'Laguna', 'PH', NULL, NULL, NULL, NULL, '2026-10-15 07:12:29', NULL, '{\"source\":\"parcel_intake\"}', '2026-10-15 07:11:15', '2026-10-15 07:12:42'),
(23, 23, NULL, NULL, 'LM-TRK-000023', 'Lumora Express', NULL, 'out_for_delivery', 'pila', 'Laguna', 'PH', NULL, NULL, NULL, NULL, '2026-10-15 07:19:03', NULL, '{\"source\":\"parcel_intake\"}', '2026-10-15 07:13:28', '2026-10-15 08:12:58'),
(24, 24, NULL, NULL, 'LM-TRK-000024', 'Lumora Express', NULL, 'delivered', 'pila', 'Laguna', 'PH', NULL, NULL, NULL, NULL, '2026-10-15 08:06:24', '2026-10-15 08:07:32', '{\"source\":\"parcel_intake\"}', '2026-10-15 07:44:05', '2026-10-15 08:07:32'),
(25, 25, NULL, NULL, 'LM-TRK-000025', 'Lumora Express', NULL, 'delivered', 'pila', 'Laguna', 'PH', NULL, NULL, NULL, NULL, '2026-10-15 08:18:59', '2026-10-29 06:10:07', '{\"source\":\"parcel_intake\"}', '2026-10-15 08:09:20', '2026-10-29 06:10:07'),
(26, 26, NULL, NULL, 'LM-TRK-000026', 'Lumora Express', NULL, 'delivered', 'pila', 'Laguna', 'PH', NULL, NULL, NULL, NULL, '2026-10-15 08:12:53', '2026-10-16 17:45:48', '{\"source\":\"parcel_intake\"}', '2026-10-15 08:11:06', '2026-10-16 17:45:48'),
(27, 27, NULL, NULL, 'LM-TRK-000027', 'Lumora Express', NULL, 'delivered', 'Santa Cruz', 'Laguna', 'PH', NULL, NULL, NULL, NULL, '2026-10-15 23:39:23', '2026-10-16 05:12:43', '{\"source\":\"parcel_intake\"}', '2026-10-15 22:13:13', '2026-10-16 05:12:43'),
(28, 28, NULL, NULL, 'LM-TRK-000028', 'Lumora Express', NULL, 'pending', 'Santa Cruz', 'Laguna', 'PH', NULL, NULL, NULL, NULL, NULL, NULL, '{\"source\":\"parcel_intake\"}', '2026-10-15 23:53:05', '2026-10-15 23:53:05'),
(29, 29, NULL, NULL, 'LM-TRK-000029', 'Lumora Express', NULL, 'pending', 'Santa Cruz', 'Laguna', 'PH', NULL, NULL, NULL, NULL, NULL, NULL, '{\"source\":\"parcel_intake\"}', '2026-10-15 23:53:05', '2026-10-15 23:53:05'),
(30, 30, NULL, NULL, 'LM-TRK-000030', 'Lumora Express', NULL, 'pending', 'Santa Cruz', 'Laguna', 'PH', NULL, NULL, NULL, NULL, NULL, NULL, '{\"source\":\"parcel_intake\"}', '2026-10-16 04:15:49', '2026-10-16 04:15:49'),
(31, 31, NULL, NULL, 'LM-TRK-000031', 'Lumora Express', NULL, 'delivered', 'Santa Cruz', 'Laguna', 'PH', NULL, NULL, NULL, NULL, '2026-10-16 04:42:56', '2026-10-16 04:43:45', '{\"source\":\"parcel_intake\"}', '2026-10-16 04:40:53', '2026-10-16 04:43:45'),
(32, 32, NULL, NULL, 'LM-TRK-000032', 'Lumora Express', NULL, 'pending', 'Santa Cruz', 'Laguna', 'PH', NULL, NULL, NULL, NULL, NULL, NULL, '{\"source\":\"parcel_intake\"}', '2026-10-16 05:53:58', '2026-10-16 05:53:58'),
(33, 33, NULL, NULL, 'LM-TRK-000033', 'Lumora Express', NULL, 'pending', 'Santa Cruz', 'Laguna', 'PH', NULL, NULL, NULL, NULL, NULL, NULL, '{\"source\":\"parcel_intake\"}', '2026-10-16 06:06:38', '2026-10-16 06:06:38'),
(34, 34, NULL, NULL, 'LM-TRK-000034', 'Lumora Express', NULL, 'delivered', 'pila', 'Laguna', 'PH', NULL, NULL, NULL, NULL, '2026-10-19 16:25:54', '2026-10-19 16:26:11', '{\"source\":\"parcel_intake\"}', '2026-10-16 06:11:05', '2026-10-19 16:26:11'),
(35, 35, NULL, NULL, 'LM-TRK-000035', 'Lumora Express', NULL, 'pending', 'Santa Cruz', 'Laguna', 'PH', NULL, NULL, NULL, NULL, NULL, NULL, '{\"source\":\"parcel_intake\"}', '2026-10-16 06:14:12', '2026-10-16 06:14:12'),
(36, 36, NULL, NULL, 'LM-TRK-000036', 'Lumora Express', NULL, 'pending', 'Santa Cruz', 'Laguna', 'PH', NULL, NULL, NULL, NULL, NULL, NULL, '{\"source\":\"parcel_intake\"}', '2026-10-16 06:14:12', '2026-10-16 06:14:12'),
(37, 37, NULL, NULL, 'LM-TRK-000037', 'Lumora Express', NULL, 'delivered', 'Santa Cruz', 'Laguna', 'PH', NULL, NULL, NULL, NULL, '2026-10-16 06:16:21', '2026-10-16 06:17:01', '{\"source\":\"parcel_intake\"}', '2026-10-16 06:14:38', '2026-10-16 06:17:01'),
(38, 38, NULL, NULL, 'LM-TRK-000038', 'Lumora Express', NULL, 'delivered', 'Santa Cruz', 'Laguna', 'PH', NULL, NULL, NULL, NULL, '2026-10-16 06:23:05', '2026-10-16 06:24:03', '{\"source\":\"parcel_intake\"}', '2026-10-16 06:22:07', '2026-10-16 06:24:03'),
(39, 39, NULL, NULL, 'LM-TRK-000039', 'Lumora Express', NULL, 'pending', 'Santa Cruz', 'Laguna', 'PH', NULL, NULL, NULL, NULL, NULL, NULL, '{\"source\":\"parcel_intake\"}', '2026-10-16 17:03:48', '2026-10-16 17:03:48'),
(40, 40, NULL, NULL, 'LM-TRK-000040', 'Lumora Express', NULL, 'delivered', 'Santa Cruz', 'Laguna', 'PH', NULL, NULL, NULL, NULL, '2026-10-16 17:06:14', '2026-10-16 17:07:08', '{\"source\":\"parcel_intake\"}', '2026-10-16 17:05:17', '2026-10-16 17:07:09'),
(41, 41, NULL, NULL, 'LM-TRK-000041', 'Lumora Express', NULL, 'pending', 'Santa Cruz', 'Laguna', 'PH', NULL, NULL, NULL, NULL, NULL, NULL, NULL, '2026-10-17 07:13:31', '2026-10-17 07:13:31'),
(42, 42, NULL, NULL, 'LM-TRK-000042', 'Lumora Express', NULL, 'pending', 'Santa Cruz', 'Laguna', 'PH', NULL, NULL, NULL, NULL, NULL, NULL, NULL, '2026-10-17 07:13:31', '2026-10-17 07:13:31'),
(43, 43, NULL, NULL, 'LM-TRK-000043', 'Lumora Express', NULL, 'packed', 'Santa Cruz', 'Laguna', 'PH', NULL, NULL, NULL, NULL, NULL, NULL, NULL, '2026-10-17 07:13:31', '2026-10-17 07:13:31'),
(44, 44, NULL, NULL, 'LM-TRK-000044', 'Lumora Express', NULL, 'delivered', 'Santa Cruz', 'Laguna', 'PH', NULL, NULL, NULL, NULL, '2026-10-30 18:50:18', '2026-10-30 18:50:35', NULL, '2026-10-17 07:13:31', '2026-10-30 18:50:35'),
(45, 45, NULL, NULL, 'LM-TRK-000045', 'Lumora Express', NULL, 'delivered', 'Santa Cruz', 'Laguna', 'PH', NULL, NULL, NULL, NULL, NULL, NULL, NULL, '2026-10-17 07:13:31', '2026-10-17 07:13:31'),
(46, 46, NULL, NULL, 'LM-TRK-000046', 'Lumora Express', NULL, 'pending', 'Santa Cruz', 'Laguna', 'PH', NULL, NULL, NULL, NULL, NULL, NULL, '{\"source\":\"parcel_intake\"}', '2026-10-19 16:27:47', '2026-10-19 16:27:47'),
(47, 47, NULL, NULL, 'LM-TRK-000047', 'Lumora Express', NULL, 'delivered', 'pila', 'Laguna', 'PH', NULL, NULL, NULL, NULL, '2026-10-30 16:30:33', '2026-10-30 18:44:46', '{\"source\":\"parcel_intake\"}', '2026-10-30 16:27:35', '2026-10-30 18:44:46'),
(48, 48, NULL, NULL, 'LM-TRK-000048', 'Lumora Express', NULL, 'pending', 'Santa Cruz', 'Laguna', 'PH', NULL, NULL, NULL, NULL, NULL, NULL, '{\"source\":\"parcel_intake\"}', '2026-10-30 18:47:33', '2026-10-30 18:47:33');

-- --------------------------------------------------------

--
-- Table structure for table `stores`
--

CREATE TABLE `stores` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `name` varchar(255) NOT NULL,
  `platform` varchar(255) NOT NULL DEFAULT 'custom',
  `external_store_id` varchar(255) DEFAULT NULL,
  `api_base_url` varchar(255) DEFAULT NULL,
  `integration_key_hash` varchar(255) DEFAULT NULL,
  `webhook_secret` varchar(255) DEFAULT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT 1,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `stores`
--

INSERT INTO `stores` (`id`, `name`, `platform`, `external_store_id`, `api_base_url`, `integration_key_hash`, `webhook_secret`, `is_active`, `created_at`, `updated_at`) VALUES
(1, 'Lumora Beauty', 'custom', 'lumora-demo', 'https://store.example.test/api', NULL, NULL, 1, '2026-08-29 23:00:03', '2026-08-29 23:00:03');

-- --------------------------------------------------------

--
-- Table structure for table `tracking_events`
--

CREATE TABLE `tracking_events` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `shipment_id` bigint(20) UNSIGNED NOT NULL,
  `status` varchar(255) NOT NULL,
  `label` varchar(255) NOT NULL,
  `description` text DEFAULT NULL,
  `location` varchar(255) DEFAULT NULL,
  `occurred_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `source` varchar(255) NOT NULL DEFAULT 'system',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `tracking_events`
--

INSERT INTO `tracking_events` (`id`, `shipment_id`, `status`, `label`, `description`, `location`, `occurred_at`, `source`, `created_at`, `updated_at`) VALUES
(1, 1, 'in_transit', 'In transit', 'Demo tracking event for the Lumora operations console.', 'Makati City, Metro Manila', '2026-08-29 23:00:04', 'demo', '2026-08-29 23:00:04', '2026-08-29 23:00:04'),
(2, 2, 'packed', 'Ready to ship', 'Demo tracking event for the Lumora operations console.', 'Taguig City, Metro Manila', '2026-08-29 22:52:04', 'demo', '2026-08-29 23:00:04', '2026-08-29 23:00:04'),
(3, 3, 'in_transit', 'In transit', 'Demo tracking event for the Lumora operations console.', 'Pasig City, Metro Manila', '2026-08-29 22:44:04', 'demo', '2026-08-29 23:00:04', '2026-08-29 23:00:04'),
(4, 4, 'exception', 'Address needs review', 'Demo tracking event for the Lumora operations console.', 'Quezon City, Metro Manila', '2026-08-29 22:36:04', 'demo', '2026-08-29 23:00:04', '2026-08-29 23:00:04'),
(5, 5, 'delivered', 'Delivered', 'Demo tracking event for the Lumora operations console.', 'Manila, Metro Manila', '2026-08-29 22:28:04', 'demo', '2026-08-29 23:00:04', '2026-08-29 23:00:04'),
(6, 6, 'in_transit', 'In transit', 'Demo tracking event for the Lumora operations console.', 'Mandaluyong City, Metro Manila', '2026-08-29 22:20:05', 'demo', '2026-08-29 23:00:05', '2026-08-29 23:00:05'),
(7, 7, 'pending', 'Order received', 'Demo tracking event for the Lumora operations console.', 'Calamba City, Laguna', '2026-08-29 22:12:05', 'demo', '2026-08-29 23:00:05', '2026-08-29 23:00:05'),
(8, 8, 'in_transit', 'In transit', 'Demo tracking event for the Lumora operations console.', 'Antipolo City, Rizal', '2026-08-29 22:04:05', 'demo', '2026-08-29 23:00:05', '2026-08-29 23:00:05'),
(9, 9, 'delivered', 'Delivered', 'Demo tracking event for the Lumora operations console.', 'Batangas City, Batangas', '2026-08-29 21:56:05', 'demo', '2026-08-29 23:00:05', '2026-08-29 23:00:05'),
(10, 10, 'in_transit', 'In transit', 'Demo tracking event for the Lumora operations console.', 'Santa Rosa City, Laguna', '2026-08-29 21:48:05', 'demo', '2026-08-29 23:00:05', '2026-08-29 23:00:05'),
(11, 11, 'packed', 'Ready to ship', 'Demo tracking event for the Lumora operations console.', 'Imus City, Cavite', '2026-08-29 21:40:05', 'demo', '2026-08-29 23:00:05', '2026-08-29 23:00:05'),
(12, 12, 'in_transit', 'In transit', 'Demo tracking event for the Lumora operations console.', 'Bacoor City, Cavite', '2026-08-29 21:32:05', 'demo', '2026-08-29 23:00:05', '2026-08-29 23:00:05'),
(13, 11, 'in_transit', 'In Transit', 'Parcel is currently on the way to its destination.', 'Imus City, Cavite', '2026-09-22 04:18:53', 'portal', '2026-09-22 04:18:53', '2026-09-22 04:18:53'),
(14, 11, 'out_for_delivery', 'Out for Delivery', 'Parcel is out for final delivery.', 'Imus City, Cavite', '2026-09-22 04:19:01', 'portal', '2026-09-22 04:19:01', '2026-09-22 04:19:01'),
(15, 11, 'delivered', 'Delivered', 'Parcel has been delivered.', 'Imus City, Cavite', '2026-09-22 04:19:10', 'portal', '2026-09-22 04:19:10', '2026-09-22 04:19:10'),
(16, 12, 'delivered', 'Delivered', 'Parcel has been delivered.', 'Bacoor City, Cavite', '2026-09-27 04:15:56', 'portal', '2026-09-27 04:15:56', '2026-09-27 04:15:56'),
(17, 10, 'out_for_delivery', 'Out for Delivery', 'Parcel is out for final delivery.', 'Santa Rosa City, Laguna', '2026-10-13 04:56:28', 'portal', '2026-10-13 04:56:28', '2026-10-13 04:56:28'),
(18, 13, 'pending', 'Received', 'Parcel successfully received by Lumora Logistics.', 'pila, Laguna', '2026-10-14 20:52:31', 'rider_app', '2026-10-14 20:52:31', '2026-10-14 20:52:31'),
(19, 13, 'pending', 'Received', 'Parcel successfully received by Lumora Logistics.', 'pila, Laguna', '2026-10-14 23:08:36', 'rider_app', '2026-10-14 23:08:36', '2026-10-14 23:08:36'),
(20, 13, 'packed', 'Sorting Center', 'Parcel is being processed at the sorting center.', 'pila, Laguna', '2026-10-14 23:08:48', 'rider_app', '2026-10-14 23:08:48', '2026-10-14 23:08:48'),
(21, 13, 'out_for_delivery', 'Out for Delivery', 'Parcel is out for final delivery.', 'pila, Laguna', '2026-10-14 23:10:55', 'portal', '2026-10-14 23:10:55', '2026-10-14 23:10:55'),
(22, 13, 'delivered', 'Delivered', 'Parcel was successfully delivered by courier cj rubiales.', 'pila, Laguna', '2026-10-14 23:46:26', 'rider_app', '2026-10-14 23:46:26', '2026-10-14 23:46:26'),
(23, 14, 'pending', 'Received', 'Parcel successfully received by Lumora Logistics.', 'pila, Laguna', '2026-10-14 23:57:35', 'rider_app', '2026-10-14 23:57:35', '2026-10-14 23:57:35'),
(24, 14, 'packed', 'Sorting Center', 'Parcel is being processed at the sorting center.', 'pila, Laguna', '2026-10-14 23:57:46', 'rider_app', '2026-10-14 23:57:46', '2026-10-14 23:57:46'),
(25, 14, 'out_for_delivery', 'Out for Delivery', 'Parcel is out for delivery with courier cj rubiales.', 'pila, Laguna', '2026-10-15 00:00:14', 'rider_app', '2026-10-15 00:00:14', '2026-10-15 00:00:14'),
(26, 13, 'delivered', 'Delivered', 'Parcel was successfully delivered by courier cj rubiales.', 'pila, Laguna', '2026-10-15 00:00:21', 'rider_app', '2026-10-15 00:00:21', '2026-10-15 00:00:21'),
(27, 14, 'delivered', 'Delivered', 'Parcel was successfully delivered by courier cj rubiales.', 'pila, Laguna', '2026-10-15 00:00:40', 'rider_app', '2026-10-15 00:00:40', '2026-10-15 00:00:40'),
(28, 7, 'cancelled', 'Cancelled', 'This shipment has been cancelled.', 'Calamba City, Laguna', '2026-10-15 00:15:08', 'portal', '2026-10-15 00:15:08', '2026-10-15 00:15:08'),
(29, 15, 'pending', 'Received', 'Parcel successfully received by Lumora Logistics.', 'pila, Laguna', '2026-10-15 00:17:01', 'rider_app', '2026-10-15 00:17:01', '2026-10-15 00:17:01'),
(30, 15, 'packed', 'Sorting Center', 'Parcel is being processed at the sorting center.', 'pila, Laguna', '2026-10-15 00:17:15', 'rider_app', '2026-10-15 00:17:15', '2026-10-15 00:17:15'),
(31, 15, 'out_for_delivery', 'Out for Delivery', 'Parcel is out for delivery with courier cj rubiales.', 'pila, Laguna', '2026-10-15 00:18:17', 'rider_app', '2026-10-15 00:18:17', '2026-10-15 00:18:17'),
(32, 15, 'delivered', 'Delivered', 'Parcel was successfully delivered by courier cj rubiales.', 'pila, Laguna', '2026-10-15 00:19:12', 'rider_app', '2026-10-15 00:19:12', '2026-10-15 00:19:12'),
(33, 16, 'pending', 'Received', 'Parcel successfully received by Lumora Logistics.', 'pila, Laguna', '2026-10-15 00:51:58', 'rider_app', '2026-10-15 00:51:58', '2026-10-15 00:51:58'),
(34, 16, 'packed', 'Sorting Center', 'Parcel is being processed at the sorting center.', 'pila, Laguna', '2026-10-15 00:52:16', 'rider_app', '2026-10-15 00:52:16', '2026-10-15 00:52:16'),
(35, 16, 'out_for_delivery', 'Out for Delivery', 'Parcel is out for delivery with courier cj rubiales.', 'pila, Laguna', '2026-10-15 00:54:55', 'rider_app', '2026-10-15 00:54:55', '2026-10-15 00:54:55'),
(36, 16, 'delivered', 'Delivered', 'Parcel was successfully delivered by courier cj rubiales.', 'pila, Laguna', '2026-10-15 00:56:05', 'rider_app', '2026-10-15 00:56:05', '2026-10-15 00:56:05'),
(37, 17, 'pending', 'Received', 'Parcel successfully received by Lumora Logistics.', 'pila, Laguna', '2026-10-15 01:16:26', 'rider_app', '2026-10-15 01:16:26', '2026-10-15 01:16:26'),
(38, 17, 'packed', 'Sorting Center', 'Parcel is being processed at the sorting center.', 'pila, Laguna', '2026-10-15 01:16:35', 'rider_app', '2026-10-15 01:16:35', '2026-10-15 01:16:35'),
(39, 17, 'in_transit', 'In Transit', 'Parcel is currently on the way to its destination.', 'pila, Laguna', '2026-10-15 01:17:48', 'portal', '2026-10-15 01:17:48', '2026-10-15 01:17:48'),
(40, 17, 'out_for_delivery', 'Out for Delivery', 'Parcel is out for delivery with courier jasen jumarang.', 'pila, Laguna', '2026-10-15 01:18:35', 'rider_app', '2026-10-15 01:18:35', '2026-10-15 01:18:35'),
(41, 17, 'delivered', 'Delivered', 'Parcel was successfully delivered by courier jasen jumarang.', 'pila, Laguna', '2026-10-15 01:19:19', 'rider_app', '2026-10-15 01:19:19', '2026-10-15 01:19:19'),
(42, 18, 'pending', 'Received', 'Parcel successfully received by Lumora Logistics.', 'pila, Laguna', '2026-10-15 01:20:35', 'rider_app', '2026-10-15 01:20:35', '2026-10-15 01:20:35'),
(43, 18, 'packed', 'Sorting Center', 'Parcel is being processed at the sorting center.', 'pila, Laguna', '2026-10-15 01:20:42', 'rider_app', '2026-10-15 01:20:42', '2026-10-15 01:20:42'),
(44, 18, 'out_for_delivery', 'Out for Delivery', 'Parcel is out for delivery with courier cj rubiales.', 'pila, Laguna', '2026-10-15 01:21:24', 'rider_app', '2026-10-15 01:21:24', '2026-10-15 01:21:24'),
(45, 19, 'pending', 'Received', 'Parcel successfully received by Lumora Logistics.', 'pila, Laguna', '2026-10-15 01:23:36', 'rider_app', '2026-10-15 01:23:36', '2026-10-15 01:23:36'),
(46, 19, 'packed', 'Sorting Center', 'Parcel is being processed at the sorting center.', 'pila, Laguna', '2026-10-15 01:23:42', 'rider_app', '2026-10-15 01:23:42', '2026-10-15 01:23:42'),
(47, 19, 'in_transit', 'In Transit', 'Parcel is currently on the way to its destination.', 'pila, Laguna', '2026-10-15 01:24:53', 'portal', '2026-10-15 01:24:53', '2026-10-15 01:24:53'),
(48, 19, 'out_for_delivery', 'Out for Delivery', 'Parcel is out for delivery with courier jasen jumarang.', 'pila, Laguna', '2026-10-15 01:25:04', 'rider_app', '2026-10-15 01:25:04', '2026-10-15 01:25:04'),
(49, 19, 'delivered', 'Delivered', 'Parcel was successfully delivered by courier jasen jumarang.', 'pila, Laguna', '2026-10-15 01:25:18', 'rider_app', '2026-10-15 01:25:18', '2026-10-15 01:25:18'),
(50, 20, 'pending', 'Received', 'Parcel successfully received by Lumora Logistics.', 'pila, Laguna', '2026-10-15 03:02:09', 'rider_app', '2026-10-15 03:02:09', '2026-10-15 03:02:09'),
(51, 20, 'packed', 'Sorting Center', 'Parcel is being processed at the sorting center.', 'pila, Laguna', '2026-10-15 03:02:20', 'rider_app', '2026-10-15 03:02:20', '2026-10-15 03:02:20'),
(52, 20, 'in_transit', 'In Transit', 'Parcel is currently on the way to its destination.', 'pila, Laguna', '2026-10-15 03:03:11', 'portal', '2026-10-15 03:03:11', '2026-10-15 03:03:11'),
(53, 20, 'out_for_delivery', 'Out for Delivery', 'Parcel is out for delivery with courier cj rubiales.', 'pila, Laguna', '2026-10-15 03:03:15', 'rider_app', '2026-10-15 03:03:15', '2026-10-15 03:03:15'),
(54, 20, 'delivered', 'Delivered', 'Parcel was successfully delivered by courier cj rubiales.', 'pila, Laguna', '2026-10-15 03:03:34', 'rider_app', '2026-10-15 03:03:34', '2026-10-15 03:03:34'),
(55, 18, 'delivered', 'Delivered', 'Parcel was successfully delivered by courier cj rubiales.', 'pila, Laguna', '2026-10-15 05:42:29', 'rider_app', '2026-10-15 05:42:29', '2026-10-15 05:42:29'),
(56, 21, 'pending', 'Received', 'Parcel successfully received by Lumora Logistics.', 'pila, Laguna', '2026-10-15 06:36:53', 'rider_app', '2026-10-15 06:36:53', '2026-10-15 06:36:53'),
(57, 21, 'packed', 'Sorting Center', 'Parcel is being processed at the sorting center.', 'pila, Laguna', '2026-10-15 06:37:34', 'rider_app', '2026-10-15 06:37:34', '2026-10-15 06:37:34'),
(58, 21, 'in_transit', 'In Transit', 'Package picked up by courier cj rubiales and is in transit.', 'pila, Laguna', '2026-10-15 06:56:23', 'rider_app', '2026-10-15 06:56:23', '2026-10-15 06:56:23'),
(59, 22, 'pending', 'Received', 'Parcel successfully received by Lumora Logistics.', 'pila, Laguna', '2026-10-15 07:11:15', 'rider_app', '2026-10-15 07:11:15', '2026-10-15 07:11:15'),
(60, 22, 'packed', 'Sorting Center', 'Parcel is being processed at the sorting center.', 'pila, Laguna', '2026-10-15 07:11:40', 'rider_app', '2026-10-15 07:11:40', '2026-10-15 07:11:40'),
(61, 22, 'in_transit', 'In Transit', 'Package picked up by courier cj rubiales and is in transit.', 'pila, Laguna', '2026-10-15 07:12:29', 'rider_app', '2026-10-15 07:12:29', '2026-10-15 07:12:29'),
(62, 22, 'out_for_delivery', 'Out for Delivery', 'Parcel is out for delivery with courier cj rubiales.', 'pila, Laguna', '2026-10-15 07:12:42', 'rider_app', '2026-10-15 07:12:42', '2026-10-15 07:12:42'),
(63, 23, 'pending', 'Received', 'Parcel successfully received by Lumora Logistics.', 'pila, Laguna', '2026-10-15 07:13:28', 'rider_app', '2026-10-15 07:13:28', '2026-10-15 07:13:28'),
(64, 23, 'packed', 'Sorting Center', 'Parcel is being processed at the sorting center.', 'pila, Laguna', '2026-10-15 07:13:36', 'rider_app', '2026-10-15 07:13:36', '2026-10-15 07:13:36'),
(65, 23, 'in_transit', 'In Transit', 'Package picked up by courier cj rubiales and is in transit.', 'pila, Laguna', '2026-10-15 07:19:03', 'rider_app', '2026-10-15 07:19:03', '2026-10-15 07:19:03'),
(66, 24, 'pending', 'Received', 'Parcel successfully received by Lumora Logistics.', 'pila, Laguna', '2026-10-15 07:44:05', 'rider_app', '2026-10-15 07:44:05', '2026-10-15 07:44:05'),
(67, 24, 'packed', 'Sorting Center', 'Parcel is being processed at the sorting center.', 'pila, Laguna', '2026-10-15 07:44:35', 'rider_app', '2026-10-15 07:44:35', '2026-10-15 07:44:35'),
(68, 24, 'packed', 'Sorting Center', 'Parcel is being processed at the sorting center.', 'pila, Laguna', '2026-10-15 08:05:35', 'rider_app', '2026-10-15 08:05:35', '2026-10-15 08:05:35'),
(69, 24, 'in_transit', 'In Transit', 'Package picked up by courier cj rubiales and is in transit.', 'pila, Laguna', '2026-10-15 08:06:24', 'rider_app', '2026-10-15 08:06:24', '2026-10-15 08:06:24'),
(70, 24, 'out_for_delivery', 'Out for Delivery', 'Parcel is out for delivery with courier cj rubiales.', 'pila, Laguna', '2026-10-15 08:07:12', 'rider_app', '2026-10-15 08:07:12', '2026-10-15 08:07:12'),
(71, 24, 'delivered', 'Delivered', 'Parcel was successfully delivered by courier cj rubiales.', 'pila, Laguna', '2026-10-15 08:07:32', 'rider_app', '2026-10-15 08:07:32', '2026-10-15 08:07:32'),
(72, 25, 'pending', 'Received', 'Parcel successfully received by Lumora Logistics.', 'pila, Laguna', '2026-10-15 08:09:20', 'rider_app', '2026-10-15 08:09:20', '2026-10-15 08:09:20'),
(73, 25, 'packed', 'Sorting Center', 'Parcel is being processed at the sorting center.', 'pila, Laguna', '2026-10-15 08:09:27', 'rider_app', '2026-10-15 08:09:27', '2026-10-15 08:09:27'),
(74, 26, 'pending', 'Received', 'Parcel successfully received by Lumora Logistics.', 'pila, Laguna', '2026-10-15 08:11:06', 'rider_app', '2026-10-15 08:11:06', '2026-10-15 08:11:06'),
(75, 26, 'packed', 'Sorting Center', 'Parcel is being processed at the sorting center.', 'pila, Laguna', '2026-10-15 08:11:14', 'rider_app', '2026-10-15 08:11:14', '2026-10-15 08:11:14'),
(76, 26, 'in_transit', 'In Transit', 'Package picked up by courier cj rubiales and is in transit.', 'pila, Laguna', '2026-10-15 08:12:53', 'rider_app', '2026-10-15 08:12:53', '2026-10-15 08:12:53'),
(77, 23, 'out_for_delivery', 'Out for Delivery', 'Parcel is out for delivery with courier cj rubiales.', 'pila, Laguna', '2026-10-15 08:12:58', 'rider_app', '2026-10-15 08:12:58', '2026-10-15 08:12:58'),
(78, 21, 'out_for_delivery', 'Out for Delivery', 'Parcel is out for delivery with courier cj rubiales.', 'pila, Laguna', '2026-10-15 08:13:00', 'rider_app', '2026-10-15 08:13:00', '2026-10-15 08:13:00'),
(79, 25, 'in_transit', 'In Transit', 'Package picked up by courier cj rubiales and is in transit.', 'pila, Laguna', '2026-10-15 08:18:59', 'rider_app', '2026-10-15 08:18:59', '2026-10-15 08:18:59'),
(80, 26, 'out_for_delivery', 'Out for Delivery', 'Parcel is out for delivery with courier cj rubiales.', 'pila, Laguna', '2026-10-15 18:32:28', 'rider_app', '2026-10-15 18:32:28', '2026-10-15 18:32:28'),
(81, 27, 'pending', 'Received', 'Parcel successfully received by Lumora Logistics.', 'Santa Cruz, Laguna', '2026-10-15 22:13:13', 'rider_app', '2026-10-15 22:13:13', '2026-10-15 22:13:13'),
(82, 27, 'packed', 'Sorting Center', 'Parcel is being processed at the sorting center.', 'Santa Cruz, Laguna', '2026-10-15 23:37:55', 'rider_app', '2026-10-15 23:37:55', '2026-10-15 23:37:55'),
(83, 27, 'in_transit', 'In Transit', 'Package picked up by courier cj rubiales and is in transit.', 'Santa Cruz, Laguna', '2026-10-15 23:39:23', 'rider_app', '2026-10-15 23:39:23', '2026-10-15 23:39:23'),
(84, 27, 'out_for_delivery', 'Out for Delivery', 'Parcel is out for delivery with courier cj rubiales.', 'Santa Cruz, Laguna', '2026-10-15 23:39:26', 'rider_app', '2026-10-15 23:39:26', '2026-10-15 23:39:26'),
(85, 25, 'out_for_delivery', 'Out for Delivery', 'Parcel is out for delivery with courier cj rubiales.', 'pila, Laguna', '2026-10-15 23:39:27', 'rider_app', '2026-10-15 23:39:27', '2026-10-15 23:39:27'),
(86, 28, 'pending', 'Received', 'Parcel successfully received by Lumora Logistics.', 'Santa Cruz, Laguna', '2026-10-15 23:53:05', 'rider_app', '2026-10-15 23:53:05', '2026-10-15 23:53:05'),
(87, 29, 'pending', 'Received', 'Parcel successfully received by Lumora Logistics.', 'Santa Cruz, Laguna', '2026-10-15 23:53:05', 'rider_app', '2026-10-15 23:53:05', '2026-10-15 23:53:05'),
(88, 25, 'out_for_delivery', 'Out for Delivery', 'Parcel is out for delivery with courier cj rubiales.', 'pila, Laguna', '2026-10-16 03:39:17', 'rider_app', '2026-10-16 03:39:17', '2026-10-16 03:39:17'),
(89, 30, 'pending', 'Received', 'Parcel successfully received by Lumora Logistics.', 'Santa Cruz, Laguna', '2026-10-16 04:15:49', 'rider_app', '2026-10-16 04:15:49', '2026-10-16 04:15:49'),
(90, 31, 'pending', 'Received', 'Parcel successfully received by Lumora Logistics.', 'Santa Cruz, Laguna', '2026-10-16 04:40:53', 'rider_app', '2026-10-16 04:40:53', '2026-10-16 04:40:53'),
(91, 31, 'packed', 'Sorting Center', 'Parcel is being processed at the sorting center.', 'Santa Cruz, Laguna', '2026-10-16 04:42:32', 'rider_app', '2026-10-16 04:42:32', '2026-10-16 04:42:32'),
(92, 31, 'in_transit', 'In Transit', 'Package picked up by courier cj rubiales and is in transit.', 'Santa Cruz, Laguna', '2026-10-16 04:42:56', 'rider_app', '2026-10-16 04:42:56', '2026-10-16 04:42:56'),
(93, 31, 'out_for_delivery', 'Out for Delivery', 'Parcel is out for delivery with courier cj rubiales.', 'Santa Cruz, Laguna', '2026-10-16 04:43:22', 'rider_app', '2026-10-16 04:43:22', '2026-10-16 04:43:22'),
(94, 31, 'delivered', 'Delivered', 'Parcel was successfully delivered by courier cj rubiales.', 'Santa Cruz, Laguna', '2026-10-16 04:43:45', 'rider_app', '2026-10-16 04:43:45', '2026-10-16 04:43:45'),
(95, 27, 'delivered', 'Delivered', 'Parcel was successfully delivered by courier cj rubiales.', 'Santa Cruz, Laguna', '2026-10-16 05:12:43', 'rider_app', '2026-10-16 05:12:43', '2026-10-16 05:12:43'),
(96, 32, 'pending', 'Received', 'Parcel successfully received by Lumora Logistics.', 'Santa Cruz, Laguna', '2026-10-16 05:53:59', 'rider_app', '2026-10-16 05:53:59', '2026-10-16 05:53:59'),
(97, 33, 'pending', 'Received', 'Parcel successfully received by Lumora Logistics.', 'Santa Cruz, Laguna', '2026-10-16 06:06:38', 'rider_app', '2026-10-16 06:06:38', '2026-10-16 06:06:38'),
(98, 34, 'pending', 'Received', 'Parcel successfully received by Lumora Logistics.', 'pila, Laguna', '2026-10-16 06:11:05', 'rider_app', '2026-10-16 06:11:05', '2026-10-16 06:11:05'),
(99, 35, 'pending', 'Received', 'Parcel successfully received by Lumora Logistics.', 'Santa Cruz, Laguna', '2026-10-16 06:14:12', 'rider_app', '2026-10-16 06:14:12', '2026-10-16 06:14:12'),
(100, 36, 'pending', 'Received', 'Parcel successfully received by Lumora Logistics.', 'Santa Cruz, Laguna', '2026-10-16 06:14:12', 'rider_app', '2026-10-16 06:14:12', '2026-10-16 06:14:12'),
(101, 37, 'pending', 'Received', 'Parcel successfully received by Lumora Logistics.', 'Santa Cruz, Laguna', '2026-10-16 06:14:38', 'rider_app', '2026-10-16 06:14:38', '2026-10-16 06:14:38'),
(102, 37, 'packed', 'Sorting Center', 'Parcel is being processed at the sorting center.', 'Santa Cruz, Laguna', '2026-10-16 06:15:50', 'rider_app', '2026-10-16 06:15:50', '2026-10-16 06:15:50'),
(103, 37, 'in_transit', 'In Transit', 'Package picked up by courier cj rubiales and is in transit.', 'Santa Cruz, Laguna', '2026-10-16 06:16:21', 'rider_app', '2026-10-16 06:16:21', '2026-10-16 06:16:21'),
(104, 37, 'out_for_delivery', 'Out for Delivery', 'Parcel is out for delivery with courier cj rubiales.', 'Santa Cruz, Laguna', '2026-10-16 06:16:44', 'rider_app', '2026-10-16 06:16:44', '2026-10-16 06:16:44'),
(105, 37, 'delivered', 'Delivered', 'Parcel was successfully delivered by courier cj rubiales.', 'Santa Cruz, Laguna', '2026-10-16 06:17:01', 'rider_app', '2026-10-16 06:17:01', '2026-10-16 06:17:01'),
(106, 38, 'pending', 'Received', 'Parcel successfully received by Lumora Logistics.', 'Santa Cruz, Laguna', '2026-10-16 06:22:07', 'rider_app', '2026-10-16 06:22:07', '2026-10-16 06:22:07'),
(107, 38, 'packed', 'Sorting Center', 'Parcel is being processed at the sorting center.', 'Santa Cruz, Laguna', '2026-10-16 06:22:23', 'rider_app', '2026-10-16 06:22:23', '2026-10-16 06:22:23'),
(108, 38, 'in_transit', 'In Transit', 'Package picked up by courier jasen jumarang and is in transit.', 'Santa Cruz, Laguna', '2026-10-16 06:23:05', 'rider_app', '2026-10-16 06:23:05', '2026-10-16 06:23:05'),
(109, 38, 'out_for_delivery', 'Out for Delivery', 'Parcel is out for delivery with courier jasen jumarang.', 'Santa Cruz, Laguna', '2026-10-16 06:23:20', 'rider_app', '2026-10-16 06:23:20', '2026-10-16 06:23:20'),
(110, 38, 'delivered', 'Delivered', 'Parcel was successfully delivered by courier jasen jumarang.', 'Santa Cruz, Laguna', '2026-10-16 06:24:03', 'rider_app', '2026-10-16 06:24:03', '2026-10-16 06:24:03'),
(111, 39, 'pending', 'Received', 'Parcel successfully received by Lumora Logistics.', 'Santa Cruz, Laguna', '2026-10-16 17:03:48', 'rider_app', '2026-10-16 17:03:48', '2026-10-16 17:03:48'),
(112, 40, 'pending', 'Received', 'Parcel successfully received by Lumora Logistics.', 'Santa Cruz, Laguna', '2026-10-16 17:05:17', 'rider_app', '2026-10-16 17:05:17', '2026-10-16 17:05:17'),
(113, 40, 'packed', 'Sorting Center', 'Parcel is being processed at the sorting center.', 'Santa Cruz, Laguna', '2026-10-16 17:05:34', 'rider_app', '2026-10-16 17:05:34', '2026-10-16 17:05:34'),
(114, 40, 'in_transit', 'In Transit', 'Package picked up by courier cj rubiales and is in transit.', 'Santa Cruz, Laguna', '2026-10-16 17:06:14', 'rider_app', '2026-10-16 17:06:14', '2026-10-16 17:06:14'),
(115, 40, 'out_for_delivery', 'Out for Delivery', 'Parcel is out for delivery with courier cj rubiales.', 'Santa Cruz, Laguna', '2026-10-16 17:06:44', 'rider_app', '2026-10-16 17:06:44', '2026-10-16 17:06:44'),
(116, 40, 'delivered', 'Delivered', 'Parcel was successfully delivered by courier cj rubiales.', 'Santa Cruz, Laguna', '2026-10-16 17:07:08', 'rider_app', '2026-10-16 17:07:08', '2026-10-16 17:07:08'),
(117, 40, 'delivered', 'Delivered', 'Parcel was successfully delivered by courier cj rubiales.', 'Santa Cruz, Laguna', '2026-10-16 17:39:57', 'rider_app', '2026-10-16 17:39:57', '2026-10-16 17:39:57'),
(118, 26, 'delivered', 'Delivered', 'Parcel was successfully delivered by courier cj rubiales.', 'pila, Laguna', '2026-10-16 17:45:48', 'rider_app', '2026-10-16 17:45:48', '2026-10-16 17:45:48'),
(119, 41, 'pending', 'Received', 'Parcel successfully received by Lumora Logistics.', 'Santa Cruz, Laguna', '2026-10-17 07:13:31', 'rider_app', '2026-10-17 07:13:31', '2026-10-17 07:13:31'),
(120, 42, 'pending', 'Received', 'Parcel successfully received by Lumora Logistics.', 'Santa Cruz, Laguna', '2026-10-17 07:13:31', 'rider_app', '2026-10-17 07:13:31', '2026-10-17 07:13:31'),
(121, 43, 'packed', 'Sorting Center', 'Parcel is being processed at the sorting center.', 'Santa Cruz, Laguna', '2026-10-17 07:13:31', 'rider_app', '2026-10-17 07:13:31', '2026-10-17 07:13:31'),
(122, 44, 'packed', 'Sorting Center', 'Parcel is being processed at the sorting center.', 'Santa Cruz, Laguna', '2026-10-17 07:13:31', 'rider_app', '2026-10-17 07:13:31', '2026-10-17 07:13:31'),
(123, 45, 'delivered', 'Delivered', 'Parcel was successfully delivered by courier Rider 01.', 'Santa Cruz, Laguna', '2026-10-17 07:13:31', 'rider_app', '2026-10-17 07:13:31', '2026-10-17 07:13:31'),
(124, 34, 'packed', 'Sorting Center', 'Parcel is being processed at the sorting center.', 'Pila, Laguna', '2026-10-19 16:21:38', 'rider_app', '2026-10-19 16:21:38', '2026-10-19 16:21:38'),
(125, 34, 'out_for_delivery', 'Out for Delivery', 'Parcel is out for delivery with courier jasen jumarang.', 'Pila, Laguna', '2026-10-19 16:25:54', 'rider_app', '2026-10-19 16:25:54', '2026-10-19 16:25:54'),
(126, 34, 'delivered', 'Delivered', 'Parcel was successfully delivered by courier jasen jumarang.', 'Pila, Laguna', '2026-10-19 16:26:11', 'rider_app', '2026-10-19 16:26:11', '2026-10-19 16:26:11'),
(127, 46, 'pending', 'Received', 'Parcel successfully received by Lumora Logistics.', 'Santa Cruz, Laguna', '2026-10-19 16:27:47', 'rider_app', '2026-10-19 16:27:47', '2026-10-19 16:27:47'),
(128, 25, 'delivered', 'Delivered', 'Parcel was successfully delivered by courier cj rubiales.', 'Pila, Laguna', '2026-10-29 06:10:07', 'rider_app', '2026-10-29 06:10:07', '2026-10-29 06:10:07'),
(129, 47, 'pending', 'Received', 'Parcel successfully received by Lumora Logistics.', 'pila, Laguna', '2026-10-30 16:27:35', 'rider_app', '2026-10-30 16:27:35', '2026-10-30 16:27:35'),
(130, 47, 'packed', 'Sorting Center', 'Parcel is being processed at the sorting center.', 'pila, Laguna', '2026-10-30 16:27:54', 'rider_app', '2026-10-30 16:27:54', '2026-10-30 16:27:54'),
(131, 47, 'out_for_delivery', 'Out for Delivery', 'Parcel is out for delivery with courier cj rubiales.', 'pila, Laguna', '2026-10-30 16:30:33', 'rider_app', '2026-10-30 16:30:33', '2026-10-30 16:30:33'),
(132, 47, 'delivered', 'Delivered', 'Parcel was successfully delivered by courier cj rubiales.', 'pila, Laguna', '2026-10-30 18:44:46', 'rider_app', '2026-10-30 18:44:46', '2026-10-30 18:44:46'),
(133, 48, 'pending', 'Received', 'Parcel successfully received by Lumora Logistics.', 'Santa Cruz, Laguna', '2026-10-30 18:47:33', 'rider_app', '2026-10-30 18:47:33', '2026-10-30 18:47:33'),
(134, 44, 'out_for_delivery', 'Out for Delivery', 'Parcel is out for delivery with courier Rider 01.', 'Santa Cruz, Laguna', '2026-10-30 18:50:18', 'rider_app', '2026-10-30 18:50:18', '2026-10-30 18:50:18'),
(135, 44, 'delivered', 'Delivered', 'Parcel was successfully delivered by courier Rider 01.', 'Santa Cruz, Laguna', '2026-10-30 18:50:35', 'rider_app', '2026-10-30 18:50:35', '2026-10-30 18:50:35');

-- --------------------------------------------------------

--
-- Table structure for table `users`
--

CREATE TABLE `users` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `name` varchar(255) NOT NULL,
  `email` varchar(255) NOT NULL,
  `email_verified_at` timestamp NULL DEFAULT NULL,
  `password` varchar(255) NOT NULL,
  `role` varchar(255) NOT NULL DEFAULT 'admin',
  `branch` varchar(255) DEFAULT NULL,
  `remember_token` varchar(100) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `users`
--

INSERT INTO `users` (`id`, `name`, `email`, `email_verified_at`, `password`, `role`, `branch`, `remember_token`, `created_at`, `updated_at`) VALUES
(1, 'PILA', 'pila@gmail.com', NULL, '$2y$12$uV3wSXoZE4N3H2vpqpnxuODXM1y.B6yI0.KJVHibo/Y1doQE5rBDC', 'admin', 'Pila', NULL, '2026-08-26 20:29:10', '2026-10-17 07:24:49'),
(2, 'Amelia Morgan', 'amelia@lumora.example', NULL, '$2y$12$y0A0UfobJh6txmTxM/NO4O7xXPjIiIsrDcVyEcBzlE4cIt/gqqyeS', 'admin', NULL, 'po22BNo3UkFezIgC8877F78cJMfLLpFJvRH4C7rloiMGQJ92101S6puHNSp7', '2026-08-29 23:00:03', '2026-10-13 01:28:02'),
(3, 'Rider 01', 'rider01@example.com', NULL, '$2y$12$BP8zi6siI/J268wr2VvUyOchLdUm9n5A2a413MxRqplmkAUUDWpJS', 'rider', NULL, NULL, '2026-08-29 23:00:04', '2026-10-13 19:54:12'),
(4, 'Rider 02', 'rider02@example.com', NULL, '12345', 'rider', NULL, NULL, '2026-08-29 23:00:04', '2026-09-27 03:44:17'),
(5, 'Rider 03', 'rider03@example.com', NULL, '45655', 'rider', NULL, NULL, '2026-08-29 23:00:04', '2026-09-27 03:44:18'),
(6, 'John Doe Rider', 'johndoe_test@example.com', NULL, '$2y$12$MI/ay87CrLU9BwxEM6tGv.fq5sG/R6rN/FEHTOYjX8dlUv.1la9Fa', 'rider', NULL, NULL, '2026-10-13 23:38:18', '2026-10-13 23:38:18'),
(7, 'cj rubiales', 'cjrubiales@gmail.com', NULL, '$2y$12$mPKEd5NuOkldjvj9Vqubh.XxwPOVCDyHzjjUYDe9Pnu4doQWtRSIa', 'rider', NULL, NULL, '2026-10-13 23:51:47', '2026-10-13 23:51:47'),
(8, 'jasen jumarang', 'jasen@gmail.com', NULL, '$2y$12$5Qd4KJLbnu6DRHIE6bBthupDtaAu84DbzKwXr6Q8M/iyN13vcybdi', 'rider', NULL, NULL, '2026-10-14 20:49:44', '2026-10-14 20:49:44'),
(9, 'Doc Verification Rider', 'testrider_1792065114@example.com', NULL, '$2y$12$axtwGpWh2ofQHIKfksyvOenBFlJn7uzxAxwBgk82bQR1vnmeETUJK', 'rider', NULL, NULL, '2026-10-15 03:51:55', '2026-10-15 03:51:55'),
(11, 'Doc Verification Rider', 'testrider_1792065223@example.com', NULL, '$2y$12$9jA3/PkZc0jfMqtmGJYEDeIzcM710fD7XSXr.HeYJytRF6Qlm8juq', 'rider', NULL, NULL, '2026-10-15 03:53:43', '2026-10-15 03:53:43'),
(13, 'Sobrevinas justin', 'tatin@gmail.com', NULL, '$2y$12$zYcvb3Mg.J3SpPhke4M0ouoqb5NuLu6bUCwaWox6G9Hutfs7RioNy', 'rider', NULL, NULL, '2026-10-15 04:03:12', '2026-10-15 04:03:12'),
(14, 'nganini totoyngani', 'totoy@gmail.com', NULL, '$2y$12$VCF0gmawk/ZqROdUEwpNuOkHhWFIuOKYFjY.vmfcklX3KnDlcjSPS', 'rider', NULL, NULL, '2026-10-16 18:00:35', '2026-10-16 18:00:35'),
(15, 'SANTA CRUZ', 'stacruz@gmail.com', NULL, '$2y$12$PFaCgVrDo4TmX9A/6YVRMu3H8fV2tvJ3U6f800fE8z.VAgM06RJ0C', 'admin', 'Santa Cruz', NULL, '2026-10-17 07:02:58', '2026-10-29 06:15:54'),
(16, 'Central Logistics HQ', 'admin@gmail.com', NULL, '$2y$12$KPVjaisQi5EbNDj0PSTL3Oa8w0x4kzXKblSQ5cvnq7PIrDMEev.bO', 'super_admin', NULL, NULL, '2026-10-17 07:24:49', '2026-10-17 07:24:49'),
(17, 'Carl John Rubiales', 'carljohnrubiales@gmail.com', NULL, '$2y$12$G.TyGf179CfCtAJqWw2sF.QqWivVOa3wYv2dofvyhSebvF5ZMDLay', 'rider', 'Santa Cruz', NULL, '2026-10-28 20:04:03', '2026-10-28 23:27:02'),
(18, 'carl Rubiales', 'cjrbls12@gmail.com', NULL, '$2y$12$xVu5abcbgDJPA7vN4h7Tz.FDuNWckGd/aKYvKIAyK8xu08nxgnlwS', 'rider', NULL, NULL, '2026-10-29 01:09:15', '2026-10-29 01:09:15'),
(19, 'Alvin Rubiales', 'rubialesarceli@gmail.com', NULL, '$2y$12$0V5vHXTWwxgg3CVnwO3baeOuXACTzfGU1u8ErnTBi9M47.s01aQm6', 'rider', 'Santa Cruz', NULL, '2026-10-29 06:21:20', '2026-10-29 06:21:20'),
(20, 'Justin Sobrevinas', 'jsobrevinas6@gmail.com', NULL, '$2y$12$v5b5f4/9JOMzBfm3IZu4feApquQovEcZ51cMScYdZZ0bSqyEzD9Ra', 'rider', 'Santa Cruz', NULL, '2026-10-30 19:20:46', '2026-10-30 19:20:46');

-- --------------------------------------------------------

--
-- Table structure for table `webhook_deliveries`
--

CREATE TABLE `webhook_deliveries` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `store_id` bigint(20) UNSIGNED DEFAULT NULL,
  `event_id` varchar(255) NOT NULL,
  `event_type` varchar(255) NOT NULL,
  `signature` varchar(255) DEFAULT NULL,
  `payload` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL CHECK (json_valid(`payload`)),
  `status` varchar(255) NOT NULL DEFAULT 'received',
  `attempts` int(10) UNSIGNED NOT NULL DEFAULT 0,
  `processed_at` timestamp NULL DEFAULT NULL,
  `error` text DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Indexes for dumped tables
--

--
-- Indexes for table `audit_logs`
--
ALTER TABLE `audit_logs`
  ADD PRIMARY KEY (`id`),
  ADD KEY `audit_logs_user_id_foreign` (`user_id`),
  ADD KEY `audit_logs_auditable_type_auditable_id_index` (`auditable_type`,`auditable_id`);

--
-- Indexes for table `cache`
--
ALTER TABLE `cache`
  ADD PRIMARY KEY (`key`),
  ADD KEY `cache_expiration_index` (`expiration`);

--
-- Indexes for table `cache_locks`
--
ALTER TABLE `cache_locks`
  ADD PRIMARY KEY (`key`),
  ADD KEY `cache_locks_expiration_index` (`expiration`);

--
-- Indexes for table `commission_transactions`
--
ALTER TABLE `commission_transactions`
  ADD PRIMARY KEY (`id`),
  ADD KEY `commission_transactions_rider_profile_id_foreign` (`rider_profile_id`),
  ADD KEY `commission_transactions_parcel_id_foreign` (`parcel_id`),
  ADD KEY `commission_transactions_status_index` (`status`);

--
-- Indexes for table `destination_areas`
--
ALTER TABLE `destination_areas`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `destination_areas_store_id_code_unique` (`store_id`,`code`);

--
-- Indexes for table `email_otp_verifications`
--
ALTER TABLE `email_otp_verifications`
  ADD PRIMARY KEY (`id`),
  ADD KEY `email_otp_verifications_email_index` (`email`);

--
-- Indexes for table `erp_messages`
--
ALTER TABLE `erp_messages`
  ADD PRIMARY KEY (`id`),
  ADD KEY `erp_messages_sender_id_foreign` (`sender_id`),
  ADD KEY `erp_messages_parcel_id_foreign` (`parcel_id`),
  ADD KEY `erp_messages_recipient_id_read_at_index` (`recipient_id`,`read_at`);

--
-- Indexes for table `failed_jobs`
--
ALTER TABLE `failed_jobs`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `failed_jobs_uuid_unique` (`uuid`);

--
-- Indexes for table `fulfillment_locations`
--
ALTER TABLE `fulfillment_locations`
  ADD PRIMARY KEY (`id`),
  ADD KEY `fulfillment_locations_store_id_foreign` (`store_id`),
  ADD KEY `fulfillment_locations_code_index` (`code`);

--
-- Indexes for table `hubs`
--
ALTER TABLE `hubs`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `inventory_items`
--
ALTER TABLE `inventory_items`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `inventory_items_store_id_sku_unique` (`store_id`,`sku`),
  ADD KEY `inventory_items_fulfillment_location_id_foreign` (`fulfillment_location_id`),
  ADD KEY `inventory_items_sku_index` (`sku`),
  ADD KEY `inventory_items_status_index` (`status`);

--
-- Indexes for table `jobs`
--
ALTER TABLE `jobs`
  ADD PRIMARY KEY (`id`),
  ADD KEY `jobs_queue_index` (`queue`);

--
-- Indexes for table `job_batches`
--
ALTER TABLE `job_batches`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `migrations`
--
ALTER TABLE `migrations`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `orders`
--
ALTER TABLE `orders`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `orders_store_id_external_id_unique` (`store_id`,`external_id`),
  ADD KEY `orders_store_id_status_index` (`store_id`,`status`),
  ADD KEY `orders_status_index` (`status`);

--
-- Indexes for table `order_items`
--
ALTER TABLE `order_items`
  ADD PRIMARY KEY (`id`),
  ADD KEY `order_items_order_id_foreign` (`order_id`);

--
-- Indexes for table `parcels`
--
ALTER TABLE `parcels`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `parcels_parcel_number_unique` (`parcel_number`),
  ADD UNIQUE KEY `parcels_barcode_unique` (`barcode`),
  ADD KEY `parcels_order_id_foreign` (`order_id`),
  ADD KEY `parcels_shipment_id_foreign` (`shipment_id`),
  ADD KEY `parcels_assigned_rider_id_foreign` (`assigned_rider_id`),
  ADD KEY `parcels_store_id_status_index` (`store_id`,`status`),
  ADD KEY `parcels_destination_area_id_status_index` (`destination_area_id`,`status`),
  ADD KEY `parcels_status_index` (`status`);

--
-- Indexes for table `parcel_scans`
--
ALTER TABLE `parcel_scans`
  ADD PRIMARY KEY (`id`),
  ADD KEY `parcel_scans_parcel_id_foreign` (`parcel_id`),
  ADD KEY `parcel_scans_user_id_foreign` (`user_id`);

--
-- Indexes for table `password_reset_tokens`
--
ALTER TABLE `password_reset_tokens`
  ADD PRIMARY KEY (`email`);

--
-- Indexes for table `personal_access_tokens`
--
ALTER TABLE `personal_access_tokens`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `personal_access_tokens_token_unique` (`token`),
  ADD KEY `personal_access_tokens_tokenable_type_tokenable_id_index` (`tokenable_type`,`tokenable_id`),
  ADD KEY `personal_access_tokens_expires_at_index` (`expires_at`);

--
-- Indexes for table `rider_area_assignments`
--
ALTER TABLE `rider_area_assignments`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `rider_area_assignment_unique` (`rider_profile_id`,`destination_area_id`),
  ADD KEY `rider_area_assignments_destination_area_id_foreign` (`destination_area_id`);

--
-- Indexes for table `rider_profiles`
--
ALTER TABLE `rider_profiles`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `rider_profiles_user_id_unique` (`user_id`),
  ADD KEY `rider_profiles_approved_by_foreign` (`approved_by`),
  ADD KEY `rider_profiles_registration_status_index` (`registration_status`),
  ADD KEY `rider_profiles_availability_index` (`availability`),
  ADD KEY `rider_profiles_hub_id_foreign` (`hub_id`);

--
-- Indexes for table `sessions`
--
ALTER TABLE `sessions`
  ADD PRIMARY KEY (`id`),
  ADD KEY `sessions_user_id_index` (`user_id`),
  ADD KEY `sessions_last_activity_index` (`last_activity`);

--
-- Indexes for table `shipments`
--
ALTER TABLE `shipments`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `shipments_order_id_external_id_unique` (`order_id`,`external_id`),
  ADD KEY `shipments_fulfillment_location_id_foreign` (`fulfillment_location_id`),
  ADD KEY `shipments_tracking_number_index` (`tracking_number`),
  ADD KEY `shipments_status_index` (`status`);

--
-- Indexes for table `stores`
--
ALTER TABLE `stores`
  ADD PRIMARY KEY (`id`),
  ADD KEY `stores_platform_is_active_index` (`platform`,`is_active`);

--
-- Indexes for table `tracking_events`
--
ALTER TABLE `tracking_events`
  ADD PRIMARY KEY (`id`),
  ADD KEY `tracking_events_shipment_id_occurred_at_index` (`shipment_id`,`occurred_at`);

--
-- Indexes for table `users`
--
ALTER TABLE `users`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `users_email_unique` (`email`),
  ADD KEY `users_role_index` (`role`);

--
-- Indexes for table `webhook_deliveries`
--
ALTER TABLE `webhook_deliveries`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `webhook_deliveries_event_id_unique` (`event_id`),
  ADD KEY `webhook_deliveries_store_id_foreign` (`store_id`),
  ADD KEY `webhook_deliveries_status_index` (`status`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `audit_logs`
--
ALTER TABLE `audit_logs`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `commission_transactions`
--
ALTER TABLE `commission_transactions`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=18;

--
-- AUTO_INCREMENT for table `destination_areas`
--
ALTER TABLE `destination_areas`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=14;

--
-- AUTO_INCREMENT for table `email_otp_verifications`
--
ALTER TABLE `email_otp_verifications`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=9;

--
-- AUTO_INCREMENT for table `erp_messages`
--
ALTER TABLE `erp_messages`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=8;

--
-- AUTO_INCREMENT for table `failed_jobs`
--
ALTER TABLE `failed_jobs`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `fulfillment_locations`
--
ALTER TABLE `fulfillment_locations`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `hubs`
--
ALTER TABLE `hubs`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT for table `inventory_items`
--
ALTER TABLE `inventory_items`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `jobs`
--
ALTER TABLE `jobs`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `migrations`
--
ALTER TABLE `migrations`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=15;

--
-- AUTO_INCREMENT for table `orders`
--
ALTER TABLE `orders`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=49;

--
-- AUTO_INCREMENT for table `order_items`
--
ALTER TABLE `order_items`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=13;

--
-- AUTO_INCREMENT for table `parcels`
--
ALTER TABLE `parcels`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=35;

--
-- AUTO_INCREMENT for table `parcel_scans`
--
ALTER TABLE `parcel_scans`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=211;

--
-- AUTO_INCREMENT for table `personal_access_tokens`
--
ALTER TABLE `personal_access_tokens`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=77;

--
-- AUTO_INCREMENT for table `rider_area_assignments`
--
ALTER TABLE `rider_area_assignments`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=18;

--
-- AUTO_INCREMENT for table `rider_profiles`
--
ALTER TABLE `rider_profiles`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=17;

--
-- AUTO_INCREMENT for table `shipments`
--
ALTER TABLE `shipments`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=49;

--
-- AUTO_INCREMENT for table `stores`
--
ALTER TABLE `stores`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `tracking_events`
--
ALTER TABLE `tracking_events`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=136;

--
-- AUTO_INCREMENT for table `users`
--
ALTER TABLE `users`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=21;

--
-- AUTO_INCREMENT for table `webhook_deliveries`
--
ALTER TABLE `webhook_deliveries`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `audit_logs`
--
ALTER TABLE `audit_logs`
  ADD CONSTRAINT `audit_logs_user_id_foreign` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE SET NULL;

--
-- Constraints for table `commission_transactions`
--
ALTER TABLE `commission_transactions`
  ADD CONSTRAINT `commission_transactions_parcel_id_foreign` FOREIGN KEY (`parcel_id`) REFERENCES `parcels` (`id`) ON DELETE SET NULL,
  ADD CONSTRAINT `commission_transactions_rider_profile_id_foreign` FOREIGN KEY (`rider_profile_id`) REFERENCES `rider_profiles` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `destination_areas`
--
ALTER TABLE `destination_areas`
  ADD CONSTRAINT `destination_areas_store_id_foreign` FOREIGN KEY (`store_id`) REFERENCES `stores` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `erp_messages`
--
ALTER TABLE `erp_messages`
  ADD CONSTRAINT `erp_messages_parcel_id_foreign` FOREIGN KEY (`parcel_id`) REFERENCES `parcels` (`id`) ON DELETE SET NULL,
  ADD CONSTRAINT `erp_messages_recipient_id_foreign` FOREIGN KEY (`recipient_id`) REFERENCES `users` (`id`) ON DELETE SET NULL,
  ADD CONSTRAINT `erp_messages_sender_id_foreign` FOREIGN KEY (`sender_id`) REFERENCES `users` (`id`) ON DELETE SET NULL;

--
-- Constraints for table `fulfillment_locations`
--
ALTER TABLE `fulfillment_locations`
  ADD CONSTRAINT `fulfillment_locations_store_id_foreign` FOREIGN KEY (`store_id`) REFERENCES `stores` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `inventory_items`
--
ALTER TABLE `inventory_items`
  ADD CONSTRAINT `inventory_items_fulfillment_location_id_foreign` FOREIGN KEY (`fulfillment_location_id`) REFERENCES `fulfillment_locations` (`id`) ON DELETE SET NULL,
  ADD CONSTRAINT `inventory_items_store_id_foreign` FOREIGN KEY (`store_id`) REFERENCES `stores` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `orders`
--
ALTER TABLE `orders`
  ADD CONSTRAINT `orders_store_id_foreign` FOREIGN KEY (`store_id`) REFERENCES `stores` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `order_items`
--
ALTER TABLE `order_items`
  ADD CONSTRAINT `order_items_order_id_foreign` FOREIGN KEY (`order_id`) REFERENCES `orders` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `parcels`
--
ALTER TABLE `parcels`
  ADD CONSTRAINT `parcels_assigned_rider_id_foreign` FOREIGN KEY (`assigned_rider_id`) REFERENCES `rider_profiles` (`id`) ON DELETE SET NULL,
  ADD CONSTRAINT `parcels_destination_area_id_foreign` FOREIGN KEY (`destination_area_id`) REFERENCES `destination_areas` (`id`) ON DELETE SET NULL,
  ADD CONSTRAINT `parcels_order_id_foreign` FOREIGN KEY (`order_id`) REFERENCES `orders` (`id`) ON DELETE SET NULL,
  ADD CONSTRAINT `parcels_shipment_id_foreign` FOREIGN KEY (`shipment_id`) REFERENCES `shipments` (`id`) ON DELETE SET NULL,
  ADD CONSTRAINT `parcels_store_id_foreign` FOREIGN KEY (`store_id`) REFERENCES `stores` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `parcel_scans`
--
ALTER TABLE `parcel_scans`
  ADD CONSTRAINT `parcel_scans_parcel_id_foreign` FOREIGN KEY (`parcel_id`) REFERENCES `parcels` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `parcel_scans_user_id_foreign` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE SET NULL;

--
-- Constraints for table `rider_area_assignments`
--
ALTER TABLE `rider_area_assignments`
  ADD CONSTRAINT `rider_area_assignments_destination_area_id_foreign` FOREIGN KEY (`destination_area_id`) REFERENCES `destination_areas` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `rider_area_assignments_rider_profile_id_foreign` FOREIGN KEY (`rider_profile_id`) REFERENCES `rider_profiles` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `rider_profiles`
--
ALTER TABLE `rider_profiles`
  ADD CONSTRAINT `rider_profiles_approved_by_foreign` FOREIGN KEY (`approved_by`) REFERENCES `users` (`id`) ON DELETE SET NULL,
  ADD CONSTRAINT `rider_profiles_hub_id_foreign` FOREIGN KEY (`hub_id`) REFERENCES `hubs` (`id`) ON DELETE SET NULL,
  ADD CONSTRAINT `rider_profiles_user_id_foreign` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `shipments`
--
ALTER TABLE `shipments`
  ADD CONSTRAINT `shipments_fulfillment_location_id_foreign` FOREIGN KEY (`fulfillment_location_id`) REFERENCES `fulfillment_locations` (`id`) ON DELETE SET NULL,
  ADD CONSTRAINT `shipments_order_id_foreign` FOREIGN KEY (`order_id`) REFERENCES `orders` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `tracking_events`
--
ALTER TABLE `tracking_events`
  ADD CONSTRAINT `tracking_events_shipment_id_foreign` FOREIGN KEY (`shipment_id`) REFERENCES `shipments` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `webhook_deliveries`
--
ALTER TABLE `webhook_deliveries`
  ADD CONSTRAINT `webhook_deliveries_store_id_foreign` FOREIGN KEY (`store_id`) REFERENCES `stores` (`id`) ON DELETE SET NULL;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
