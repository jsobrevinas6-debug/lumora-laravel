import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProductColorOption {
  final String name;
  final Color color;
  final String? imagePath;

  const ProductColorOption({
    required this.name,
    required this.color,
    this.imagePath,
  });
}

class ProductVariant {
  final int id;
  final String name;
  final int stock;

  const ProductVariant({
    required this.id,
    required this.name,
    required this.stock,
  });

  factory ProductVariant.fromJson(Map<String, dynamic> json) {
    return ProductVariant(
      id: (json['id'] as num?)?.toInt() ??
          int.tryParse(json['id']?.toString() ?? '0') ??
          0,
      name: (json['name'] ?? '').toString().trim(),
      stock: (json['stock'] as num?)?.toInt() ??
          int.tryParse(json['stock']?.toString() ?? '0') ??
          0,
    );
  }
}

class Product {
  final String id;
  final String name;
  final String brand;
  final String sku;
  final double price;
  final double? originalPrice;
  final String category;
  final String description;
  final double rating;
  final int reviewsCount;
  final int soldCount;
  final List<Color>? gradient;
  final String? discountLabel;
  final bool isFlashDeal;
  final List<String> features;
  final IconData icon;
  final String? imagePath;
  final List<String> galleryImages;
  final int stock;
  final String? variantType;
  final List<ProductVariant> variants;
  final List<ProductColorOption> _rawColorOptions;
  final String _rawSecondaryOptionLabel;
  final List<String> _rawSecondaryOptions;
  final String materialCare;
  final bool _rawHasSizeGuide;
  final String sellerId;
  final String sellerName;
  final String sellerLocation;

  const Product({
    required this.id,
    required this.name,
    this.brand = 'LUMORA ATELIER',
    this.sku = 'LMR-2026-AUTH',
    required this.price,
    this.originalPrice,
    required this.category,
    required this.description,
    this.rating = 4.8,
    this.reviewsCount = 120,
    this.soldCount = 150,
    this.gradient,
    this.discountLabel,
    this.isFlashDeal = false,
    this.features = const [],
    this.icon = Icons.spa_outlined,
    this.imagePath,
    this.galleryImages = const [],
    this.stock = 25,
    this.variantType,
    this.variants = const [],
    this.sellerId = 'store_lumora_official',
    this.sellerName = 'LUMORA Official Store',
    this.sellerLocation = 'Metro Manila',
    List<ProductColorOption> colorOptions = const [
      ProductColorOption(name: 'Signature Noir', color: Color(0xFF2B2129)),
      ProductColorOption(name: 'Champagne Ivory', color: Color(0xFFEBD9C8)),
      ProductColorOption(name: 'Rosewood Blush', color: Color(0xFFB85E68)),
    ],
    String secondaryOptionLabel = 'Option',
    List<String> secondaryOptions = const ['Standard'],
    this.materialCare = '100% Authentic Lumora Boutique Quality • Store in cool, dry place.',
    bool hasSizeGuide = false,
  })  : _rawColorOptions = colorOptions,
        _rawSecondaryOptionLabel = secondaryOptionLabel,
        _rawSecondaryOptions = secondaryOptions,
        _rawHasSizeGuide = hasSizeGuide;

  bool get hasServerVariants => variants.isNotEmpty;

  bool get _hasGenericDefaultColors =>
      _rawColorOptions.isEmpty ||
      (_rawColorOptions.length == 3 &&
          _rawColorOptions[0].name == 'Signature Noir' &&
          _rawColorOptions[1].name == 'Champagne Ivory' &&
          _rawColorOptions[2].name == 'Rosewood Blush');

  bool get _hasGenericDefaultSecondary =>
      _rawSecondaryOptions.isEmpty ||
      (_rawSecondaryOptions.length == 1 && _rawSecondaryOptions.first == 'Standard');

  /// When a live catalog item supplies real seller-defined `variants` without custom colors,
  /// only render the exact seller variant axis so no synthetic color swatches are fabricated.
  bool get showPrimaryOptionSelector =>
      !hasServerVariants || !_hasGenericDefaultColors;

  ProductVariationProfile get _variationProfile =>
      ProductVariationGenerator.forProduct(id: id, name: name, category: category);

  String get primaryOptionLabel => _variationProfile.primaryLabel;

  List<ProductColorOption> get colorOptions {
    if (hasServerVariants) {
      return _hasGenericDefaultColors ? const <ProductColorOption>[] : _rawColorOptions;
    }
    return _hasGenericDefaultColors ? _variationProfile.primaryOptions : _rawColorOptions;
  }

  String get secondaryOptionLabel {
    if (hasServerVariants) {
      if (variantType != null && variantType!.trim().isNotEmpty) {
        return variantType!.trim();
      }
      return 'Option';
    }
    return (_rawSecondaryOptionLabel == 'Option' || _hasGenericDefaultSecondary)
        ? _variationProfile.secondaryLabel
        : _rawSecondaryOptionLabel;
  }

  List<String> get secondaryOptions {
    if (hasServerVariants) {
      return variants.map((v) => v.name).toList();
    }
    return _hasGenericDefaultSecondary ? _variationProfile.secondaryOptions : _rawSecondaryOptions;
  }

  bool get hasSizeGuide => _rawHasSizeGuide || (!hasServerVariants && _variationProfile.hasSizeGuide);

  String get defaultColorName =>
      (showPrimaryOptionSelector && colorOptions.isNotEmpty) ? colorOptions.first.name : '';

  String get defaultSecondaryOption {
    if (hasServerVariants && variants.isNotEmpty) {
      final inStock = variants.where((v) => v.stock > 0);
      return inStock.isNotEmpty ? inStock.first.name : variants.first.name;
    }
    return secondaryOptions.isNotEmpty ? secondaryOptions.first : 'Standard';
  }

  String get defaultVariationSummary {
    if (!showPrimaryOptionSelector || defaultColorName.isEmpty) {
      return defaultSecondaryOption;
    }
    return '$defaultColorName • $defaultSecondaryOption';
  }

  /// Returns the price for a selected variation.
  /// Real seller `variants` share the server base price; curated profiles only scale prices
  /// for volume/storage/pack tiers (`scalePriceByTier`), never for clothing/shoe/jewelry sizes.
  double priceForVariant({String? color, String? secondaryOption}) {
    if (hasServerVariants || !_variationProfile.scalePriceByTier) {
      return price;
    }
    if (secondaryOption == null || secondaryOption.trim().isEmpty) {
      return price;
    }
    final opts = secondaryOptions;
    final secIdx = opts.indexWhere(
      (o) => o.toLowerCase() == secondaryOption.trim().toLowerCase(),
    );
    if (secIdx <= 0) return price;

    final double tierStep;
    if (price < 500) {
      tierStep = 50.0;
    } else if (price < 1500) {
      tierStep = 150.0;
    } else if (price < 5000) {
      tierStep = 350.0;
    } else {
      tierStep = 1200.0;
    }
    return price + (secIdx * tierStep);
  }

  double? originalPriceForVariant({String? color, String? secondaryOption}) {
    if (originalPrice == null) return null;
    final delta = priceForVariant(color: color, secondaryOption: secondaryOption) - price;
    return originalPrice! + delta;
  }

  String formattedPriceForVariant({String? color, String? secondaryOption}) {
    final p = priceForVariant(color: color, secondaryOption: secondaryOption);
    return p % 1 == 0 ? '₱${p.toInt()}' : '₱${p.toStringAsFixed(2)}';
  }

  String formattedOriginalPriceForVariant({String? color, String? secondaryOption}) {
    final op = originalPriceForVariant(color: color, secondaryOption: secondaryOption);
    if (op == null) return '';
    return op % 1 == 0 ? '₱${op.toInt()}' : '₱${op.toStringAsFixed(2)}';
  }

  /// Returns the stock count for a specific variation.
  /// When real DB `variants` exist, returns that exact variant's database stock.
  int stockForVariant({String? color, String? secondaryOption}) {
    if (hasServerVariants) {
      final target = (secondaryOption ?? '').trim().toLowerCase();
      if (target.isNotEmpty) {
        for (final v in variants) {
          if (v.name.toLowerCase() == target) return v.stock;
        }
      }
      final colorTarget = (color ?? '').trim().toLowerCase();
      if (colorTarget.isNotEmpty) {
        for (final v in variants) {
          if (v.name.toLowerCase() == colorTarget) return v.stock;
        }
      }
      return variants.first.stock;
    }
    return stock;
  }

  bool isVariantOutOfStock({String? color, String? secondaryOption}) =>
      stockForVariant(color: color, secondaryOption: secondaryOption) <= 0;

  String get formattedPrice =>
      price % 1 == 0 ? '₱${price.toInt()}' : '₱${price.toStringAsFixed(2)}';
  String get formattedOriginalPrice => originalPrice != null
      ? (originalPrice! % 1 == 0
            ? '₱${originalPrice!.toInt()}'
            : '₱${originalPrice!.toStringAsFixed(2)}')
      : '';

  int? get discountPercentage {
    if (originalPrice != null && originalPrice! > price) {
      return (((originalPrice! - price) / originalPrice!) * 100).round();
    }
    return null;
  }
}

class CartItem {
  final Product product;
  int quantity;
  bool isSelected;
  String selectedColor;
  String selectedSizeOrOption;

  CartItem({
    required this.product,
    this.quantity = 1,
    this.isSelected = true,
    String? selectedColor,
    String? selectedSizeOrOption,
  })  : selectedColor = selectedColor ?? product.defaultColorName,
        selectedSizeOrOption =
            selectedSizeOrOption ?? product.defaultSecondaryOption;

  String get variationLabel {
    final c = selectedColor.trim();
    final s = selectedSizeOrOption.trim();
    if (c.isEmpty) return s.isEmpty ? 'Standard' : s;
    if (s.isEmpty || s == 'Standard') return c;
    return '$c • $s';
  }

  String get itemKey => '${product.id}_${selectedColor}_$selectedSizeOrOption';

