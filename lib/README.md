# 📁 Lumora Codebase Organization Guide

This document provides a quick map of the project structure and file responsibilities for easy reference during development and defense presentations.

---

## 🏗️ Folder Structure Overview

```
lib/
├── data/                      # Data Sources & Mock Repositories
│   └── mock_data.dart         # Universal Marketplace 6-department catalog, categories & flash deals
│
├── models/                    # Data Models & Entities
│   └── models.dart            # Product, CategoryItem, User, CartItem, Review, and Order entities
│
├── providers/                 # State Management (ChangeNotifier + Persistence)
│   ├── auth_provider.dart     # Authentication state (Native Google Sign-In, Email/Pass, SharedPreferences)
│   └── cart_provider.dart     # Shopping cart state, quantity stacking, and calculation logic
│
├── screens/                   # User Interface Screens & Navigation
│   ├── main_screen.dart       # Master BottomNavigationBar wrapper (Home, Categories, Deals, Cart, Account)
│   ├── home_screen.dart       # Marketplace Home feed with departments, search, and carousel
│   ├── categories_screen.dart # Department browser with live search & multi-criteria sorting
│   ├── deals_screen.dart      # ⚡ Flash Deals & Sale Hub with live countdown timer & claimable vouchers
│   ├── product_detail_screen.dart # Product specs, photo gallery, variation selector, and ratings
│   ├── cart_screen.dart       # Interactive cart management with guest gating
│   ├── checkout_screen.dart   # Interactive checkout (Delivery address, COD/GCash/Maya, Vouchers)
│   ├── order_success_screen.dart # Order confirmation with animated receipt & Order ID
│   ├── account_screen.dart    # Buyer profile, Order Status Tracker, Addresses, and Notifications
│   ├── login_screen.dart      # Buyer Sign-In with bottom Google Sign-In button
│   └── register_screen.dart   # ERP Buyer Registration (Personal, auto-age, PH address, ID upload, approval)
│
├── theme/                     # Styling & Design Tokens
│   └── app_theme.dart         # Colors (Plum, Orange, Cream, Blush), Google Fonts, and TextStyles
│
├── widgets/                   # Modular & Reusable UI Components
│   ├── auth_modal.dart        # Action-gating bottom sheet prompting guest users to sign in
│   ├── cards.dart             # Responsive ProductCard and DealCard widgets
│   └── google_icon.dart       # Authentic 4-color custom painter Google vector logo
│
└── main.dart                  # Application entry point with MultiProvider setup & theme configuration
```

---

## 🎯 Quick Reference for Common Tasks:

| If you need to edit... | Go to file... |
| :--- | :--- |
| **Catalog Products / Prices / Departments** | [`lib/data/mock_data.dart`](file:///c:/Users/asus/Desktop/lumora/lib/data/mock_data.dart) |
| **Colors, Typography, or Styling** | [`lib/theme/app_theme.dart`](file:///c:/Users/asus/Desktop/lumora/lib/theme/app_theme.dart) |
| **Google Sign-In or Login Session** | [`lib/providers/auth_provider.dart`](file:///c:/Users/asus/Desktop/lumora/lib/providers/auth_provider.dart) |
| **Cart Logic & Price Computation** | [`lib/providers/cart_provider.dart`](file:///c:/Users/asus/Desktop/lumora/lib/providers/cart_provider.dart) |
| **Buyer Registration Form / Approval Dialog** | [`lib/screens/register_screen.dart`](file:///c:/Users/asus/Desktop/lumora/lib/screens/register_screen.dart) |
| **Flash Deals / Sale Hub & Timer** | [`lib/screens/deals_screen.dart`](file:///c:/Users/asus/Desktop/lumora/lib/screens/deals_screen.dart) |
| **Orders Tracker & Account Settings** | [`lib/screens/account_screen.dart`](file:///c:/Users/asus/Desktop/lumora/lib/screens/account_screen.dart) |
| **Checkout Flow & Payment Methods** | [`lib/screens/checkout_screen.dart`](file:///c:/Users/asus/Desktop/lumora/lib/screens/checkout_screen.dart) |
| **Bottom Navigation Tabs** | [`lib/screens/main_screen.dart`](file:///c:/Users/asus/Desktop/lumora/lib/screens/main_screen.dart) |
