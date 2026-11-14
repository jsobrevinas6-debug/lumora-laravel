import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/chat_provider.dart';
import 'providers/follow_provider.dart';
import 'providers/order_provider.dart';
import 'providers/wallet_provider.dart';
import 'providers/wishlist_provider.dart';
import 'data/mock_data.dart';
import 'screens/splash_screen.dart';
import 'services/api_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiConfig.loadConfig();
  unawaited(MockData.syncFromApi());
  runApp(const LumoraApp());
}

class LumoraApp extends StatelessWidget {
  const LumoraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProxyProvider<AuthProvider, CartProvider>(
          create: (_) => CartProvider(),
          update: (_, auth, cart) {
            final c = cart ?? CartProvider();
            c.syncWithAuth(auth.currentUser?.email);
            return c;
          },
        ),
        ChangeNotifierProxyProvider<AuthProvider, WishlistProvider>(
          create: (_) => WishlistProvider(),
          update: (_, auth, wishlist) {
            final w = wishlist ?? WishlistProvider();
            w.syncWithAuth(auth.currentUser?.email);
            return w;
          },
        ),
        ChangeNotifierProxyProvider<AuthProvider, OrderProvider>(
          create: (_) => OrderProvider(),
          update: (_, auth, order) {
            final o = order ?? OrderProvider();
            o.syncWithAuth(auth.currentUser?.email);
            return o;
          },
        ),
        ChangeNotifierProxyProvider<AuthProvider, FollowProvider>(
          create: (_) => FollowProvider(),
          update: (_, auth, follow) {
            final f = follow ?? FollowProvider();
            f.syncWithAuth(auth.currentUser?.email);
            return f;
          },
        ),
        ChangeNotifierProvider(create: (_) => WalletProvider()),
        ChangeNotifierProxyProvider<AuthProvider, ChatProvider>(
          create: (_) => ChatProvider(),
          update: (_, auth, chat) {
            final ch = chat ?? ChatProvider();
            ch.syncWithAuth(auth.currentUser?.email);
            return ch;
          },
        ),
      ],
      child: MaterialApp(
        title: 'Lumora Marketplace',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const SplashScreen(),
      ),
    );
  }
}