  int? get selectedVariantId {
    if (!product.hasServerVariants) return null;
    final target = selectedSizeOrOption.trim().toLowerCase();
    for (final v in product.variants) {
      if (v.name.toLowerCase() == target) return v.id;
    }
    final colorTarget = selectedColor.trim().toLowerCase();
    for (final v in product.variants) {
      if (v.name.toLowerCase() == colorTarget) return v.id;
    }
    return product.variants.first.id;
  }

  String get selectedVariantName {
    if (!product.hasServerVariants) return variationLabel;
    final id = selectedVariantId;
    if (id != null) {
      for (final v in product.variants) {
        if (v.id == id) return v.name;
      }
    }
    return selectedSizeOrOption.trim().isNotEmpty ? selectedSizeOrOption : variationLabel;
  }

  double get unitPrice => product.priceForVariant(
        color: selectedColor,
        secondaryOption: selectedSizeOrOption,
      );

  String get formattedUnitPrice =>
      unitPrice % 1 == 0 ? '₱${unitPrice.toInt()}' : '₱${unitPrice.toStringAsFixed(2)}';

  int get variantStock => product.stockForVariant(
        color: selectedColor,
        secondaryOption: selectedSizeOrOption,
      );

  double get totalPrice => unitPrice * quantity;
  String get formattedTotalPrice => '₱${totalPrice.toStringAsFixed(2)}';
}

class CategoryItem {
  final String id;
  final String name;
  final IconData icon;
  final String? imagePath;

  const CategoryItem({
    required this.id,
    required this.name,
    required this.icon,
    this.imagePath,
  });
}

class HeroSlide {
  final String id;
  final String eyebrow;
  final String title;
  final String description;
  final String imagePath;
  final String ctaText;

  const HeroSlide({
    required this.id,
    required this.eyebrow,
    required this.title,
    required this.description,
    required this.imagePath,
    this.ctaText = 'Explore Collection',
  });
}

class ChatMessage {
  final String id;
  final String senderName;
  final String senderRole; // 'Buyer', 'Seller', 'Support', 'Bot'
  final String message;
  final DateTime timestamp;
  final bool isFromUser;
  final bool isBot;
  final String? attachmentUrl;
  final String? attachmentName;
  final Map<String, String>? productContext; // {'id', 'name', 'price', 'image'}

  const ChatMessage({
    required this.id,
    required this.senderName,
    required this.senderRole,
    required this.message,
    required this.timestamp,
    required this.isFromUser,
    this.isBot = false,
    this.attachmentUrl,
    this.attachmentName,
    this.productContext,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'senderName': senderName,
    'senderRole': senderRole,
    'body': message,
    'message': message,
    'timestamp': timestamp.toIso8601String(),
    'isFromUser': isFromUser,
    'isBot': isBot,
    'attachmentUrl': attachmentUrl,
    'attachmentName': attachmentName,
    'productContext': productContext,
  };

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
    id: (json['id'] ?? '').toString(),
    senderName: (json['senderName'] ?? json['sender_name']) as String? ?? 'Seller',
    senderRole: (json['senderRole'] ?? json['sender_role']) as String? ?? 'Seller',
    message: (json['body'] ?? json['message'] ?? '').toString(),
    timestamp: DateTime.tryParse(
          (json['timestamp'] ?? json['created_at'])?.toString() ?? '',
        ) ??
        DateTime.now(),
    isFromUser: (json['isFromUser'] ?? json['is_from_user']) as bool? ?? false,
    isBot: (json['isBot'] ?? json['is_bot']) as bool? ?? false,
    attachmentUrl: (json['attachmentUrl'] ?? json['attachment_url']) as String?,
    attachmentName: (json['attachmentName'] ?? json['attachment_name']) as String?,
    productContext: ((json['productContext'] ?? json['product_context']) as Map?)
        ?.map((k, v) => MapEntry(k.toString(), v?.toString() ?? '')),
  );
}

class ConversationThread {
  final String id;
  final String sellerId;
  final String sellerName;
  final String sellerRole;
  final String? sellerAvatar;
  final Map<String, String>? productContext;
  final List<ChatMessage> messages;
  DateTime lastMessageAt;
  int unreadCount;

  ConversationThread({
    required this.id,
    required this.sellerId,
    required this.sellerName,
    this.sellerRole = 'Verified Luxury Merchant',
    this.sellerAvatar,
    this.productContext,
    required this.messages,
    required this.lastMessageAt,
    this.unreadCount = 0,
  });

  String get lastMessagePreview =>
      messages.isNotEmpty ? messages.last.message : 'Start a conversation...';

  Map<String, dynamic> toJson() => {
    'id': id,
    'seller_id': sellerId,
    'sellerName': sellerName,
    'sellerRole': sellerRole,
    'sellerAvatar': sellerAvatar,
    'productContext': productContext,
    'messages': messages.map((m) => m.toJson()).toList(),
    'last_message_at': lastMessageAt.toIso8601String(),
    'unreadCount': unreadCount,
  };

  factory ConversationThread.fromJson(Map<String, dynamic> json) {
    final rawMessages = json['messages'] as List<dynamic>?;
    final parsedMessages = rawMessages != null && rawMessages.isNotEmpty
        ? rawMessages
            .whereType<Map>()
            .map((e) => ChatMessage.fromJson(Map<String, dynamic>.from(e)))
            .toList()
        : (json['last_message'] is Map
            ? [ChatMessage.fromJson(Map<String, dynamic>.from(json['last_message'] as Map))]
            : <ChatMessage>[]);

    return ConversationThread(
      id: (json['id'] ?? '').toString(),
      sellerId: (json['seller_id'] ?? json['sellerId'] ?? '').toString(),
      sellerName: (json['sellerName'] ?? json['seller_name']) as String? ?? 'Lumora Merchant',
      sellerRole: (json['sellerRole'] ?? json['seller_role']) as String? ?? 'Verified Luxury Merchant',
      sellerAvatar: (json['sellerAvatar'] ?? json['seller_avatar']) as String?,
      productContext: ((json['productContext'] ?? json['product_context']) as Map?)
          ?.map((k, v) => MapEntry(k.toString(), v?.toString() ?? '')),
      messages: parsedMessages,
      lastMessageAt: DateTime.tryParse(
            (json['last_message_at'] ?? json['lastMessageAt'])?.toString() ?? '',
          ) ??
          DateTime.now(),
      unreadCount: ((json['unreadCount'] ?? json['unread_count']) as num?)?.toInt() ?? 0,
    );
  }
}

class ShopItem {
  final String id;
  final String name;
  final String? avatar;
  final String? coverImage;
  final bool isVerified;
  final double rating;
  final String responseRate;
  final int productsCount;
  final String joinedDate;
  final String category;
  final String description;
  final bool isOnVacation;

  const ShopItem({
    required this.id,
    required this.name,
    this.avatar,
    this.coverImage,
    this.isVerified = true,
    this.rating = 4.9,
    this.responseRate = '98% (within 1 hr)',
    this.productsCount = 18,
    this.joinedDate = 'Joined 2 yrs ago',
    this.category = 'Skincare & Cosmetics',
    this.description = 'Curated high-grade formulations and authentic luxury aesthetics crafted for glowing skin.',
    this.isOnVacation = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'avatar': avatar,
    'coverImage': coverImage,
    'isVerified': isVerified,
    'rating': rating,
    'responseRate': responseRate,
    'productsCount': productsCount,
    'joinedDate': joinedDate,
    'isOnVacation': isOnVacation,
    'category': category,
    'description': description,
  };

  factory ShopItem.fromJson(Map<String, dynamic> json) => ShopItem(
    id: json['id'] as String? ?? 'shop_1',
    name: json['name'] as String? ?? 'Lumora Official Merchant',
    avatar: json['avatar'] as String?,
    coverImage: json['coverImage'] as String?,
    isVerified: json['isVerified'] as bool? ?? true,
    rating: (json['rating'] as num?)?.toDouble() ?? 4.9,
    responseRate: json['responseRate'] as String? ?? '98% (within 1 hr)',
    productsCount: (json['productsCount'] as num?)?.toInt() ?? 12,
    joinedDate: json['joinedDate'] as String? ?? 'Joined 2024',
    category: json['category'] as String? ?? 'Luxury Beauty',
    description: json['description'] as String? ?? '',
    isOnVacation: json['isOnVacation'] as bool? ?? false,
  );
}

class User {
  final String id;
  final String fullName;
  final String firstName;
  final String lastName;
  final String? middleInitial;
  final String? sex;
  final String? contactNumber;
  final String? dateOfBirth;
  final int? age;
  final String? province;
  final String? municipality;
  final String? barangay;
  final String? street;
  final String? houseNumber;
  final String email;
  final String role; // 'buyer', 'seller'
  final String status; // 'active'
  final String? googleId;
  final String? provider; // 'google', 'local'
  final String? avatar;
  final bool emailVerified;
  final DateTime? emailVerifiedAt;
  final String? passwordHash;
  final String? validIdType;
  final String? validIdPhoto;
  final int points;
  final DateTime joinedDate;

  User({
    required this.id,
    required this.fullName,
    String? firstName,
    String? lastName,
    this.middleInitial,
    this.sex,
    this.contactNumber,
    this.dateOfBirth,
    this.age,
    this.province,
    this.municipality,
    this.barangay,
    this.street,
    this.houseNumber,
    required this.email,
    this.role = 'buyer',
    this.status = 'active',
    this.googleId,
    this.provider,
    this.avatar,
    this.emailVerified = true,
    this.emailVerifiedAt,
    this.passwordHash,
    this.validIdType,
    this.validIdPhoto,
    this.points = 250,
    required this.joinedDate,
  })  : firstName = firstName ?? (fullName.split(' ').isNotEmpty ? fullName.split(' ').first : fullName),
        lastName = lastName ?? (fullName.split(' ').length > 1 ? fullName.split(' ').sublist(1).join(' ') : '');

  bool get isGoogleAccount =>
      provider == 'google' || (googleId != null && googleId!.isNotEmpty);

