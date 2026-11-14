import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumora/data/mock_data.dart';
import 'package:lumora/main.dart';
import 'package:lumora/models/models.dart';
import 'package:lumora/providers/auth_provider.dart';
import 'package:lumora/providers/cart_provider.dart';
import 'package:lumora/providers/chat_provider.dart';
import 'package:lumora/providers/follow_provider.dart';
import 'package:lumora/providers/order_provider.dart';
import 'package:lumora/providers/wallet_provider.dart';
import 'package:lumora/providers/wishlist_provider.dart';
import 'package:lumora/screens/cart_screen.dart';
import 'package:lumora/screens/checkout_screen.dart';
import 'package:lumora/screens/home_screen.dart';
import 'package:lumora/screens/product_detail_screen.dart';
import 'package:lumora/screens/splash_screen.dart';
import 'package:lumora/services/api_service.dart';
import 'package:lumora/services/product_repository.dart';
import 'package:lumora/widgets/google_icon.dart';
import 'package:lumora/widgets/live_map_tracker.dart';
import 'package:lumora/widgets/order_tracking_modal.dart';
import 'package:lumora/widgets/voucher_selection_modal.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    ApiConfig.useLiveApi = false;
  });

  group('AuthProvider Unit Tests', () {
    test('Default state is Guest', () {
      final auth = AuthProvider();
      expect(auth.isLoggedIn, false);
      expect(auth.currentUser, isNull);
    });

    test('Empty credentials reject login immediately', () async {
      final auth = AuthProvider();
      final success = await auth.login('', '');
      expect(success, false);
      expect(auth.isLoggedIn, false);
      expect(auth.lastAuthError, contains('Please enter your email and password.'));
    });

    test('Dummy or unregistered accounts are strictly rejected from logging in', () async {
      final auth = AuthProvider();
      final success = await auth.login('unregistered_buyer@test.com', 'wrongpass');
      expect(success, false);
      expect(auth.isLoggedIn, false);
      expect(auth.currentUser, isNull);
      expect(auth.lastAuthError, isNotNull);
    });

    test('Logout returns to Guest state', () async {
      final auth = AuthProvider();
      auth.logout();
      expect(auth.isLoggedIn, false);
      expect(auth.currentUser, isNull);
    });
  });

  group('CartProvider Unit Tests', () {
    test('Initial cart is empty', () {
      final cart = CartProvider();
      expect(cart.totalItemsCount, 0);
      expect(cart.subtotal, 0.0);
      expect(cart.itemList.isEmpty, true);
    });

    test('Adding product increases item count and computes total', () {
      final cart = CartProvider();
      final product = MockData.allProducts.first;

      cart.addToCart(product, quantity: 2);
      expect(cart.totalItemsCount, 2);
      expect(cart.subtotal, product.price * 2);
      expect(cart.isInCart(product.id), true);

      cart.addToCart(product, quantity: 1);
      expect(cart.totalItemsCount, 3);
      expect(cart.subtotal, product.price * 3);
    });

    test('Updating quantity and removing works correctly', () {
      final cart = CartProvider();
      final product = MockData.allProducts.first;

      cart.addToCart(product, quantity: 2);
      cart.updateQuantity(product.id, -1);
      expect(cart.totalItemsCount, 1);

      cart.updateQuantity(product.id, -1);
      expect(cart.totalItemsCount, 0);
      expect(cart.isInCart(product.id), false);
    });
  });

  group('WishlistProvider Unit Tests', () {
    test('Initial wishlist is empty', () {
      final wishlist = WishlistProvider();
      expect(wishlist.count, 0);
      expect(wishlist.isEmpty, true);
    });

    test('Toggle favorite adds and removes product', () {
      final wishlist = WishlistProvider();
      final product = MockData.allProducts.first;

      wishlist.toggleFavorite(product);
      expect(wishlist.isFavorite(product.id), true);
      expect(wishlist.count, 1);

      wishlist.toggleFavorite(product);
      expect(wishlist.isFavorite(product.id), false);
      expect(wishlist.count, 0);
    });

    test('getWishlistItems filters products correctly', () {
      final wishlist = WishlistProvider();
      final p1 = MockData.allProducts[0];
      final p2 = MockData.allProducts[1];

      wishlist.addFavorite(p1);
      wishlist.addFavorite(p2);

      final items = wishlist.getWishlistItems(MockData.allProducts);
      expect(items.length, 2);
      expect(items.any((p) => p.id == p1.id), true);
      expect(items.any((p) => p.id == p2.id), true);
    });
  });

  group('ProductRepository Unit Tests', () {
    test('Fetches all featured products and flash deals', () async {
      final repo = ProductRepository();
      final featured = await repo.getFeaturedProducts();
      final deals = await repo.getFlashDeals();

      expect(featured.isNotEmpty, true);
      expect(deals.isNotEmpty, true);
    });

    test('Filters products by category accurately', () async {
      final repo = ProductRepository();
      final apparel = await repo.getProductsByCategory('Apparel');
      expect(apparel.every((p) => p.category.toLowerCase() == 'apparel'), true);
    });

    test('Searches products by keyword', () async {
      final repo = ProductRepository();
      final results = await repo.searchProducts('Silk');
      expect(results.any((p) => p.name.contains('Silk')), true);
    });
  });

  group('GoogleIcon Widget Test', () {
    testWidgets('GoogleIcon renders correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GoogleIcon(size: 24),
          ),
        ),
      );
      expect(find.byType(GoogleIcon), findsOneWidget);
    });
  });

  group('Lumora Direct Launch Flow (Splash -> Main Marketplace)', () {
    testWidgets('App opens SplashScreen, auto-glides to Main Marketplace with Floating Capsule Nav',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(const LumoraApp());

      // 1. Initial screen is SplashScreen
      expect(find.byType(SplashScreen), findsOneWidget);
      expect(find.text('Curating seasonal collections...'), findsOneWidget);

      // Advance timer to trigger direct transition to MainScreen
      await tester.pump(const Duration(milliseconds: 2200));
      await tester.pumpAndSettle();

      // 2. Directly on HomeScreen
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.byType(RichText), findsWidgets);

      // Check floating capsule nav tab labels (original 5 tabs)
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Categories'), findsOneWidget);
      expect(find.text('Deals'), findsOneWidget);
      expect(find.text('Bag'), findsOneWidget);
      expect(find.text('Account'), findsOneWidget);

      // Deals tab shows Flash Sale Hub
      await tester.tap(find.text('Deals'));
      await tester.pumpAndSettle();
      expect(find.text('Flash Sale Hub'), findsOneWidget);

      // Bag tab shows guest prompt
      await tester.tap(find.text('Bag'));
      await tester.pumpAndSettle();
      expect(find.text('Sign In to View Cart'), findsOneWidget);

      // Account tab shows Guest with Zalora VIP hierarchy
      await tester.tap(find.text('Account'));
      await tester.pumpAndSettle();
      expect(find.text('Hi Guest,'), findsOneWidget);
      expect(find.text('Guest'), findsOneWidget);
      expect(find.text('Log in to start buying & saving items'), findsOneWidget);
      expect(find.text('VIP'), findsOneWidget);
    });
  });

  group('ProductDetailScreen Widget Tests', () {
    testWidgets('Shows product details, multi-angle gallery, specifications, reviews, and opens purchase modal',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      final product = MockData.allProducts.first;

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AuthProvider()),
            ChangeNotifierProvider(create: (_) => CartProvider()),
            ChangeNotifierProvider(create: (_) => WishlistProvider()),
            ChangeNotifierProvider(create: (_) => OrderProvider()),
            ChangeNotifierProvider(create: (_) => FollowProvider()),
            ChangeNotifierProvider(create: (_) => WalletProvider()),
            ChangeNotifierProvider(create: (_) => ChatProvider()),
          ],
          child: MaterialApp(
            home: ProductDetailScreen(product: product),
          ),
        ),
      );

      // 1. Verify details, specs, guarantees, and reviews are present
      expect(find.text(product.name), findsOneWidget);
      expect(find.text('Product Details & Description'), findsOneWidget);
      expect(find.text('Specifications & Authenticity'), findsOneWidget);
      expect(find.text('Ratings & Reviews'), findsOneWidget);
      expect(find.text('Sophia M.'), findsOneWidget);

      // 2. Verify static quantity selector is NOT on the main page (only in modal)
      expect(find.text('Select quantity for order'), findsNothing);

      // 3. Guest tapping heart button triggers AuthModal
      await tester.tap(find.byIcon(Icons.favorite_border).first);
      await tester.pumpAndSettle();
      expect(find.text('Sign In Required'), findsOneWidget);

      // Close AuthModal
      await tester.tap(find.text('Continue Browsing as Guest'));
      await tester.pumpAndSettle();

      // 4. Tap Share icon in AppBar to open Zalora-Style LuxuryShareModal
      await tester.tap(find.byIcon(Icons.share_outlined));
      await tester.pumpAndSettle();
      expect(find.text('Share'), findsOneWidget);
      expect(find.text('Chats'), findsOneWidget);
      expect(find.text('Instagram'), findsOneWidget);
      expect(find.text('WhatsApp'), findsOneWidget);

      // Close Share modal
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      // 5. Tap Add to Cart to open purchase modal
      await tester.tap(find.text('Add to Cart'));
      await tester.pumpAndSettle();

      // Modal is now open
      expect(find.text('Select quantity for order'), findsOneWidget);
      expect(find.text('Total Amount:'), findsOneWidget);

      // Close modal
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();
    });
  });

  group('Guest & Auth Barrier Tests (Wishlist & Live Chat)', () {
    testWidgets('Guest tapping Header Wishlist & Live Chat triggers AuthModal', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      final auth = AuthProvider(); // Guest by default

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: auth),
            ChangeNotifierProvider(create: (_) => CartProvider()),
            ChangeNotifierProvider(create: (_) => WishlistProvider()),
            ChangeNotifierProvider(create: (_) => OrderProvider()),
            ChangeNotifierProvider(create: (_) => FollowProvider()),
            ChangeNotifierProvider(create: (_) => WalletProvider()),
            ChangeNotifierProvider(create: (_) => ChatProvider()),
          ],
          child: const MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Guest taps Header Wishlist -> AuthModal appears
      await tester.tap(find.byIcon(Icons.favorite_border_rounded));
      await tester.pumpAndSettle();
      expect(find.text('Sign In Required'), findsOneWidget);

      // Dismiss modal
      await tester.tap(find.text('Continue Browsing as Guest'));
      await tester.pumpAndSettle();

      // 2. Guest taps Header Live Chat -> AuthModal appears
      await tester.tap(find.byIcon(Icons.chat_bubble_outline_rounded).first);
      await tester.pumpAndSettle();
      expect(find.text('Sign In Required'), findsOneWidget);

      // Dismiss modal
      await tester.tap(find.text('Continue Browsing as Guest'));
      await tester.pumpAndSettle();
    });

    testWidgets('Authenticated User can access Wishlist modal and Live Chat Screen', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      final auth = AuthProvider();
      await auth.login('buyer@example.com', 'password123');

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: auth),
            ChangeNotifierProvider(create: (_) => CartProvider()),
            ChangeNotifierProvider(create: (_) => WishlistProvider()),
            ChangeNotifierProvider(create: (_) => OrderProvider()),
            ChangeNotifierProvider(create: (_) => FollowProvider()),
            ChangeNotifierProvider(create: (_) => WalletProvider()),
            ChangeNotifierProvider(create: (_) => ChatProvider()),
          ],
          child: const MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Authenticated user taps Header Live Chat -> opens ChatScreen
      await tester.tap(find.byIcon(Icons.chat_bubble_outline_rounded).first);
      await tester.pumpAndSettle();
      expect(find.text('Lumora Concierge & Support'), findsOneWidget);
      expect(find.text('Where is my order?'), findsOneWidget);
    });

    testWidgets('CartScreen renders product image and cleanly omits top title', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      final auth = AuthProvider();
      await auth.login('buyer@example.com', 'password123');

      final cart = CartProvider();
      cart.addToCart(MockData.allProducts.first);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: auth),
            ChangeNotifierProvider.value(value: cart),
            ChangeNotifierProvider(create: (_) => WishlistProvider()),
            ChangeNotifierProvider(create: (_) => OrderProvider()),
            ChangeNotifierProvider(create: (_) => FollowProvider()),
            ChangeNotifierProvider(create: (_) => WalletProvider()),
            ChangeNotifierProvider(create: (_) => ChatProvider()),
          ],
          child: const MaterialApp(
            home: CartScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Top title is cleanly removed
      expect(find.text('Shopping Cart'), findsNothing);

      // Product image is rendered
      expect(find.byType(Image), findsWidgets);
      expect(find.text(MockData.allProducts.first.name), findsOneWidget);
    });

    testWidgets('CartScreen displays luxury Bag elements matching Zalora style', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      final auth = AuthProvider();
      await auth.login('buyer@example.com', 'password123');

      final cart = CartProvider();
      cart.addToCart(MockData.allProducts[0], quantity: 1);
      cart.addToCart(MockData.allProducts[1], quantity: 1);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: auth),
            ChangeNotifierProvider.value(value: cart),
            ChangeNotifierProvider(create: (_) => WishlistProvider()),
            ChangeNotifierProvider(create: (_) => OrderProvider()),
            ChangeNotifierProvider(create: (_) => FollowProvider()),
            ChangeNotifierProvider(create: (_) => WalletProvider()),
            ChangeNotifierProvider(create: (_) => ChatProvider()),
          ],
          child: const MaterialApp(
            home: CartScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Top title is My Bag with 2 items ready for checkout
      expect(find.text('My Bag'), findsOneWidget);
      expect(find.text('2 items ready for checkout'), findsOneWidget);

      // Delivery Address card
      expect(find.text('Sitio, Ilaya, Pagsanjan, Laguna, 4008'), findsOneWidget);

      // VIP Unlimited Free Shipping banner
      expect(find.textContaining('Get Unlimited Free Shipping with'), findsOneWidget);
      expect(find.text('VIP'), findsOneWidget);

      // Store header
      expect(find.text(MockData.allProducts[0].sellerName), findsWidgets);

      // Assurance and voucher tags
      expect(find.text('30 Days Free Return | T&C Apply'), findsWidgets);
      expect(find.text('Enter voucher code or gift card'), findsOneWidget);

      // Bottom bar
      expect(find.text('All'), findsOneWidget);
      expect(find.text('Checkout (2)'), findsOneWidget);
    });
  });

  group('OrderProvider Unit Tests', () {
    Future<OrderProvider> getLoadedProvider() async {
      final p = OrderProvider();
      int retries = 0;
      while (!p.isLoaded && retries < 25) {
        await Future.delayed(const Duration(milliseconds: 10));
        retries++;
      }
      return p;
    }

    test('Initial orders start clean with zero fake seeded orders', () async {
      final orderProvider = await getLoadedProvider();
      expect(orderProvider.orders.isEmpty, true);
      expect(orderProvider.activeInTransitOrder, isNull);
    });

    test('Placing order adds new order and updates list', () async {
      final orderProvider = await getLoadedProvider();
      final initialCount = orderProvider.orders.length;
      final cartItem = CartItem(product: MockData.allProducts.first, quantity: 2);

      final newOrder = await orderProvider.placeOrder(
        cartItems: [cartItem],
        totalAmount: 2598.0,
        deliveryAddress: 'Two Serendra, BGC, Taguig City',
        recipientName: 'Maria Clara Santos',
        paymentMethod: 'Cash on Delivery (COD)',
      );

      expect(newOrder, isNotNull);
      expect(orderProvider.orders.length, initialCount + 1);
      expect(newOrder!.items.length, 1);
      expect(newOrder.items.first.quantity, 2);
      expect(newOrder.status, 'pending');
      expect(orderProvider.orders.first.id, newOrder.id);
    });

    test('Marking order as received updates status to Delivered', () async {
      final orderProvider = await getLoadedProvider();
      final cartItem = CartItem(product: MockData.allProducts.first, quantity: 1);
      final placed = await orderProvider.placeOrder(
        cartItems: [cartItem],
        totalAmount: 1299.0,
        deliveryAddress: 'San Antonio, Biñan, Laguna',
        recipientName: 'Buyer',
        paymentMethod: 'Cash on Delivery (COD)',
      );
      final orderId = placed!.id;
      await orderProvider.markAsReceived(orderId);
      final updated = orderProvider.getOrderById(orderId);
      expect(updated?.normalizedWebStatus, 'delivered');
      expect(updated?.progress, 1.0);
    });

    test('Cancelling order updates status to Cancelled', () async {
      final orderProvider = await getLoadedProvider();
      final cartItem = CartItem(product: MockData.allProducts.first, quantity: 1);
      final placed = await orderProvider.placeOrder(
        cartItems: [cartItem],
        totalAmount: 1299.0,
        deliveryAddress: 'San Antonio, Biñan, Laguna',
        recipientName: 'Buyer',
        paymentMethod: 'Cash on Delivery (COD)',
      );
      final orderId = placed!.id;
      await orderProvider.cancelOrder(orderId);
      final updated = orderProvider.getOrderById(orderId);
      expect(updated?.normalizedWebStatus, 'cancelled');
    });
  });

  group('LiveMapTracker & Order Tracking Modal Widget Tests', () {
    testWidgets('LiveMapTracker renders natural gesture zoom InteractiveViewer and moving truck', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      final sampleOrder = OrderModel(
        id: 'LUM-TEST-1',
        trackingNumber: 'PH-LMR-TEST-1',
        createdAt: DateTime.now(),
        status: 'To Receive',
        totalAmount: 1200.0,
        deliveryAddress: 'Two Serendra, BGC',
        recipientName: 'Maria Clara',
        paymentMethod: 'COD',
        items: [],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LiveMapTracker(order: sampleOrder),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));

      // InteractiveViewer is present for natural pinch-to-zoom & pan gestures
      expect(find.byType(InteractiveViewer), findsOneWidget);
      // Origin and destination location pins exist
      expect(find.text('LUMORA HUB'), findsOneWidget);
      expect(find.text('DELIVERY DESTINATION'), findsOneWidget);
      // Moving delivery truck icon exists
      expect(find.byIcon(Icons.local_shipping), findsOneWidget);
      // Natural pinch hint is shown
      expect(find.text('Pinch to zoom map'), findsOneWidget);
    });

    testWidgets('OrderTrackingModal shows live map and driver contact options', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      final auth = AuthProvider();
      await auth.login('buyer@example.com', 'password123');

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: auth),
            ChangeNotifierProvider(create: (_) => CartProvider()),
            ChangeNotifierProvider(create: (_) => WishlistProvider()),
            ChangeNotifierProvider(create: (_) => OrderProvider()),
          ],
          child: MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () => OrderTrackingModal.show(
                      context,
                      status: 'out_for_delivery',
                    ),
                    child: const Text('Open Tracker'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap to open OrderTrackingModal
      await tester.tap(find.text('Open Tracker'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Live Order Tracking'), findsOneWidget);
      expect(find.text('LIVE GPS'), findsOneWidget);
      expect(find.text('Call Driver'), findsOneWidget);
      expect(find.text('Message'), findsOneWidget);
      expect(find.text('Delivery Timeline'), findsOneWidget);
    });
  });

  group('Shopee-Style Voucher System Tests', () {
    test('VoucherModel eligibility and discount calculation', () {
      final freeship = VoucherModel.sampleVouchers.firstWhere((v) => v.code == 'FREESHIP');
      expect(freeship.isEligible(500), false);
      expect(freeship.calculateDiscount(500, 50), 0.0);
      expect(freeship.isEligible(1200), true);
      expect(freeship.calculateDiscount(1200, 50), 50.0);
      expect(freeship.calculateDiscount(1200, 30), 30.0);

      final beauty = VoucherModel.sampleVouchers.firstWhere((v) => v.code == 'BEAUTY10');
      expect(beauty.isEligible(500), false);
      expect(beauty.isEligible(1000), true);
      expect(beauty.calculateDiscount(1000, 50), 100.0); // 10% of 1000
      expect(beauty.calculateDiscount(4000, 50), 250.0); // capped at 250

      final lumora50 = VoucherModel.sampleVouchers.firstWhere((v) => v.code == 'LUMORA50');
      expect(lumora50.isEligible(200), false);
      expect(lumora50.isEligible(600), true);
      expect(lumora50.calculateDiscount(600, 50), 50.0);
    });

    test('VoucherSelectionResult correctly calculates stacked savings', () {
      final freeship = VoucherModel.sampleVouchers.firstWhere((v) => v.code == 'FREESHIP');
      final lumora50 = VoucherModel.sampleVouchers.firstWhere((v) => v.code == 'LUMORA50');

      final result = VoucherSelectionResult(
        shippingVoucher: freeship,
        discountVoucher: lumora50,
      );

      // Subtotal 1500, shipping 50: freeship saves 50, lumora50 saves 50 -> total 100
      expect(result.totalDiscount(1500, 50), 100.0);
    });

    testWidgets('Shopee Voucher Selection Modal opens and selects stackable vouchers', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      VoucherSelectionResult? modalResult;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () async {
                    modalResult = await VoucherSelectionModal.show(
                      context,
                      subtotal: 1500.0,
                      shippingFee: 50.0,
                    );
                  },
                  child: const Text('Select Vouchers'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open modal
      await tester.tap(find.text('Select Vouchers'));
      await tester.pumpAndSettle();

      // Check modal components
      expect(find.text('Select Lumora Voucher'), findsOneWidget);
      expect(find.text('Free Shipping Voucher'), findsOneWidget);
      expect(find.text('Platform Discount & Cashback'), findsOneWidget);

      // Tap on FREESHIP card
      expect(find.text('FREESHIP'), findsOneWidget);
      await tester.tap(find.text('FREESHIP'));
      await tester.pumpAndSettle();

      // Tap on LUMORA50 card
      expect(find.text('LUMORA50'), findsOneWidget);
      await tester.tap(find.text('LUMORA50'));
      await tester.pumpAndSettle();

      // Verify bottom summary shows 2 selected vouchers
      expect(find.textContaining('2 Vouchers Selected'), findsOneWidget);

      // Confirm selection
      await tester.tap(find.text('Apply Vouchers'));
      await tester.pumpAndSettle();

      expect(modalResult, isNotNull);
      expect(modalResult?.shippingVoucher?.code, 'FREESHIP');
      expect(modalResult?.discountVoucher?.code, 'LUMORA50');
    });

    testWidgets('CheckoutScreen displays Lumora Vouchers card and stackable voucher savings', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      final auth = AuthProvider();
      await auth.login('buyer@example.com', 'password123');

      final cart = CartProvider();
      cart.addToCart(MockData.allProducts.firstWhere((p) => p.price >= 1000));

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: auth),
            ChangeNotifierProvider.value(value: cart),
            ChangeNotifierProvider(create: (_) => WishlistProvider()),
            ChangeNotifierProvider(create: (_) => OrderProvider()),
            ChangeNotifierProvider(create: (_) => FollowProvider()),
            ChangeNotifierProvider(create: (_) => WalletProvider()),
            ChangeNotifierProvider(create: (_) => ChatProvider()),
          ],
          child: const MaterialApp(
            home: CheckoutScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Voucher card exists
      expect(find.text('Lumora Vouchers'), findsOneWidget);
      expect(find.text('STACKABLE'), findsOneWidget);
      expect(find.text('Select code'), findsOneWidget);

      // Tap voucher card to open modal
      await tester.ensureVisible(find.text('Lumora Vouchers'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Lumora Vouchers'));
      await tester.pumpAndSettle();

      // Modal is visible
      expect(find.text('Select Lumora Voucher'), findsOneWidget);

      // Select FREESHIP
      await tester.tap(find.text('FREESHIP'));
      await tester.pumpAndSettle();

      // Apply
      await tester.tap(find.text('Apply Vouchers'));
      await tester.pumpAndSettle();

      // Should now show applied badge on Checkout Screen
      expect(find.textContaining('Free Shipping: -₱50'), findsOneWidget);
      expect(find.text('Change'), findsOneWidget);
      expect(find.text('Clear'), findsOneWidget);
    });
  });
}

