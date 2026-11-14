-- ==========================================================
-- LUMORA LUXURY MARKETPLACE - MySQL DATABASE SCHEMA & SEED
-- Compatible with: MySQL 5.7+, MySQL 8.0+, MariaDB, phpMyAdmin, XAMPP, AWS RDS
-- Character Set: utf8mb4 (Full Emoji & Multilingual support)
-- ==========================================================

CREATE DATABASE IF NOT EXISTS `lumora_db`
  DEFAULT CHARACTER SET utf8mb4
  DEFAULT COLLATE utf8mb4_unicode_ci;

USE `lumora_db`;

-- Disable Foreign Key checks during table creation and insertion
SET FOREIGN_KEY_CHECKS = 0;

-- ----------------------------------------------------------
-- 1. TABLE: users
-- ----------------------------------------------------------
DROP TABLE IF EXISTS `users`;
CREATE TABLE `users` (
  `id` VARCHAR(50) NOT NULL,
  `full_name` VARCHAR(150) NOT NULL,
  `email` VARCHAR(150) NOT NULL UNIQUE,
  `password` VARCHAR(255) NOT NULL,
  `phone` VARCHAR(30) DEFAULT NULL,
  `role` ENUM('buyer', 'seller', 'admin') NOT NULL DEFAULT 'buyer',
  `points` INT NOT NULL DEFAULT 500,
  `tier` VARCHAR(50) NOT NULL DEFAULT 'Silver Member',
  `avatar_url` VARCHAR(255) DEFAULT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  INDEX `idx_users_email` (`email`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------------------------------------
-- 2. TABLE: categories
-- ----------------------------------------------------------
DROP TABLE IF EXISTS `categories`;
CREATE TABLE `categories` (
  `id` VARCHAR(50) NOT NULL,
  `name` VARCHAR(100) NOT NULL,
  `slug` VARCHAR(100) NOT NULL UNIQUE,
  `icon` VARCHAR(50) DEFAULT 'spa_outlined',
  `image_path` VARCHAR(255) DEFAULT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------------------------------------
-- 3. TABLE: products
-- ----------------------------------------------------------
DROP TABLE IF EXISTS `products`;
CREATE TABLE `products` (
  `id` VARCHAR(50) NOT NULL,
  `name` VARCHAR(200) NOT NULL,
  `price` DECIMAL(12,2) NOT NULL,
  `original_price` DECIMAL(12,2) DEFAULT NULL,
  `category_id` VARCHAR(50) NOT NULL,
  `description` TEXT NOT NULL,
  `rating` DECIMAL(3,2) NOT NULL DEFAULT 4.80,
  `reviews_count` INT NOT NULL DEFAULT 0,
  `sold_count` INT NOT NULL DEFAULT 0,
  `discount_label` VARCHAR(50) DEFAULT NULL,
  `is_flash_deal` TINYINT(1) NOT NULL DEFAULT 0,
  `stock` INT NOT NULL DEFAULT 25,
  `image_path` VARCHAR(255) DEFAULT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  INDEX `idx_products_category` (`category_id`),
  INDEX `idx_products_flash_deal` (`is_flash_deal`),
  CONSTRAINT `fk_products_category` FOREIGN KEY (`category_id`) REFERENCES `categories` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------------------------------------
-- 4. TABLE: product_features
-- ----------------------------------------------------------
DROP TABLE IF EXISTS `product_features`;
CREATE TABLE `product_features` (
  `id` INT AUTO_INCREMENT NOT NULL,
  `product_id` VARCHAR(50) NOT NULL,
  `feature_text` VARCHAR(255) NOT NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_features_product` FOREIGN KEY (`product_id`) REFERENCES `products` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------------------------------------
-- 5. TABLE: product_reviews
-- ----------------------------------------------------------
DROP TABLE IF EXISTS `product_reviews`;
CREATE TABLE `product_reviews` (
  `id` VARCHAR(50) NOT NULL,
  `product_id` VARCHAR(50) NOT NULL,
  `user_id` VARCHAR(50) DEFAULT NULL,
  `user_name` VARCHAR(100) NOT NULL,
  `rating` DECIMAL(2,1) NOT NULL DEFAULT 5.0,
  `comment` TEXT NOT NULL,
  `is_verified_purchase` TINYINT(1) NOT NULL DEFAULT 1,
  `review_date` VARCHAR(50) NOT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  INDEX `idx_reviews_product` (`product_id`),
  CONSTRAINT `fk_reviews_product` FOREIGN KEY (`product_id`) REFERENCES `products` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------------------------------------
-- 6. TABLE: vouchers
-- ----------------------------------------------------------
DROP TABLE IF EXISTS `vouchers`;
CREATE TABLE `vouchers` (
  `id` VARCHAR(50) NOT NULL,
  `code` VARCHAR(50) NOT NULL UNIQUE,
  `description` VARCHAR(255) NOT NULL,
  `badge` VARCHAR(50) NOT NULL DEFAULT 'STOREWIDE',
  `discount_type` ENUM('fixed', 'percent') NOT NULL DEFAULT 'fixed',
  `discount_value` DECIMAL(10,2) NOT NULL,
  `min_spend` DECIMAL(10,2) NOT NULL DEFAULT 0.00,
  `is_active` TINYINT(1) NOT NULL DEFAULT 1,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------------------------------------
-- 7. TABLE: shipping_addresses
-- ----------------------------------------------------------
DROP TABLE IF EXISTS `shipping_addresses`;
CREATE TABLE `shipping_addresses` (
  `id` VARCHAR(50) NOT NULL,
  `user_id` VARCHAR(50) NOT NULL,
  `full_name` VARCHAR(150) NOT NULL,
  `phone` VARCHAR(30) NOT NULL,
  `address_line` VARCHAR(255) NOT NULL,
  `city` VARCHAR(100) NOT NULL,
  `province` VARCHAR(100) NOT NULL,
  `postal_code` VARCHAR(20) NOT NULL,
  `is_default` TINYINT(1) NOT NULL DEFAULT 0,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  INDEX `idx_addresses_user` (`user_id`),
  CONSTRAINT `fk_addresses_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------------------------------------
-- 8. TABLE: payment_methods
-- ----------------------------------------------------------
DROP TABLE IF EXISTS `payment_methods`;
CREATE TABLE `payment_methods` (
  `id` VARCHAR(50) NOT NULL,
  `user_id` VARCHAR(50) NOT NULL,
  `type` VARCHAR(50) NOT NULL, -- e.g., 'Visa', 'Mastercard', 'GCash', 'Maya'
  `account_identifier` VARCHAR(100) NOT NULL, -- e.g., '**** 4829' or '+63 917 890 1234'
  `is_default` TINYINT(1) NOT NULL DEFAULT 0,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_payment_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------------------------------------
-- 9. TABLE: orders
-- ----------------------------------------------------------
DROP TABLE IF EXISTS `orders`;
CREATE TABLE `orders` (
  `id` VARCHAR(50) NOT NULL,
  `user_id` VARCHAR(50) NOT NULL,
  `subtotal` DECIMAL(12,2) NOT NULL,
  `shipping_fee` DECIMAL(10,2) NOT NULL DEFAULT 150.00,
  `discount_amount` DECIMAL(10,2) NOT NULL DEFAULT 0.00,
  `total_amount` DECIMAL(12,2) NOT NULL,
  `payment_method` VARCHAR(100) NOT NULL,
  `status` ENUM('To Pay', 'To Ship', 'To Receive', 'Completed', 'Cancelled') NOT NULL DEFAULT 'To Pay',
  `tracking_number` VARCHAR(100) DEFAULT NULL,
  `shipping_address` TEXT NOT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  INDEX `idx_orders_user` (`user_id`),
  INDEX `idx_orders_status` (`status`),
  CONSTRAINT `fk_orders_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------------------------------------
-- 10. TABLE: order_items
-- ----------------------------------------------------------
DROP TABLE IF EXISTS `order_items`;
CREATE TABLE `order_items` (
  `id` INT AUTO_INCREMENT NOT NULL,
  `order_id` VARCHAR(50) NOT NULL,
  `product_id` VARCHAR(50) NOT NULL,
  `product_name` VARCHAR(200) NOT NULL,
  `unit_price` DECIMAL(12,2) NOT NULL,
  `quantity` INT NOT NULL DEFAULT 1,
  `total_price` DECIMAL(12,2) NOT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  INDEX `idx_order_items_order` (`order_id`),
  CONSTRAINT `fk_order_items_order` FOREIGN KEY (`order_id`) REFERENCES `orders` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_order_items_product` FOREIGN KEY (`product_id`) REFERENCES `products` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------------------------------------
-- 11. TABLE: wishlists
-- ----------------------------------------------------------
DROP TABLE IF EXISTS `wishlists`;
CREATE TABLE `wishlists` (
  `id` INT AUTO_INCREMENT NOT NULL,
  `user_id` VARCHAR(50) NOT NULL,
  `product_id` VARCHAR(50) NOT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `unique_user_product_wishlist` (`user_id`, `product_id`),
  CONSTRAINT `fk_wishlist_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_wishlist_product` FOREIGN KEY (`product_id`) REFERENCES `products` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------------------------------------
-- 12. TABLE: conversations
-- ----------------------------------------------------------
DROP TABLE IF EXISTS `conversations`;
CREATE TABLE `conversations` (
  `id` VARCHAR(50) NOT NULL,
  `user_id` VARCHAR(50) NOT NULL,
  `title` VARCHAR(200) NOT NULL DEFAULT 'Lumora Concierge & Support',
  `status` ENUM('active', 'resolved', 'closed') NOT NULL DEFAULT 'active',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_conv_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------------------------------------
-- 13. TABLE: chat_messages
-- ----------------------------------------------------------
DROP TABLE IF EXISTS `chat_messages`;
CREATE TABLE `chat_messages` (
  `id` VARCHAR(50) NOT NULL,
  `conversation_id` VARCHAR(50) NOT NULL,
  `sender_name` VARCHAR(100) NOT NULL,
  `sender_role` VARCHAR(50) NOT NULL,
  `message` TEXT NOT NULL,
  `is_from_user` TINYINT(1) NOT NULL DEFAULT 0,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  INDEX `idx_messages_conversation` (`conversation_id`),
  CONSTRAINT `fk_messages_conv` FOREIGN KEY (`conversation_id`) REFERENCES `conversations` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------------------------------------
-- 14. TABLE: hero_slides
-- ----------------------------------------------------------
DROP TABLE IF EXISTS `hero_slides`;
CREATE TABLE `hero_slides` (
  `id` VARCHAR(50) NOT NULL,
  `eyebrow` VARCHAR(100) NOT NULL,
  `title` VARCHAR(150) NOT NULL,
  `description` TEXT NOT NULL,
  `image_path` VARCHAR(255) NOT NULL,
  `cta_text` VARCHAR(100) NOT NULL DEFAULT 'Shop Now',
  `sort_order` INT NOT NULL DEFAULT 1,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ==========================================================
-- SEED DATA (Populating Lumora Initial Records)
-- ==========================================================

-- 1. Insert Initial Users
INSERT INTO `users` (`id`, `full_name`, `email`, `password`, `phone`, `role`, `points`, `tier`, `avatar_url`) VALUES
('u-1', 'Sophia Martinez', 'buyer@example.com', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', '+63 917 890 1234', 'buyer', 850, 'Gold VIP Member', NULL),
('u-2', 'Alexander Wright', 'alexander@lumora.luxury', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', '+63 918 555 6789', 'seller', 1200, 'Platinum Seller', NULL),
('u-3', 'Lumora Admin', 'admin@lumora.luxury', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', '+63 920 111 2222', 'admin', 5000, 'Executive', NULL);

-- 2. Insert Categories
INSERT INTO `categories` (`id`, `name`, `slug`, `icon`, `image_path`) VALUES
('luxury', 'Luxury', 'luxury', 'diamond_outlined', 'assets/images/hero/hero-1.jpg'),
('women', 'Women', 'women', 'woman', 'assets/images/flow-menu-womans-apparel.jpg'),
('men', 'Men', 'men', 'man', 'assets/images/flow-menu-mens-apparel.jpg'),
('electronics', 'Electronics', 'electronics', 'devices_outlined', 'assets/images/flow-menu-appliances.jpg'),
('beauty-personal-care', 'Beauty', 'beauty', 'face_retouching_natural', 'assets/images/skincare.jpg'),
('sports-outdoors', 'Sports', 'sports', 'fitness_center_outlined', 'assets/images/flow-menu-sports.jpg'),
('home-living', 'Home & Living', 'home-living', 'home_outlined', 'assets/images/flow-menu-kids.jpg');

-- 3. Insert Products
INSERT INTO `products` (`id`, `name`, `price`, `original_price`, `category_id`, `description`, `rating`, `reviews_count`, `sold_count`, `discount_label`, `is_flash_deal`, `stock`, `image_path`) VALUES
('fd-1', 'Lumora Pro 5G Smartphone', 18999.00, 24999.00, 'electronics', 'Flagship 5G smartphone featuring a 120Hz AMOLED display, 108MP cinematic quad camera, and lightning-fast 67W Turbo Charge.', 4.90, 384, 840, '24% OFF', 1, 14, 'assets/images/lumora-phone.jpg'),
('fd-2', 'Lumora Pure Botanical Glow Serum', 749.00, 1250.00, 'beauty-personal-care', 'Formulated with 10% Niacinamide, Hyaluronic Acid, and Camellia Seed Extract for glass-skin hydration and even tone.', 4.90, 520, 1420, '40% OFF', 1, 35, 'assets/images/skincare.jpg'),
('fd-3', 'UltraLite 15.6" Creator Laptop', 38499.00, 48999.00, 'electronics', 'Ultra-thin magnesium-alloy laptop with 16-Core Processor, 16GB High-Speed DDR5 RAM, and 1TB NVMe Gen4 SSD.', 4.80, 185, 310, '21% OFF', 1, 8, 'assets/images/lumora-laptop.jpg'),
('fd-4', 'Midnight Silk Evening Gown', 4299.00, 6500.00, 'women', 'Tailored pure mulberry silk evening gown with subtle cowl neckline and graceful floor-length silhouette.', 4.95, 142, 290, '34% OFF', 1, 12, 'assets/images/flow-menu-womans-apparel.jpg'),
('fd-5', 'Tailored Cashmere Overcoat', 8899.00, 12500.00, 'men', 'Handcrafted Italian double-faced cashmere overcoat providing unmatched warmth, structure, and tailored poise.', 4.90, 98, 160, '29% OFF', 1, 6, 'assets/images/flow-menu-mens-apparel.jpg'),
('p-1', 'Velvet Radiance Liquid Lipstick', 850.00, 1100.00, 'beauty-personal-care', 'Weightless ultra-matte liquid lipstick that provides 16-hour smudge-proof hydration with rich pigment payoff.', 4.80, 210, 540, '23% OFF', 0, 50, 'assets/images/skincare.jpg'),
('p-2', 'ChronoCraft Gold Automatic Watch', 14500.00, 18500.00, 'luxury', 'Exquisite 18K gold-plated automatic mechanical timepiece with sapphire crystal glass and 50m water resistance.', 4.95, 180, 220, '22% OFF', 0, 15, 'assets/images/hero/hero-1.jpg'),
('p-3', 'Merino Wool Knit Cardigan', 2890.00, 3500.00, 'women', 'Cozy, breathable 100% fine Merino wool cardigan with horn buttons and relaxed luxury drape.', 4.75, 95, 180, '17% OFF', 0, 30, 'assets/images/flow-menu-womans-apparel.jpg'),
('p-4', 'StudioMaster ANC Wireless Headphones', 7990.00, 9990.00, 'electronics', 'Audiophile-grade Active Noise Cancelling headphones featuring 40mm beryllium drivers and 45-hour battery life.', 4.90, 310, 680, '20% OFF', 0, 25, 'assets/images/flow-menu-appliances.jpg'),
('p-5', 'Italian Leather Chelsea Boots', 5450.00, 6900.00, 'men', 'Full-grain Tuscan calfskin leather boots with Goodyear welt construction and non-slip rubber soles.', 4.85, 130, 240, '21% OFF', 0, 20, 'assets/images/flow-menu-mens-apparel.jpg'),
('p-6', 'Artisanal Ceramic Pour-Over Set', 1650.00, 2200.00, 'home-living', 'Hand-glazed stoneware coffee dripper and matching glass server for precision brewing at home.', 4.80, 75, 140, '25% OFF', 0, 40, 'assets/images/flow-menu-kids.jpg');

-- 4. Insert Product Features
INSERT INTO `product_features` (`product_id`, `feature_text`) VALUES
('fd-1', '6.67" 120Hz Curved AMOLED'),
('fd-1', '108MP Pro Cinematic Camera'),
('fd-1', '5000mAh Battery with 67W Fast Charging'),
('fd-1', 'Dual Stereo Speakers with Dolby Atmos'),
('fd-2', '10% Niacinamide + Hyaluronic Complex'),
('fd-2', 'Non-comedogenic & Hypoallergenic'),
('fd-2', 'Dermatologist Tested'),
('fd-2', 'Fragrance-free & Cruelty-free'),
('fd-3', '15.6" 2.8K OLED Display 100% DCI-P3'),
('fd-3', '16GB RAM + 1TB High-Speed SSD'),
('fd-3', 'Backlit Ergonomic Keyboard'),
('fd-3', 'Thunderbolt 4 & Fast Power Delivery'),
('fd-4', '100% Grade 6A Pure Mulberry Silk'),
('fd-4', 'Bias-cut drape with seamless side zipper'),
('fd-4', 'Naturally hypoallergenic and breathable'),
('fd-5', 'Double-Faced Grade A Italian Cashmere'),
('fd-5', 'Hand-stitched horn buttons'),
('fd-5', 'Tailored slim-classic fit with notch lapel');

-- 5. Insert Product Reviews
INSERT INTO `product_reviews` (`id`, `product_id`, `user_id`, `user_name`, `rating`, `comment`, `is_verified_purchase`, `review_date`) VALUES
('rev-1', 'fd-1', 'u-1', 'Sophia M.', 5.0, 'Incredible 120Hz screen and the camera is crystal clear! Premium quality all around.', 1, '2 days ago'),
('rev-2', 'fd-1', NULL, 'Marcus T.', 5.0, 'Best smartphone purchase this year. The 67W fast charging is mindblowing.', 1, '1 week ago'),
('rev-3', 'fd-2', 'u-1', 'Elena R.', 5.0, 'My skin feels deeply hydrated and luminous without any oily residue. A true holy grail!', 1, '3 days ago'),
('rev-4', 'fd-2', NULL, 'Gwen P.', 5.0, 'Faded my dark spots in just 2 weeks. Highly recommended!', 1, '2 weeks ago'),
('rev-5', 'fd-4', NULL, 'Camille V.', 5.0, 'The mulberry silk is so rich and smooth. It fits like a dream for gala nights!', 1, '4 days ago');

-- 6. Insert Vouchers
INSERT INTO `vouchers` (`id`, `code`, `description`, `badge`, `discount_type`, `discount_value`, `min_spend`, `is_active`) VALUES
('v-1', 'LUMORA50', '₱50 OFF on orders over ₱499', 'STOREWIDE', 'fixed', 50.00, 499.00, 1),
('v-2', 'BEAUTY10', '10% OFF on all Skincare items', 'CATEGORY', 'percent', 10.00, 0.00, 1),
('v-3', 'FREESHIP', 'Free Shipping on orders ₱1,000+', 'SHIPPING', 'fixed', 150.00, 1000.00, 1);

-- 7. Insert Shipping Addresses
INSERT INTO `shipping_addresses` (`id`, `user_id`, `full_name`, `phone`, `address_line`, `city`, `province`, `postal_code`, `is_default`) VALUES
('addr-1', 'u-1', 'Sophia Martinez', '+63 917 890 1234', 'Unit 402, Acacia Residences, Katipunan Ave.', 'Quezon City', 'Metro Manila', '1108', 1),
('addr-2', 'u-1', 'Sophia Martinez (Office)', '+63 917 890 1234', '18F Lumora Tower, 5th Avenue, BGC', 'Taguig City', 'Metro Manila', '1634', 0);

-- 8. Insert Hero Carousel Slides
INSERT INTO `hero_slides` (`id`, `eyebrow`, `title`, `description`, `image_path`, `cta_text`, `sort_order`) VALUES
('slide-1', 'NEW ARRIVALS 2026', 'Timeless Luxury For Every Season', 'Explore refined apparel, artisanal fragrance, and curated home essentials.', 'assets/images/hero/hero-1.jpg', 'Shop New Arrivals', 1),
('slide-2', 'PREMIER BEAUTY & SKINCARE', 'Luminous Radiance & Botanical Care', 'Crafted with potent botanical extracts for timeless, healthy glow.', 'assets/images/hero/hero-2.jpg', 'Explore Beauty', 2),
('slide-3', 'CUTTING-EDGE ELECTRONICS', 'Next-Gen Performance & Precision', 'High-performance laptops, crystal-clear audio, and smart devices.', 'assets/images/hero/hero-3.jpg', 'View Tech Deals', 3),
('slide-4', 'LIMITED FLASH SALE', 'Exclusive Deals Up To 50% Off', 'Nationwide shipping on top-rated essentials. Grab yours before stocks run out.', 'assets/images/hero/hero-4.jpg', 'Claim Vouchers', 4);

-- 9. Insert Sample Completed Orders for Tracking
INSERT INTO `orders` (`id`, `user_id`, `subtotal`, `shipping_fee`, `discount_amount`, `total_amount`, `payment_method`, `status`, `tracking_number`, `shipping_address`) VALUES
('ord-1001', 'u-1', 18999.00, 0.00, 50.00, 18949.00, 'Cash on Delivery (COD)', 'To Receive', 'PH-LMR-882910', 'Unit 402, Acacia Residences, Katipunan Ave., Quezon City, Metro Manila 1108'),
('ord-1002', 'u-1', 749.00, 150.00, 0.00, 899.00, 'GCash', 'Completed', 'PH-LMR-771234', 'Unit 402, Acacia Residences, Katipunan Ave., Quezon City, Metro Manila 1108');

INSERT INTO `order_items` (`order_id`, `product_id`, `product_name`, `unit_price`, `quantity`, `total_price`) VALUES
('ord-1001', 'fd-1', 'Lumora Pro 5G Smartphone', 18999.00, 1, 18999.00),
('ord-1002', 'fd-2', 'Lumora Pure Botanical Glow Serum', 749.00, 1, 749.00);

-- 10. Insert Sample Concierge Conversation
INSERT INTO `conversations` (`id`, `user_id`, `title`, `status`) VALUES
('conv-1', 'u-1', 'Lumora Concierge & Support', 'active');

INSERT INTO `chat_messages` (`id`, `conversation_id`, `sender_name`, `sender_role`, `message`, `is_from_user`, `created_at`) VALUES
('msg-1', 'conv-1', 'Lumora Concierge', 'Support', 'Hello and welcome to Lumora! ✨ How can we assist with your shopping today?', 0, NOW() - INTERVAL 15 MINUTE),
('msg-2', 'conv-1', 'Lumora Concierge', 'Support', 'All orders nationwide are covered by our 100% Authentic Guarantee and fast door-to-door delivery.', 0, NOW() - INTERVAL 14 MINUTE);

-- Re-enable Foreign Key checks
SET FOREIGN_KEY_CHECKS = 1;

-- ==========================================================
-- SUCCESS: Database Schema & Seeds Generated Successfully!
-- ==========================================================