  String get approvalStatus => status;

  String get fullAddress {
    final parts = [
      if (houseNumber != null && houseNumber!.isNotEmpty) houseNumber,
      if (street != null && street!.isNotEmpty) street,
      if (barangay != null && barangay!.isNotEmpty) barangay,
      if (municipality != null && municipality!.isNotEmpty) municipality,
      if (province != null && province!.isNotEmpty) province,
    ];
    return parts.isNotEmpty ? parts.join(', ') : 'Philippines';
  }

  User copyWith({
    String? id,
    String? fullName,
    String? firstName,
    String? lastName,
    String? middleInitial,
    String? sex,
    String? contactNumber,
    String? dateOfBirth,
    int? age,
    String? province,
    String? municipality,
    String? barangay,
    String? street,
    String? houseNumber,
    String? email,
    String? role,
    String? status,
    String? googleId,
    String? provider,
    String? avatar,
    bool clearAvatar = false,
    bool? emailVerified,
    DateTime? emailVerifiedAt,
    String? passwordHash,
    String? validIdType,
    String? validIdPhoto,
    int? points,
    DateTime? joinedDate,
  }) {
    return User(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      middleInitial: middleInitial ?? this.middleInitial,
      sex: sex ?? this.sex,
      contactNumber: contactNumber ?? this.contactNumber,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      age: age ?? this.age,
      province: province ?? this.province,
      municipality: municipality ?? this.municipality,
      barangay: barangay ?? this.barangay,
      street: street ?? this.street,
      houseNumber: houseNumber ?? this.houseNumber,
      email: email ?? this.email,
      role: role ?? this.role,
      status: status ?? this.status,
      googleId: googleId ?? this.googleId,
      provider: provider ?? this.provider,
      avatar: clearAvatar ? null : (avatar ?? this.avatar),
      emailVerified: emailVerified ?? this.emailVerified,
      emailVerifiedAt: emailVerifiedAt ?? this.emailVerifiedAt,
      passwordHash: passwordHash ?? this.passwordHash,
      validIdType: validIdType ?? this.validIdType,
      validIdPhoto: validIdPhoto ?? this.validIdPhoto,
      points: points ?? this.points,
      joinedDate: joinedDate ?? this.joinedDate,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': fullName,
    'fullName': fullName,
    'first_name': firstName,
    'firstName': firstName,
    'last_name': lastName,
    'lastName': lastName,
    'middle_initial': middleInitial,
    'middleInitial': middleInitial,
    'sex': sex,
    'contact_number': contactNumber,
    'contactNumber': contactNumber,
    'date_of_birth': dateOfBirth,
    'dateOfBirth': dateOfBirth,
    'age': age,
    'province': province,
    'municipality': municipality,
    'barangay': barangay,
    'street': street,
    'house_number': houseNumber,
    'houseNumber': houseNumber,
    'email': email,
    'role': role,
    'status': status,
    'google_id': googleId,
    'googleId': googleId,
    'provider': provider,
    'avatar': avatar,
    'email_verified': emailVerified ? 1 : 0,
    'emailVerified': emailVerified,
    'email_verified_at': emailVerifiedAt?.toIso8601String(),
    'passwordHash': passwordHash,
    'valid_id_type': validIdType,
    'validIdType': validIdType,
    'valid_id_photo': validIdPhoto,
    'validIdPhoto': validIdPhoto,
    'points': points,
    'joinedDate': joinedDate.toIso8601String(),
  };

  factory User.fromJson(Map<String, dynamic> data) => User(
    id: (data['id'] ?? '').toString(),
    fullName: (data['fullName'] ?? data['name'] ?? 'Buyer').toString(),
    firstName: (data['firstName'] ?? data['first_name'])?.toString(),
    lastName: (data['lastName'] ?? data['last_name'])?.toString(),
    middleInitial: (data['middleInitial'] ?? data['middle_initial'])?.toString(),
    sex: data['sex']?.toString(),
    contactNumber: (data['contactNumber'] ?? data['contact_number'])?.toString(),
    dateOfBirth: (data['dateOfBirth'] ?? data['date_of_birth'])?.toString(),
    age: (data['age'] as num?)?.toInt(),
    province: data['province']?.toString(),
    municipality: data['municipality']?.toString(),
    barangay: data['barangay']?.toString(),
    street: data['street']?.toString(),
    houseNumber: (data['houseNumber'] ?? data['house_number'])?.toString(),
    email: (data['email'] ?? '').toString(),
    role: (data['role'] ?? 'buyer').toString(),
    status: (data['approval_status'] == 'pending'
            ? 'pending'
            : (data['status'] ?? data['approval_status'] ?? 'active'))
        .toString(),
    googleId: (data['googleId'] ?? data['google_id'])?.toString(),
    provider: data['provider']?.toString(),
    avatar: data['avatar']?.toString(),
    emailVerified: data['emailVerified'] == true || data['email_verified'] == 1 || data['email_verified'] == true,
    emailVerifiedAt: DateTime.tryParse((data['email_verified_at'] ?? '').toString()),
    passwordHash: data['passwordHash']?.toString(),
    validIdType: (data['validIdType'] ?? data['valid_id_type'])?.toString(),
    validIdPhoto: (data['validIdPhoto'] ?? data['valid_id_photo'])?.toString(),
    points: (data['points'] as num?)?.toInt() ?? 250,
    joinedDate: DateTime.tryParse((data['joinedDate'] ?? data['created_at'] ?? '').toString()) ?? DateTime.now(),
  );
}

class SavedPaymentMethod {
  final String id;
  final String type; // 'gcash', 'maya', 'bank', 'cod'
  final String name; // e.g. 'GCash', 'Maya'
  final String accountName;
  final String accountNumber; // e.g. '0917 123 4567'
  final bool isDefault;

  const SavedPaymentMethod({
    required this.id,
    required this.type,
    required this.name,
    required this.accountName,
    required this.accountNumber,
    this.isDefault = false,
  });

  String get maskedNumber {
    if (accountNumber.length <= 4) return accountNumber;
    final last4 = accountNumber.substring(accountNumber.length - 4);
    return '•••• •••• $last4';
  }
}

class TrendItem {
  final String id;
  final String tag;
  final String title;
  final String subtitle;
  final String imagePath;
  final String categoryTarget;

  const TrendItem({
    required this.id,
    required this.tag,
    required this.title,
    required this.subtitle,
    required this.imagePath,
    required this.categoryTarget,
  });
}

class ProductReview {
  final String id;
  final String? userId;
  final String? productId;
  final String? orderId;
  final String author;
  final double rating;
  final String date;
  final String comment;
  final String? variant;
  final bool isVerified;
  final int helpfulCount;
  final List<String> images;

  const ProductReview({
    required this.id,
    this.userId,
    this.productId,
    this.orderId,
    required this.author,
    required this.rating,
    required this.date,
    required this.comment,
    this.variant,
    this.isVerified = true,
    this.helpfulCount = 0,
    this.images = const [],
  });

  ProductReview copyWith({
    String? id,
    String? userId,
    String? productId,
    String? orderId,
    String? author,
    double? rating,
    String? date,
    String? comment,
    String? variant,
    bool? isVerified,
    int? helpfulCount,
    List<String>? images,
  }) {
    return ProductReview(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      productId: productId ?? this.productId,
      orderId: orderId ?? this.orderId,
      author: author ?? this.author,
      rating: rating ?? this.rating,
      date: date ?? this.date,
      comment: comment ?? this.comment,
      variant: variant ?? this.variant,
      isVerified: isVerified ?? this.isVerified,
      helpfulCount: helpfulCount ?? this.helpfulCount,
      images: images ?? this.images,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'product_id': productId,
    'order_id': orderId,
    'author': author,
    'rating': rating,
    'date': date,
    'review': comment,
    'comment': comment,
    'variant': variant,
    'isVerified': isVerified,
    'helpfulCount': helpfulCount,
    'images': images,
  };

  factory ProductReview.fromJson(Map<String, dynamic> json) => ProductReview(
    id: (json['id'] ?? '').toString(),
    userId: (json['user_id'] ?? json['userId'])?.toString(),
    productId: (json['product_id'] ?? json['productId'])?.toString(),
    orderId: (json['order_id'] ?? json['orderId'])?.toString(),
    author: (json['author'] ?? 'Verified Buyer').toString(),
    rating: (json['rating'] as num?)?.toDouble() ?? 5.0,
    date: (json['date'] ?? 'Just now').toString(),
    comment: (json['review'] ?? json['comment'] ?? '').toString(),
    variant: json['variant']?.toString(),
    isVerified: json['isVerified'] as bool? ?? true,
    helpfulCount: (json['helpfulCount'] as num?)?.toInt() ?? 0,
    images: (json['images'] as List?)?.map((e) => e.toString()).toList() ?? const [],
  );
}

class OrderStatusHistoryItem {
  final String status;
  final String notes;
  final String? location;
  final String? trackingStatus;
  final String? trackingLabel;
  final String? courierName;
  final String? formattedTime;
  final DateTime createdAt;

  const OrderStatusHistoryItem({
    required this.status,
    required this.notes,
    this.location,
    this.trackingStatus,
    this.trackingLabel,
    this.courierName,
    this.formattedTime,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'status': status,
    'notes': notes,
    'note': notes,
    'location': location,
    'tracking_status': trackingStatus,
    'trackingStatus': trackingStatus,
    'tracking_label': trackingLabel,
    'trackingLabel': trackingLabel,
    'courier_name': courierName,
    'courierName': courierName,
    'formatted_time': formattedTime,
    'created_at': createdAt.toIso8601String(),
  };

  factory OrderStatusHistoryItem.fromJson(Map<String, dynamic> json) => OrderStatusHistoryItem(
    status: (json['status'] ?? json['tracking_status'] ?? json['trackingStatus'] ?? 'pending').toString(),
    notes: (json['notes'] ?? json['note'] ?? '').toString(),
    location: json['location'] as String?,
    trackingStatus: (json['tracking_status'] ?? json['trackingStatus']) as String?,
    trackingLabel: (json['tracking_label'] ?? json['trackingLabel']) as String?,
    courierName: (json['courier_name'] ?? json['courierName']) as String?,
    formattedTime: (json['formatted_time'] ?? json['formattedTime']) as String?,
    createdAt: DateTime.tryParse((json['created_at'] ?? json['createdAt'] ?? '').toString()) ?? DateTime.now(),
  );
}

class OrderItem {
  final String productId;
  final String productName;
  final double price;
  final int quantity;
  final String? imagePath;
  final int? variantId;
  final String? variantName;
  final String? variation;

  const OrderItem({
    required this.productId,
    required this.productName,
    required this.price,
    required this.quantity,
    this.imagePath,
    this.variantId,
    this.variantName,
    this.variation,
  });

  Map<String, dynamic> toJson() => {
    'product_id': productId,
    'productId': productId,
    'productName': productName,
    'price': price,
    'quantity': quantity,
    'imagePath': imagePath,
    if (variantId != null) 'variant_id': variantId,
    if (variantName != null) 'variant_name': variantName,
    'variation': variation ?? variantName,
  };

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    final rawVarId = json['variantId'] ?? json['variant_id'];
    final parsedVarId = rawVarId is num
        ? rawVarId.toInt()
        : int.tryParse((rawVarId ?? '').toString());
    final varName = (json['variantName'] ?? json['variant_name'])?.toString();
    final variationStr = (json['variation'] ?? varName)?.toString();
    return OrderItem(
      productId: (json['productId'] ?? json['product_id'] ?? '').toString(),
      productName: json['productName'] as String? ?? 'Luxury Item',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      imagePath: json['imagePath'] as String?,
      variantId: parsedVarId,
      variantName: varName,
      variation: variationStr,
    );
  }
}

class OrderModel {
  final String id;
  final String trackingNumber;
  final DateTime createdAt;
  String status; // Web statuses: 'pending', 'processing', 'packed', 'shipped', 'out_for_delivery', 'delivered', 'cancelled', 'returned'
  final List<OrderItem> items;
  final double totalAmount;
  final double? subtotalAmount;
  final double? shippingFeeAmount;
  final String deliveryAddress;
  final String recipientName;
  final String paymentMethod;
  final String courierName;
  final String driverName;
  final String driverPhone;
  final String vehiclePlate;
  final String? sortingCenterName;
  final String? destinationArea;
  final String? assignedRiderId;
  final List<OrderStatusHistoryItem> statusHistory;
  double progress; // 0.0 to 1.0 along the route
  final String? noteToSeller;
  final String? voucherCode;
  DateTime? deliveredAt;
  bool isAutoCompleted;
  bool isDisputed;
  String? returnRejectionReason;
  String? returnDisputeStatus;
  String? returnStatus;
  String? preferredSolution;
  String? returnReviewNote;
  String? refundStatus;
  double? refundAmount;
  DateTime? refundedAt;
  List<String> returnEvidencePhotos;
  String? returnReason;
  final String? paymentProofPath;
  final String? paymentReferenceLast6;
  String paymentStatus; // 'pending', 'paid', 'verified', 'failed', 'refunded'
  final DateTime? estimatedDelivery;
  final String? statusHeadline;
  final String? statusExplanation;
  final String? statusLabel;

  OrderModel({
    required this.id,
    required this.trackingNumber,
    required this.createdAt,
    required this.status,
    required this.items,
    required this.totalAmount,
    this.subtotalAmount,
    this.shippingFeeAmount,
    required this.deliveryAddress,
    required this.recipientName,
    required this.paymentMethod,
    this.courierName = 'Lumora Express Priority',
    this.driverName = 'Assigning Courier Rider',
    this.driverPhone = 'Courier Dispatch',
    this.vehiclePlate = 'Sorting Hub Dispatch',
    this.sortingCenterName = 'Laguna Central Sorting Hub',
    this.destinationArea = 'Area B (Biñan, Laguna)',
    this.assignedRiderId,
    this.statusHistory = const [],
    this.progress = 0.15,
    this.noteToSeller,
    this.voucherCode,
    this.deliveredAt,
    this.isAutoCompleted = false,
    this.isDisputed = false,
    this.returnRejectionReason,
    this.returnDisputeStatus,
    this.returnStatus,
    this.preferredSolution,
    this.returnReviewNote,
    this.refundStatus,
    this.refundAmount,
    this.refundedAt,
    this.returnEvidencePhotos = const [],
    this.returnReason,
    this.paymentProofPath,
    this.paymentReferenceLast6,
    this.paymentStatus = 'pending',
    this.estimatedDelivery,
    this.statusHeadline,
    this.statusExplanation,
    this.statusLabel,
  });

  bool get hasReturnRequest =>
      (returnStatus != null && returnStatus!.isNotEmpty) ||
      normalizedWebStatus == 'return_requested' ||
      normalizedWebStatus == 'returned' ||
      (returnDisputeStatus != null && returnDisputeStatus!.isNotEmpty);

  bool get isReturnApproved =>
      normalizedWebStatus == 'returned' || returnStatus == 'approved';

  bool get isReturnDenied =>
      returnStatus == 'denied' ||
      (!isReturnApproved &&
          returnRejectionReason != null &&
          returnRejectionReason!.isNotEmpty);

  bool get isWithinReturnWindow {
    final dt = deliveredAt;
    if (dt == null) return true;
    return DateTime.now().difference(dt).inDays <= 7;
  }

  String get orderNumber => id;
  String get formattedTotal => '₱${totalAmount.toStringAsFixed(2)}';
  int get totalItemsCount => items.fold(0, (sum, it) => sum + it.quantity);

  /// Compute Destination Area according to ERP Logistics Matrix
  String get computedAreaCode {
    if (destinationArea != null && destinationArea!.isNotEmpty) {
      return destinationArea!;
    }
    final addr = deliveryAddress.toLowerCase();
    if (addr.contains('santa cruz') || addr.contains('sta cruz') || addr.contains('sta. cruz')) {
      return 'Area A (Santa Cruz, Laguna)';
    } else if (addr.contains('los baños') || addr.contains('los banos')) {
      return 'Area C (Los Baños, Laguna)';
    } else if (addr.contains('biñan') || addr.contains('binan') || addr.contains('pagsanjan')) {
      return 'Area B (Biñan, Laguna)';
    }
    return 'Area B (Laguna Central District)';
  }

  /// Compute Sorting Hub
  String get computedSortingHub => sortingCenterName ?? 'Laguna Central Sorting Hub';

  /// Compute Assigned Rider according to ERP Logistics Matrix
  String get computedAssignedRider {
    if (assignedRiderId != null && assignedRiderId!.isNotEmpty) {
      return assignedRiderId!;
    }
    final area = computedAreaCode;
    if (area.contains('Area A')) return 'Rider 01';
    if (area.contains('Area C')) return 'Rider 03';
    return 'Rider 02';
  }

  /// Normalize status into official web slug ('pending', 'processing', 'packed', 'shipped', 'out_for_delivery', 'delivered', 'cancelled', 'returned')
  String get normalizedWebStatus {
    final s = status.trim().toLowerCase().replaceAll(' ', '_');
    switch (s) {
      case 'to_pay':
      case 'pending':
        return 'pending';
      case 'processing':
        return 'processing';
      case 'to_ship':
      case 'packed':
        return 'packed';
      case 'shipped':
      case 'in_transit':
      case 'rider_received':
        return 'shipped';
      case 'at_sorting_center':
      case 'received':
      case 'scanned':
        return 'at_sorting_center';
      case 'sorted':
        return 'sorted';
      case 'assigned_to_rider':
      case 'assigned':
        return 'assigned_to_rider';
      case 'to_receive':
      case 'out_for_delivery':
        return 'out_for_delivery';
      case 'completed':
      case 'delivered':
        return 'delivered';
      case 'cancelled':
        return 'cancelled';
      case 'return_requested':
        return 'return_requested';
      case 'returned':
        return 'returned';
      case 'delivery_failed':
        return 'delivery_failed';
      default:
        return s;
    }
  }

  /// Human-friendly display label matching web order badges
  String get displayStatus {
    switch (normalizedWebStatus) {
      case 'pending':
        return 'Pending';
      case 'processing':
        return 'Processing';
      case 'packed':
        return 'Packed';
      case 'shipped':
        return 'Shipped';
      case 'at_sorting_center':
        return 'At Sorting Center';
      case 'sorted':
        return 'Sorted (Laguna)';
      case 'assigned_to_rider':
        return 'Assigned to Rider';
      case 'out_for_delivery':
        return 'Out for Delivery';
      case 'delivered':
        return 'Delivered';
      case 'cancelled':
        return 'Cancelled';
      case 'return_requested':
        return 'Return Requested';
      case 'returned':
        return 'Returned';
      case 'delivery_failed':
        return 'Delivery Failed';
      default:
        return status;
    }
  }

  /// Live GPS & Rider tracking is ONLY active once the order is Out for Delivery
  bool get hasActiveRider => normalizedWebStatus == 'out_for_delivery';

  Map<String, dynamic> toJson() => {
    'id': id,
    'order_number': id,
    'trackingNumber': trackingNumber,
    'createdAt': createdAt.toIso8601String(),
    'status': status,
    'items': items.map((e) => e.toJson()).toList(),
    'totalAmount': totalAmount,
    'total': totalAmount,
    'subtotalAmount': subtotalAmount,
    'shippingFeeAmount': shippingFeeAmount,
    'deliveryAddress': deliveryAddress,
    'recipientName': recipientName,
    'paymentMethod': paymentMethod,
    'courierName': courierName,
    'driverName': driverName,
    'driverPhone': driverPhone,
    'vehiclePlate': vehiclePlate,
    'sortingCenterName': sortingCenterName,
    'destinationArea': destinationArea,
    'assignedRiderId': assignedRiderId,
    'statusHistory': statusHistory.map((e) => e.toJson()).toList(),
    'progress': progress,
    'noteToSeller': noteToSeller,
    'voucherCode': voucherCode,
    'deliveredAt': deliveredAt?.toIso8601String(),
    'isAutoCompleted': isAutoCompleted,
    'isDisputed': isDisputed,
    'is_disputed': isDisputed,
    'returnRejectionReason': returnRejectionReason,
    'return_rejection_reason': returnRejectionReason,
    'returnDisputeStatus': returnDisputeStatus,
    'return_dispute_status': returnDisputeStatus,
    'returnStatus': returnStatus,
    'return_status': returnStatus,
    'preferredSolution': preferredSolution,
    'preferred_solution': preferredSolution,
    'returnReviewNote': returnReviewNote,
    'return_review_note': returnReviewNote,
    'refundStatus': refundStatus,
    'refund_status': refundStatus,
    'refundAmount': refundAmount,
    'refund_amount': refundAmount,
    'refundedAt': refundedAt?.toIso8601String(),
    'refunded_at': refundedAt?.toIso8601String(),
    'returnEvidencePhotos': returnEvidencePhotos,
    'return_evidence_photos': returnEvidencePhotos,
    'returnReason': returnReason,
    'return_reason': returnReason,
    'paymentProofPath': paymentProofPath,
    'payment_proof': paymentProofPath,
    'paymentReferenceLast6': paymentReferenceLast6,
    'payment_reference_last6': paymentReferenceLast6,
    'paymentStatus': paymentStatus,
    'payment_status': paymentStatus,
    'estimated_delivery': estimatedDelivery?.toIso8601String(),
    'estimatedDelivery': estimatedDelivery?.toIso8601String(),
    'status_headline': statusHeadline,
    'statusHeadline': statusHeadline,
    'status_explanation': statusExplanation,
    'statusExplanation': statusExplanation,
    'status_label': statusLabel,
    'statusLabel': statusLabel,
  };

  factory OrderModel.fromJson(Map<String, dynamic> json) => OrderModel(
    id: (json['id'] ?? json['order_number'] ?? 'LUM-000').toString(),
    trackingNumber: (json['trackingNumber'] ?? json['tracking_number'] ?? 'PH-LMR-000').toString(),
    createdAt: DateTime.tryParse(json['createdAt'] as String? ?? json['created_at'] as String? ?? '') ?? DateTime.now(),
    status: json['status'] as String? ?? 'pending',
    items: (json['items'] as List<dynamic>?)
            ?.map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [],
    totalAmount: (json['totalAmount'] as num? ?? json['total'] as num?)?.toDouble() ?? 0.0,
    subtotalAmount: (json['subtotalAmount'] as num? ?? json['subtotal'] as num?)?.toDouble(),
    shippingFeeAmount: (json['shippingFeeAmount'] as num? ?? json['shipping_fee'] as num?)?.toDouble(),
    deliveryAddress: (json['deliveryAddress'] ?? json['delivery_address'] ?? 'Metro Manila, Philippines').toString(),
    recipientName: (json['recipientName'] ?? json['recipient_name'] ?? 'Valued Member').toString(),
    paymentMethod: (json['paymentMethod'] ?? json['payment_method'] ?? 'Cash on Delivery (COD)').toString(),
    courierName: (json['courierName'] ?? json['courier'] ?? 'Lumora Express Priority').toString(),
    driverName: (json['driverName'] ?? json['driver_name'] ?? 'Assigning Courier Rider').toString(),
    driverPhone: (json['driverPhone'] ?? json['driver_phone'] ?? 'Courier Dispatch').toString(),
    vehiclePlate: (json['vehiclePlate'] ?? json['vehicle_plate'] ?? 'Sorting Hub Dispatch').toString(),
    sortingCenterName: (json['sortingCenterName'] ?? json['sorting_center_name'] ?? 'Laguna Central Sorting Hub').toString(),
    destinationArea: (json['destinationArea'] ?? json['destination_area'] ?? 'Area B (Biñan, Laguna)').toString(),
    assignedRiderId: (json['assignedRiderId'] ?? json['assigned_rider_id']) as String?,
    statusHistory: (json['statusHistory'] as List<dynamic>? ?? json['status_history'] as List<dynamic>?)
            ?.map((e) => OrderStatusHistoryItem.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [],
    progress: (json['progress'] as num?)?.toDouble() ?? 0.15,
    noteToSeller: (json['noteToSeller'] ?? json['notes'] ?? json['note_to_seller']) as String?,
    voucherCode: (json['voucherCode'] ?? json['voucher_code']) as String?,
    deliveredAt: json['deliveredAt'] != null
        ? DateTime.tryParse(json['deliveredAt'].toString())
        : (json['delivered_at'] != null ? DateTime.tryParse(json['delivered_at'].toString()) : null),
    isAutoCompleted: json['isAutoCompleted'] as bool? ?? false,
    isDisputed: (json['isDisputed'] ?? json['is_disputed']) == true ||
        (json['returnDisputeStatus'] ?? json['return_dispute_status']) == 'under_arbitration',
    returnRejectionReason: (json['returnRejectionReason'] ?? json['return_rejection_reason'])?.toString(),
    returnDisputeStatus: (json['returnDisputeStatus'] ?? json['return_dispute_status'])?.toString(),
    returnStatus: (json['returnStatus'] ?? json['return_status'])?.toString(),
    preferredSolution: (json['preferredSolution'] ?? json['preferred_solution'])?.toString(),
    returnReviewNote: (json['returnReviewNote'] ?? json['return_review_note'])?.toString(),
    refundStatus: (json['refundStatus'] ?? json['refund_status'])?.toString(),
    refundAmount: (json['refundAmount'] as num? ?? json['refund_amount'] as num?)?.toDouble(),
    refundedAt: (json['refundedAt'] ?? json['refunded_at']) != null
        ? DateTime.tryParse((json['refundedAt'] ?? json['refunded_at']).toString())
        : null,
    returnEvidencePhotos: ((json['returnEvidencePhotos'] ?? json['return_evidence_photos']) as List?)
            ?.map((e) => e.toString())
            .toList() ??
        const [],
    returnReason: (json['returnReason'] ?? json['return_reason'])?.toString(),
    paymentProofPath: (json['paymentProofPath'] ?? json['payment_proof']) as String?,
    paymentReferenceLast6: (json['paymentReferenceLast6'] ?? json['payment_reference_last6']) as String?,
    paymentStatus: (json['paymentStatus'] ?? json['payment_status'] ?? 'pending').toString(),
    estimatedDelivery: json['estimated_delivery'] != null
        ? DateTime.tryParse(json['estimated_delivery'].toString())
        : (json['estimatedDelivery'] != null ? DateTime.tryParse(json['estimatedDelivery'].toString()) : null),
    statusHeadline: (json['status_headline'] ?? json['statusHeadline']) as String?,
    statusExplanation: (json['status_explanation'] ?? json['statusExplanation']) as String?,
    statusLabel: (json['status_label'] ?? json['statusLabel']) as String?,
  );
}

class PhilippineAddress {
  String id;
  String recipientName;
  String phoneNumber;
  String province;
  String municipality;
  String barangay;
  String streetName;
  String houseNumber;
  String postalCode;
  String label; // 'Home', 'Work', or 'Other'
  bool isDefault;

  PhilippineAddress({
    required this.id,
    required this.recipientName,
    required this.phoneNumber,
    required this.province,
    required this.municipality,
    required this.barangay,
    required this.streetName,
    this.houseNumber = '',
    required this.postalCode,
    this.label = 'Home',
    this.isDefault = false,
  });

  String get formattedAddress {
    final parts = [
      houseNumber,
      streetName,
      barangay,
      municipality,
      province,
    ].where((p) => p.trim().isNotEmpty).toList();
    return '${parts.join(', ')}${postalCode.isNotEmpty ? ' $postalCode' : ''}';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'recipientName': recipientName,
        'phoneNumber': phoneNumber,
        'province': province,
        'municipality': municipality,
        'barangay': barangay,
        'streetName': streetName,
        'houseNumber': houseNumber,
        'postalCode': postalCode,
        'label': label,
        'isDefault': isDefault,
      };

  factory PhilippineAddress.fromJson(Map<String, dynamic> json) =>
      PhilippineAddress(
        id: (json['id'] ?? 'addr-${DateTime.now().millisecondsSinceEpoch}').toString(),
        recipientName: (json['recipientName'] ?? 'Recipient').toString(),
        phoneNumber: (json['phoneNumber'] ?? '+63 917 892 4101').toString(),
        province: (json['province'] ?? '').toString(),
        municipality: (json['municipality'] ?? '').toString(),
        barangay: (json['barangay'] ?? '').toString(),
        streetName: (json['streetName'] ?? '').toString(),
        houseNumber: (json['houseNumber'] ?? '').toString(),
        postalCode: (json['postalCode'] ?? '').toString(),
        label: (json['label'] ?? 'Home').toString(),
        isDefault: json['isDefault'] as bool? ?? false,
      );
}

class SavedAddressBook {
  static String _keyForUser(User? user) {
    final identifier = (user?.email.trim().isNotEmpty == true)
        ? user!.email.trim().toLowerCase()
        : (user?.id ?? 'guest');
    return 'lumora_saved_addresses_v2_$identifier';
  }

  static List<PhilippineAddress> defaultSeed(User? user) {
    if (user == null) return [];
    final hasUserAddress = (user.province?.trim().isNotEmpty == true) ||
        (user.municipality?.trim().isNotEmpty == true) ||
        (user.barangay?.trim().isNotEmpty == true);
    if (!hasUserAddress) return [];
    return [
      PhilippineAddress(
        id: 'addr-primary',
        recipientName: user.fullName.isNotEmpty ? user.fullName : 'Recipient',
        phoneNumber: user.contactNumber?.isNotEmpty == true ? user.contactNumber! : '',
        province: user.province ?? '',
        municipality: user.municipality ?? '',
        barangay: user.barangay ?? '',
        streetName: user.street ?? '',
        houseNumber: user.houseNumber ?? '',
        postalCode: '',
        label: 'Home',
        isDefault: true,
      ),
    ];
  }

  static Future<List<PhilippineAddress>> load(User? user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_keyForUser(user));
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw) as List<dynamic>;
        final list = decoded
            .map((e) => PhilippineAddress.fromJson(e as Map<String, dynamic>))
            .toList();
        return list;
      }
    } catch (_) {}
    final seeded = defaultSeed(user);
    if (seeded.isNotEmpty) {
      await save(user, seeded);
    }
    return seeded;
  }

  static Future<void> save(User? user, List<PhilippineAddress> addresses) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = jsonEncode(addresses.map((a) => a.toJson()).toList());
      await prefs.setString(_keyForUser(user), raw);
    } catch (_) {}
  }

  static Future<List<PhilippineAddress>> deleteAddress(
    User? user,
    String addressId,
  ) async {
    final list = await load(user);
    if (list.length <= 1) return list;
    final removedWasDefault =
        list.any((a) => a.id == addressId && a.isDefault);
    list.removeWhere((a) => a.id == addressId);
    if (removedWasDefault && list.isNotEmpty) {
      list.first.isDefault = true;
    }
    await save(user, list);
    return list;
  }

  static Future<List<PhilippineAddress>> setDefaultAddress(
    User? user,
    String addressId,
  ) async {
    final list = await load(user);
    for (final a in list) {
      a.isDefault = (a.id == addressId);
    }
    await save(user, list);
    return list;
  }

  static Future<List<PhilippineAddress>> upsertAddress(
    User? user,
    PhilippineAddress address,
  ) async {
    final list = await load(user);
    if (address.isDefault) {
      for (final a in list) {
        a.isDefault = false;
      }
    }
    final idx = list.indexWhere((a) => a.id == address.id);
    if (idx != -1) {
      list[idx] = address;
    } else {
      list.add(address);
    }
    if (!list.any((a) => a.isDefault) && list.isNotEmpty) {
      list.first.isDefault = true;
    }
    await save(user, list);
    return list;
  }
}

class ProductVariationProfile {
  final String primaryLabel;
  final List<ProductColorOption> primaryOptions;
  final String secondaryLabel;
  final List<String> secondaryOptions;
  final bool hasSizeGuide;
  final bool scalePriceByTier;

  const ProductVariationProfile({
    required this.primaryLabel,
    required this.primaryOptions,
    required this.secondaryLabel,
    required this.secondaryOptions,
    this.hasSizeGuide = false,
    this.scalePriceByTier = false,
  });
}

class ProductVariationGenerator {
  static int _stableHash(String input) {
    int hash = 5381;
    for (int i = 0; i < input.length; i++) {
      hash = ((hash << 5) + hash) ^ input.codeUnitAt(i);
    }
    return hash.abs();
  }

  static bool _hasAnyWord(String text, List<String> keywords) {
    for (final k in keywords) {
      if (RegExp('\\b${RegExp.escape(k)}\\b', caseSensitive: false).hasMatch(text)) {
        return true;
      }
    }
    return false;
  }

  static ProductVariationProfile forProduct({
    required String id,
    required String name,
    required String category,
  }) {
    final n = name.toLowerCase();
    final c = category.toLowerCase();
    final seed = _stableHash('${id}_${name}_$category');

    // 1. LIPSTICK / LIP GLOSS / LIP TINT / LIP CARE
    if (_hasAnyWord(n, ['lipstick', 'lipgloss', 'lip', 'tint'])) {
      const shadeBanks = [
        [
          ProductColorOption(name: 'Ruby Velvet #01', color: Color(0xFF9B1B30)),
          ProductColorOption(name: 'Rosewood Nude #04', color: Color(0xFFB76E79)),
          ProductColorOption(name: 'Terracotta Spice #08', color: Color(0xFFC05A46)),
          ProductColorOption(name: 'Berry Bordeaux #12', color: Color(0xFF6B1D2F)),
        ],
        [
          ProductColorOption(name: 'Peony Petal #02', color: Color(0xFFD98292)),
          ProductColorOption(name: 'Cinnamon Chai #06', color: Color(0xFFA45A49)),
          ProductColorOption(name: 'Scarlet Rouge #09', color: Color(0xFFB81D24)),
          ProductColorOption(name: 'Mauve Cashmere #14', color: Color(0xFF9E6B7B)),
        ],
        [
          ProductColorOption(name: 'Coral Sorbet #03', color: Color(0xFFE06D53)),
          ProductColorOption(name: 'Toasted Almond #05', color: Color(0xFFAD6F69)),
          ProductColorOption(name: 'Cherry Fig #11', color: Color(0xFF7D2432)),
          ProductColorOption(name: 'Plum Truffle #15', color: Color(0xFF5D2A42)),
        ],
      ];
      const finishBanks = [
        ['3.5g Velvet Matte', '3.5g Satin Creme', 'Mini Duo Set (2x 2g)'],
        ['5ml Luxe Liquid Tube', '5ml Dewy Stain', 'Gift Set + Lip Liner'],
        ['4g Soft-Blur Matte', '4g High-Shine Lacquer', 'Refillable Couture Case'],
      ];
      return ProductVariationProfile(
        primaryLabel: 'Shade',
        primaryOptions: shadeBanks[seed % shadeBanks.length],
        secondaryLabel: 'Finish & Pack',
        secondaryOptions: finishBanks[(seed ~/ 3) % finishBanks.length],
        scalePriceByTier: true,
      );
    }

    // 2. FOUNDATION / CUSHION / CONCEALER / POWDER / BLUSH / EYESHADOW
    if (_hasAnyWord(n, ['foundation', 'cushion', 'concealer', 'powder', 'blush', 'palette', 'eyeshadow', 'mascara', 'brow'])) {
      const complexionBanks = [
        [
          ProductColorOption(name: '1N0 Porcelain Ivory', color: Color(0xFFF3E2D2)),
          ProductColorOption(name: '2W1 Warm Vanilla', color: Color(0xFFE7CBB3)),
          ProductColorOption(name: '3N1 Natural Sand', color: Color(0xFFD8B292)),
          ProductColorOption(name: '4W2 Golden Honey', color: Color(0xFFC3936F)),
        ],
        [
          ProductColorOption(name: '01 Rose Champagne', color: Color(0xFFE8B4B8)),
          ProductColorOption(name: '02 Peach Nectar', color: Color(0xFFE5987E)),
          ProductColorOption(name: '03 Sunset Terracotta', color: Color(0xFFC66B57)),
          ProductColorOption(name: '04 Rosewood Berry', color: Color(0xFF9F4B5B)),
        ],
      ];
      const sizeBanks = [
        ['Full Compact (15g)', 'Compact + 15g Refill', 'Travel Mini (7g)'],
        ['30ml Atelier Bottle', '30ml + Primer Set', '15ml Purse Size'],
      ];
      return ProductVariationProfile(
        primaryLabel: 'Shade / Palette',
        primaryOptions: complexionBanks[seed % complexionBanks.length],
        secondaryLabel: 'Edition',
        secondaryOptions: sizeBanks[(seed ~/ 2) % sizeBanks.length],
      );
    }

    // 3. FRAGRANCE / PERFUME / EAU DE PARFUM / COLOGNE
    if (_hasAnyWord(n, ['perfume', 'parfum', 'fragrance', 'cologne', 'mist', 'scent'])) {
      const scentBanks = [
        [
          ProductColorOption(name: 'Oud & Damask Rose', color: Color(0xFF6B2D46)),
          ProductColorOption(name: 'Bergamot & White Tea', color: Color(0xFFD9CBA3)),
          ProductColorOption(name: 'Amber Vanilla Noir', color: Color(0xFF4A2E2B)),
        ],
        [
          ProductColorOption(name: 'Peony & Cashmere Musk', color: Color(0xFFE2B6CF)),
          ProductColorOption(name: 'Neroli & Sea Salt', color: Color(0xFFB8D4E3)),
          ProductColorOption(name: 'Santal & Cedarwood', color: Color(0xFF8C6239)),
        ],
      ];
      const bottleBanks = [
        ['30ml Travel Atomizer', '50ml Eau de Parfum', '100ml Collector Flacon'],
        ['50ml EDP Spray', '100ml EDP Spray', '100ml + 10ml Gift Coffret'],
      ];
      return ProductVariationProfile(
        primaryLabel: 'Scent Note',
        primaryOptions: scentBanks[seed % scentBanks.length],
        secondaryLabel: 'Bottle Volume',
        secondaryOptions: bottleBanks[(seed ~/ 2) % bottleBanks.length],
        scalePriceByTier: true,
      );
    }

    // 4. BATH SOAPS, CLAY MASKS, BODY BUTTERS & SKINCARE
    if (_hasAnyWord(n, ['soap', 'butter', 'clay', 'scrub', 'balm', 'charcoal', 'lavender'])) {
      if (n.contains('soap')) {
        return const ProductVariationProfile(
          primaryLabel: 'Botanical Variant',
          primaryOptions: [
            ProductColorOption(name: 'Activated Bamboo Charcoal', color: Color(0xFF2B2D2F)),
            ProductColorOption(name: 'Tea Tree & Eucalyptus', color: Color(0xFF7D9F7B)),
            ProductColorOption(name: 'Oatmeal & Shea Mild', color: Color(0xFFE4D6C1)),
          ],
          secondaryLabel: 'Weight / Pack',
          secondaryOptions: ['100g Single Bar', '2 x 100g Twin Pack', '3-Bar Gift Set'],
          scalePriceByTier: true,
        );
      }
      if (n.contains('clay') || n.contains('mask')) {
        return const ProductVariationProfile(
          primaryLabel: 'Clay Formulation',
          primaryOptions: [
            ProductColorOption(name: 'Rose Kaolin Gentle', color: Color(0xFFD69BA4)),
            ProductColorOption(name: 'French Green Detox', color: Color(0xFF88A387)),
            ProductColorOption(name: 'Moroccan Rhassoul', color: Color(0xFFA77865)),
          ],
          secondaryLabel: 'Jar Size',
          secondaryOptions: ['100g Glass Jar', '200g Spa Size', '100g + Silicone Brush'],
          scalePriceByTier: true,
        );
      }
      return const ProductVariationProfile(
        primaryLabel: 'Botanical Blend',
        primaryOptions: [
          ProductColorOption(name: 'French Lavender', color: Color(0xFFB59EC9)),
          ProductColorOption(name: 'Sweet Almond & Shea', color: Color(0xFFE7D3B6)),
          ProductColorOption(name: 'Chamomile Honey', color: Color(0xFFE5BA73)),
        ],
        secondaryLabel: 'Container Size',
        secondaryOptions: ['150ml Amber Jar', '250ml Full Tub'],
        scalePriceByTier: true,
      );
    }

    if (_hasAnyWord(n, [
          'serum', 'cream', 'cleanser', 'toner', 'sunscreen', 'spf', 'lotion',
          'moisturizer', 'mask', 'essence', 'oil', 'shampoo', 'conditioner',
        ]) ||
        c.contains('beauty') ||
        c.contains('skincare')) {
      const formulaBanks = [
        [
          ProductColorOption(name: 'Radiance Vitamin C+E', color: Color(0xFFF4C469)),
          ProductColorOption(name: 'Hydra-Barrier Ceramide', color: Color(0xFFA9D1E6)),
          ProductColorOption(name: 'Peptide Youth Repair', color: Color(0xFFD8B4E2)),
        ],
        [
          ProductColorOption(name: 'Cica Soothing Calm', color: Color(0xFF9AC5A8)),
          ProductColorOption(name: 'Niacinamide Pore Refine', color: Color(0xFFF0D9C8)),
          ProductColorOption(name: 'Rosehip Gold Elixir', color: Color(0xFFD99B66)),
        ],
        [
          ProductColorOption(name: 'Hyaluronic Deep Dew', color: Color(0xFF88B8D6)),
          ProductColorOption(name: 'Retinol Night Renewal', color: Color(0xFF7A5980)),
          ProductColorOption(name: 'Botanical Green Tea', color: Color(0xFF7D9F7B)),
        ],
      ];
      const volumeBanks = [
        ['30ml Dropper Bottle', '50ml Full Size', '100ml Value Duo (2x 50ml)'],
        ['50ml Jar', '100ml Deluxe Jar', '50ml + Refill Pod'],
        ['150ml Pump Bottle', '250ml Jumbo Size', 'Travel Discovery Kit'],
      ];
      return ProductVariationProfile(
        primaryLabel: 'Formula Type',
        primaryOptions: formulaBanks[seed % formulaBanks.length],
        secondaryLabel: 'Volume',
        secondaryOptions: volumeBanks[(seed ~/ 3) % volumeBanks.length],
        scalePriceByTier: true,
      );
    }

    // 5. SMARTPHONES / TABLETS / LAPTOPS / COMPUTERS
    if (_hasAnyWord(n, [
      'phone', 'smartphone', 'iphone', 'xiaomi', 'samsung', 'galaxy', 'oppo',
      'vivo', 'redmi', 'poco', 'pixel', 'realme', 'tablet', 'ipad', 'laptop',
      'macbook', 'notebook',
    ])) {
      final isXiaomi = n.contains('xiaomi');
      final isApple = n.contains('iphone') || n.contains('macbook') || n.contains('ipad');
      final finishOptions = isXiaomi
          ? const [
              ProductColorOption(name: 'Black Titanium', color: Color(0xFF232528)),
              ProductColorOption(name: 'White Ceramic', color: Color(0xFFF0EFEA)),
              ProductColorOption(name: 'Titanium Blue', color: Color(0xFF42546A)),
            ]
          : (isApple
              ? const [
                  ProductColorOption(name: 'Natural Titanium', color: Color(0xFFA5A29D)),
                  ProductColorOption(name: 'Black Titanium', color: Color(0xFF1F2024)),
                  ProductColorOption(name: 'White Titanium', color: Color(0xFFF0EFEA)),
                  ProductColorOption(name: 'Desert Titanium', color: Color(0xFFCDA898)),
                ]
              : const [
                  ProductColorOption(name: 'Obsidian Black', color: Color(0xFF232528)),
                  ProductColorOption(name: 'Starlight Silver', color: Color(0xFFE3E0D8)),
                  ProductColorOption(name: 'Midnight Sapphire', color: Color(0xFF25334A)),
                  ProductColorOption(name: 'Alpine Emerald', color: Color(0xFF3A5A4B)),
                ]);
      const storageBanks = [
        ['12GB + 256GB', '12GB + 512GB', '16GB + 1TB Ultra'],
        ['256GB Standard', '512GB Pro Edition', '1TB Studio Edition'],
      ];
      return ProductVariationProfile(
        primaryLabel: 'Device Finish',
        primaryOptions: finishOptions,
        secondaryLabel: 'RAM & Storage',
        secondaryOptions: storageBanks[(seed ~/ 2) % storageBanks.length],
        scalePriceByTier: true,
      );
    }

    // 6. WATCHES / JEWELRY / EARRINGS / BRACELETS / RINGS / NECKLACES / EYEWEAR
    if (_hasAnyWord(n, [
      'watch', 'rolex', 'submariner', 'daytona', 'datejust', 'chronograph',
      'necklace', 'pendant', 'ring', 'earring', 'earrings', 'stud', 'bracelet',
      'bangle', 'cuff', 'sunglass', 'sunglasses', 'eyewear',
    ])) {
      final isWatch = _hasAnyWord(n, ['watch', 'rolex', 'submariner', 'daytona', 'datejust', 'chronograph']);
      final isBracelet = _hasAnyWord(n, ['bracelet', 'bangle', 'cuff']);
      final isEarring = _hasAnyWord(n, ['earring', 'earrings', 'stud']);
      final isRing = _hasAnyWord(n, ['ring']);
      final isSilverNamed = n.contains('silver');

      if (isWatch) {
        final isSubmariner = n.contains('submariner');
        final isDaytona = n.contains('daytona');
        final isDatejust = n.contains('datejust');
        return ProductVariationProfile(
          primaryLabel: 'Dial & Bezel',
          primaryOptions: isSubmariner
              ? const [
                  ProductColorOption(name: 'Oystersteel • Black Dial', color: Color(0xFF212428)),
                  ProductColorOption(name: 'Oystersteel • Starbucks Green', color: Color(0xFF1F5438)),
                  ProductColorOption(name: 'Rolesor Two-Tone • Blue Dial', color: Color(0xFF22427C)),
                ]
              : (isDaytona
                  ? const [
                      ProductColorOption(name: 'Panda White Dial • Cerachrom', color: Color(0xFFF3F1EA)),
                      ProductColorOption(name: 'Oystersteel • Gloss Black', color: Color(0xFF1E1F24)),
                      ProductColorOption(name: 'Rose Gold • Chocolate Dial', color: Color(0xFFC28E7A)),
                    ]
                  : const [
                      ProductColorOption(name: 'Fluted Bezel • Champagne', color: Color(0xFFD8C28B)),
                      ProductColorOption(name: 'Fluted Bezel • Mint Green', color: Color(0xFF6B8E78)),
                      ProductColorOption(name: 'Smooth Bezel • Slate Blue', color: Color(0xFF3E526A)),
                    ]),
          secondaryLabel: 'Case Size',
          secondaryOptions: isDaytona
              ? const ['40mm Cosmograph']
              : (isDatejust
                  ? const ['36mm Classic', '41mm Modern']
                  : const ['40mm Classic', '41mm Oystersteel']),
        );
      }

      final metalOptions = isSilverNamed
          ? const [
              ProductColorOption(name: '925 Sterling Silver', color: Color(0xFFC9CED4)),
              ProductColorOption(name: 'Brushed Satin Silver', color: Color(0xFFB1B6BC)),
              ProductColorOption(name: 'Oxidized Vintage Silver', color: Color(0xFF6C7178)),
            ]
          : const [
              ProductColorOption(name: '18K Yellow Gold Vermeil', color: Color(0xFFD4AF37)),
              ProductColorOption(name: '925 Sterling Silver', color: Color(0xFFC9CED4)),
              ProductColorOption(name: '18K Rose Gold', color: Color(0xFFD49A89)),
            ];

      if (isBracelet) {
        return ProductVariationProfile(
          primaryLabel: 'Metal Finish',
          primaryOptions: metalOptions,
          secondaryLabel: 'Wrist Size',
          secondaryOptions: const ['17 cm (Small)', '19 cm (Medium)', '21 cm (Large)'],
        );
      }
      if (isEarring) {
        return ProductVariationProfile(
          primaryLabel: 'Metal Finish',
          primaryOptions: metalOptions,
          secondaryLabel: 'Style / Fit',
          secondaryOptions: const ['Classic Everyday Pair', 'Statement Atelier Pair'],
        );
      }
      if (isRing) {
        return ProductVariationProfile(
          primaryLabel: 'Metal Finish',
          primaryOptions: metalOptions,
          secondaryLabel: 'Ring Size',
          secondaryOptions: const ['US 5', 'US 6', 'US 7', 'US 8', 'US 9'],
          hasSizeGuide: true,
        );
      }
      return ProductVariationProfile(
        primaryLabel: 'Metal Finish',
        primaryOptions: metalOptions,
        secondaryLabel: 'Chain Length',
        secondaryOptions: const ['16" Choker Fit', '18" Standard Fit', '20" Layered Fit'],
      );
    }

    // 7. AUDIO / HEADPHONES / EARBUDS / CAMERAS / ELECTRONICS ACCESSORIES / APPLIANCES
    if (c.contains('electronics') ||
        _hasAnyWord(n, [
          'headphone', 'headphones', 'earbud', 'earbuds', 'airpods', 'speaker',
          'camera', 'charger', 'powerbank', 'keyboard', 'mouse', 'trimmer',
          'shaver', 'dryer',
        ])) {
      const techColors = [
        [
          ProductColorOption(name: 'Matte Graphite', color: Color(0xFF2E3136)),
          ProductColorOption(name: 'Champagne Gold', color: Color(0xFFD7C29E)),
          ProductColorOption(name: 'Cloud Silver', color: Color(0xFFD8DADF)),
        ],
        [
          ProductColorOption(name: 'Carbon Midnight', color: Color(0xFF1A1B1E)),
          ProductColorOption(name: 'Rose Quartz Metallic', color: Color(0xFFD6A9A9)),
          ProductColorOption(name: 'Arctic Frost', color: Color(0xFFECEFF4)),
        ],
      ];
      const bundleBanks = [
        ['Standard Unit', 'With Protective Travel Case'],
        ['Standard Edition', 'With Complete Care Kit'],
      ];
      return ProductVariationProfile(
        primaryLabel: 'Color Finish',
        primaryOptions: techColors[seed % techColors.length],
        secondaryLabel: 'Edition',
        secondaryOptions: bundleBanks[(seed ~/ 2) % bundleBanks.length],
      );
    }

    // 8. FOOTWEAR / SHOES / SNEAKERS / HEELS / LOAFERS / SANDALS / BOOTS
    if (_hasAnyWord(n, [
          'shoe', 'shoes', 'sneaker', 'sneakers', 'loafer', 'loafers', 'heel',
          'heels', 'sandal', 'sandals', 'boot', 'boots', 'mule', 'runner',
          'af1', 'dunk', 'jordan', '550', '327', '9060', '2002r',
        ]) ||
        c.contains('shoe')) {
      final isTripleWhite = n.contains('white') || n.contains('af1');
      final shoeColors = isTripleWhite
          ? const [
              ProductColorOption(name: 'Triple White Leather', color: Color(0xFFF5F5F2)),
              ProductColorOption(name: 'White / Sail Cream', color: Color(0xFFEDE4D7)),
              ProductColorOption(name: 'White / Ash Grey', color: Color(0xFFD3D4D8)),
            ]
          : const [
              ProductColorOption(name: 'Triple White Leather', color: Color(0xFFF5F5F2)),
              ProductColorOption(name: 'Espresso Calfskin', color: Color(0xFF4B3025)),
              ProductColorOption(name: 'Onyx Black Leather', color: Color(0xFF1F1E21)),
            ];
      final isWomensShoe = c.contains('women') || _hasAnyWord(n, ['heel', 'heels', 'mule']);
      return ProductVariationProfile(
        primaryLabel: 'Colorway',
        primaryOptions: shoeColors,
        secondaryLabel: 'Size (EU)',
        secondaryOptions: isWomensShoe
            ? const ['EU 36', 'EU 37', 'EU 38', 'EU 39', 'EU 40']
            : const ['EU 40', 'EU 41', 'EU 42', 'EU 43', 'EU 44'],
        hasSizeGuide: true,
      );
    }

    // 9. BAGS / TOTES / PURSES / WALLETS / LEATHER GOODS
    if (_hasAnyWord(n, ['bag', 'tote', 'clutch', 'wallet', 'cardholder', 'backpack', 'satchel', 'crossbody'])) {
      const leatherBanks = [
        [
          ProductColorOption(name: 'Cognac Tan Leather', color: Color(0xFF9A5B36)),
          ProductColorOption(name: 'Noir Caviar Grain', color: Color(0xFF211E21)),
          ProductColorOption(name: 'Taupe Greige', color: Color(0xFFA89C94)),
          ProductColorOption(name: 'Blush Pink Epsom', color: Color(0xFFDDB3B3)),
        ],
        [
          ProductColorOption(name: 'Bordeaux Wine', color: Color(0xFF61212F)),
          ProductColorOption(name: 'Oatmeal Canvas & Tan', color: Color(0xFFD8C8B4)),
          ProductColorOption(name: 'Emerald Box Calf', color: Color(0xFF234D3C)),
        ],
      ];
      const bagSizes = [
        ['Mini (18cm)', 'Small Classic (24cm)', 'Medium Tote (32cm)'],
        ['Gold Hardware', 'Silver Hardware'],
      ];
      return ProductVariationProfile(
        primaryLabel: 'Leather & Color',
        primaryOptions: leatherBanks[seed % leatherBanks.length],
        secondaryLabel: 'Size / Hardware',
        secondaryOptions: bagSizes[(seed ~/ 2) % bagSizes.length],
      );
    }

    // 10. WOMEN'S & MEN'S APPAREL / CLOTHING / TEES / HOODIES / DRESSES / SHIRTS
    if (_hasAnyWord(n, [
          'tee', 't-shirt', 'shirt', 'blouse', 'top', 'dress', 'jacket', 'coat',
          'blazer', 'trouser', 'trousers', 'pant', 'pants', 'skirt', 'cardigan',
          'sweater', 'polo', 'hoodie', 'pullover', 'jersey', 'shorts', 'jeans',
          'silk', 'linen',
        ]) ||
        c.contains('clothing') ||
        c.contains('women') ||
        c.contains('men')) {
      const fabricBanks = [
        [
          ProductColorOption(name: 'Classic Black', color: Color(0xFF1E1E22)),
          ProductColorOption(name: 'Ivory White', color: Color(0xFFF6F4EE)),
          ProductColorOption(name: 'Charcoal Slate', color: Color(0xFF3E424B)),
          ProductColorOption(name: 'Midnight Navy', color: Color(0xFF222D42)),
        ],
        [
          ProductColorOption(name: 'Champagne Ecru', color: Color(0xFFEADBC8)),
          ProductColorOption(name: 'Dusty Rose Blush', color: Color(0xFFD6A2A8)),
          ProductColorOption(name: 'Mulberry Wine', color: Color(0xFF66293B)),
          ProductColorOption(name: 'Sage Olive', color: Color(0xFF83967E)),
        ],
      ];
      return ProductVariationProfile(
        primaryLabel: 'Colorway',
        primaryOptions: fabricBanks[seed % fabricBanks.length],
        secondaryLabel: 'Size',
        secondaryOptions: const ['XS', 'S', 'M', 'L', 'XL'],
        hasSizeGuide: true,
      );
    }

    // 11. HOME & LIVING / DECOR / CANDLES / BEDDING / KITCHEN
    if (c.contains('home') ||
        _hasAnyWord(n, ['candle', 'diffuser', 'lamp', 'vase', 'pillow', 'bed', 'sheet', 'towel', 'coffee', 'mug', 'organizer'])) {
      const homeColors = [
        [
          ProductColorOption(name: 'Warm Travertine Beige', color: Color(0xFFD9CABB)),
          ProductColorOption(name: 'Brushed Brass Gold', color: Color(0xFFC5A358)),
          ProductColorOption(name: 'Matte Terracotta', color: Color(0xFFB96A52)),
        ],
        [
          ProductColorOption(name: 'Nordic Oat Linen', color: Color(0xFFE7DFD3)),
          ProductColorOption(name: 'Eucalyptus Sage', color: Color(0xFF8FA691)),
          ProductColorOption(name: 'Smoked Anthracite', color: Color(0xFF383B40)),
        ],
      ];
      const homeSizes = [
        ['Single Piece', 'Duo Set (2 pcs)'],
        ['Medium Studio Size', 'Large Statement Size'],
      ];
      return ProductVariationProfile(
        primaryLabel: 'Finish / Tone',
        primaryOptions: homeColors[seed % homeColors.length],
        secondaryLabel: 'Edition',
        secondaryOptions: homeSizes[(seed ~/ 2) % homeSizes.length],
      );
    }

    // 12. SPORTS & OUTDOORS / FITNESS / YOGA / BOTTLE / BASKETBALL
    if (c.contains('sport') ||
        _hasAnyWord(n, ['yoga', 'dumbbell', 'fitness', 'gym', 'bottle', 'tumbler', 'racket', 'ball', 'basketball'])) {
      final isBottle = _hasAnyWord(n, ['bottle', 'tumbler']);
      final isBasketball = n.contains('basketball');
      return ProductVariationProfile(
        primaryLabel: 'Colorway',
        primaryOptions: isBasketball
            ? const [
                ProductColorOption(name: 'Official Leather Orange', color: Color(0xFFD2692C)),
                ProductColorOption(name: 'Indoor Midnight Black', color: Color(0xFF24272B)),
              ]
            : const [
                ProductColorOption(name: 'Matcha Forest', color: Color(0xFF567A5A)),
                ProductColorOption(name: 'Cobalt Velocity', color: Color(0xFF28559A)),
                ProductColorOption(name: 'Stealth Carbon', color: Color(0xFF24272B)),
              ],
        secondaryLabel: isBottle ? 'Capacity' : 'Specification',
        secondaryOptions: isBottle
            ? const ['500ml Insulated', '750ml Classic', '1000ml Adventure']
            : (isBasketball
                ? const ['Size 7 (Official Men)', 'Size 6 (Women / Youth)']
                : const ['Standard Fit', 'Pro Heavy-Duty']),
        scalePriceByTier: isBottle,
      );
    }

    // 13. FALLBACK CURATION
    const bespokeColorBanks = [
      [
        ProductColorOption(name: 'Atelier Plum', color: Color(0xFF4B2039)),
        ProductColorOption(name: 'Champagne Silk', color: Color(0xFFE8D8C8)),
        ProductColorOption(name: 'Rose Gold Vermeil', color: Color(0xFFC98A82)),
      ],
      [
        ProductColorOption(name: 'Alabaster Pearl', color: Color(0xFFF1ECE4)),
        ProductColorOption(name: 'Obsidian Onyx', color: Color(0xFF222126)),
        ProductColorOption(name: 'Venetian Terracotta', color: Color(0xFFB85B45)),
      ],
    ];
    return ProductVariationProfile(
      primaryLabel: 'Finish / Tone',
      primaryOptions: bespokeColorBanks[seed % bespokeColorBanks.length],
      secondaryLabel: 'Edition',
      secondaryOptions: const ['Standard Edition', 'Gift Boxed'],
    );
  }
}




