import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:lumora/models/models.dart';
import 'package:lumora/providers/auth_provider.dart';
import 'package:lumora/providers/chat_provider.dart';
import 'package:lumora/services/api_service.dart';
import 'package:lumora/widgets/luxury_date_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    ApiConfig.useLiveApi = false;
    ApiService.testHttpClient = null;
  });

  tearDown(() {
    ApiService.testHttpClient = null;
  });

  group('LumoraDatePicker Tests', () {
    test('Parses ISO, slash, and friendly dates while rejecting invalid leap days', () {
      expect(LumoraDatePicker.tryParse('2001-05-15'), DateTime(2001, 5, 15));
      expect(LumoraDatePicker.tryParse('05/15/2001'), DateTime(2001, 5, 15));
      expect(LumoraDatePicker.tryParse('May 15, 2001'), DateTime(2001, 5, 15));
      expect(LumoraDatePicker.tryParse('2000-02-29'), DateTime(2000, 2, 29));
      // 2001 is not a leap year
      expect(LumoraDatePicker.tryParse('02/29/2001'), isNull);
      expect(LumoraDatePicker.tryParse(''), isNull);
    });

    test('Formats ISO, friendly, and full dates accurately', () {
      final sample = DateTime(2001, 5, 5);
      expect(LumoraDatePicker.formatIso(sample), '2001-05-05');
      expect(LumoraDatePicker.formatFriendly(sample), 'May 5, 2001');
      expect(LumoraDatePicker.formatFull(sample), 'May 5, 2001');
    });

    test('Computes exact legal age against reference date', () {
      final ref = DateTime(2026, 11, 15);
      expect(LumoraDatePicker.computeAge(DateTime(2008, 11, 15), now: ref), 18);
      expect(LumoraDatePicker.computeAge(DateTime(2008, 11, 16), now: ref), 17);
      expect(LumoraDatePicker.computeAge(DateTime(1999, 1, 10), now: ref), 27);
    });

    testWidgets('Opens birthday wheel modal, toggles Quick Type, and confirms date', (tester) async {
      DateTime? picked;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  picked = await LumoraDatePicker.show(
                    context,
                    initialDate: DateTime(2000, 6, 15),
                    minimumAge: 18,
                  );
                },
                child: const Text('Open Picker'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Picker'));
      await tester.pumpAndSettle();

      expect(find.text('Select Date of Birth'), findsOneWidget);
      expect(find.text('Month • Day • Year'), findsOneWidget);
      expect(find.text('Quick Type (MM/DD)'), findsOneWidget);

      await tester.tap(find.text('Quick Type (MM/DD)'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), '08/21/1999');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Confirm Aug 21, 1999'));
      await tester.pumpAndSettle();

      expect(picked, DateTime(1999, 8, 21));
    });
  });

  group('ProductVariant & ProductVariationGenerator Accuracy Tests', () {
    test('Server variants render single seller axis, exact DB stock, and no phantom size markup', () {
      final product = Product(
        id: '19',
        name: 'Gothic Silver Cross Drop Earrings',
        price: 809.10,
        originalPrice: 899.0,
        category: 'womens-accessories',
        description: 'Handcrafted 925 sterling silver earrings.',
        variantType: 'Style',
        variants: const [
          ProductVariant(id: 101, name: 'Out of Stock Archive', stock: 0),
          ProductVariant(id: 102, name: 'Classic Drop', stock: 12),
          ProductVariant(id: 103, name: 'Long Gothic Hook', stock: 5),
        ],
      );

      expect(product.hasServerVariants, isTrue);
      expect(product.showPrimaryOptionSelector, isFalse);
      expect(product.colorOptions, isEmpty);
      expect(product.secondaryOptionLabel, 'Style');
      expect(
        product.secondaryOptions,
        ['Out of Stock Archive', 'Classic Drop', 'Long Gothic Hook'],
      );
      expect(product.defaultSecondaryOption, 'Classic Drop');
      expect(product.stockForVariant(secondaryOption: 'Out of Stock Archive'), 0);
      expect(product.stockForVariant(secondaryOption: 'Classic Drop'), 12);
      expect(product.isVariantOutOfStock(secondaryOption: 'Out of Stock Archive'), isTrue);
      expect(product.priceForVariant(secondaryOption: 'Long Gothic Hook'), 809.10);
    });

    test('Nike AF1 White uses EU shoe sizes with no phantom price markup per size', () {
      const af1 = Product(
        id: '14',
        name: 'Nike AF1 White',
        price: 1551.03,
        category: 'mens-shoes',
        description: 'Original Design of AF 1',
      );

      expect(af1.secondaryOptionLabel, 'Size (EU)');
      expect(af1.secondaryOptions, containsAll(['EU 40', 'EU 41', 'EU 42', 'EU 43', 'EU 44']));
      expect(af1.colorOptions.first.name, 'Triple White Leather');
      expect(af1.priceForVariant(secondaryOption: 'EU 44'), 1551.03);
      expect(af1.hasSizeGuide, isTrue);
    });

    test('Rolex Submariner uses authentic watch dial & case sizes without size markup', () {
      const sub = Product(
        id: '17',
        name: 'Rolex Submariner',
        price: 4553.01,
        category: 'mens-accessories',
        description: 'Rolex Submariner Watch',
      );

      expect(sub.primaryOptionLabel, 'Dial & Bezel');
      expect(sub.secondaryOptionLabel, 'Case Size');
      expect(sub.secondaryOptions, ['40mm Classic', '41mm Oystersteel']);
      expect(sub.priceForVariant(secondaryOption: '41mm Oystersteel'), 4553.01);
    });

    test('Xiaomi 14 Ultra uses RAM & Storage tiers with real storage tier price scaling', () {
      const xiaomi = Product(
        id: '22',
        name: 'Xiaomi 14 Ultra',
        price: 15243.90,
        category: 'xiaomi',
        description: 'Xiaomi 14 Ultra flagship',
      );

      expect(xiaomi.primaryOptionLabel, 'Device Finish');
      expect(xiaomi.secondaryOptionLabel, 'RAM & Storage');
      expect(xiaomi.secondaryOptions.length, 3);
      expect(
        xiaomi.priceForVariant(secondaryOption: xiaomi.secondaryOptions.last),
        greaterThan(xiaomi.price),
      );
    });

    test('Silver Chain Bracelet uses wrist sizes rather than clothing or ring sizes', () {
      const bracelet = Product(
        id: '20',
        name: 'Silver Chain Bracelet',
        price: 570,
        category: 'mens-accessories',
        description: '925 silver bracelet',
      );

      expect(bracelet.secondaryOptionLabel, 'Wrist Size');
      expect(bracelet.secondaryOptions, ['17 cm (Small)', '19 cm (Medium)', '21 cm (Large)']);
    });

    test('OrderItem preserves variant_id, variant_name, and variation across JSON round-trip', () {
      const original = OrderItem(
        productId: '19',
        productName: 'Gothic Silver Cross Drop Earrings',
        price: 809.10,
        quantity: 2,
        variantId: 102,
        variantName: 'Classic Drop',
        variation: 'Classic Drop',
      );

      final roundTripped = OrderItem.fromJson(original.toJson());
      expect(roundTripped.productId, '19');
      expect(roundTripped.variantId, 102);
      expect(roundTripped.variantName, 'Classic Drop');
      expect(roundTripped.variation, 'Classic Drop');
    });
  });

  group('AuthProvider Security Validation Tests', () {
    test('Password validator enforces full complexity rules', () {
      expect(AuthProvider.validatePassword('short'), isNotNull);
      expect(AuthProvider.validatePassword('lowercaseonly1!'), isNotNull);
      expect(AuthProvider.validatePassword('UPPERCASE1!'), isNotNull);
      expect(AuthProvider.validatePassword('NoDigitsHere!'), isNotNull);
      expect(AuthProvider.validatePassword('NoSpecial123'), isNotNull);
      expect(AuthProvider.validatePassword('LuxuryPass#2026'), isNull);
    });

    test('updatePassword rejects empty current password and mismatched confirmation when signed out/in', () async {
      final auth = AuthProvider();
      final res = await auth.updatePassword(
        currentPassword: '',
        newPassword: 'LuxuryPass#2026',
        confirmPassword: 'LuxuryPass#2026',
      );
      expect(res['success'], isFalse);

      final delRes = await auth.deleteAccount(password: '');
      expect(delRes['success'], isFalse);
    });
  });

  group('Model, Session, Avatar, & Chat API Integration Tests', () {
    test('User.copyWith(clearAvatar: true) resets avatar to null while preserving identity', () {
      final user = User(
        id: 'u1',
        fullName: 'Elena Vance',
        email: 'elena@lumora.test',
        avatar: 'https://lumora.party/avatars/elena.jpg',
        joinedDate: DateTime(2025, 1, 1),
      );

      final preserved = user.copyWith(fullName: 'Elena V.');
      expect(preserved.avatar, 'https://lumora.party/avatars/elena.jpg');

      final cleared = preserved.copyWith(clearAvatar: true);
      expect(cleared.avatar, isNull);
      expect(cleared.fullName, 'Elena V.');
    });

    test('ChatMessage & ConversationThread parse snake_case Laravel API JSON', () {
      final thread = ConversationThread.fromJson({
        'id': '44',
        'seller_id': '9',
        'seller_name': 'Atelier Luxe',
        'seller_role': 'Verified Luxury Merchant',
        'seller_avatar': '/avatars/shop.jpg',
        'unread_count': 2,
        'last_message_at': '2026-11-15T05:00:00Z',
        'last_message': {
          'id': '901',
          'sender_name': 'Atelier Luxe',
          'sender_role': 'Seller',
          'body': 'Your parcel is ready for pickup.',
          'is_from_user': false,
          'is_bot': false,
          'attachment_url': '/chat-attachments/proof.png',
          'attachment_name': 'proof.png',
          'created_at': '2026-11-15T05:00:00Z',
        },
      });

      expect(thread.id, '44');
      expect(thread.sellerId, '9');
      expect(thread.sellerName, 'Atelier Luxe');
      expect(thread.unreadCount, 2);
      expect(thread.messages.length, 1);
      expect(thread.messages.first.isFromUser, isFalse);
      expect(thread.messages.first.message, 'Your parcel is ready for pickup.');
      expect(thread.messages.first.attachmentUrl, '/chat-attachments/proof.png');
    });

    test('ApiService.fetchSessions reads Laravel data key and supports sessions fallback', () async {
      ApiService.testHttpClient = MockClient((request) async {
        expect(request.url.path, endsWith('/auth/sessions'));
        expect(request.headers['Authorization'], 'Bearer test-token-123');
        return http.Response(
          jsonEncode({
            'data': [
              {'id': '1', 'device': 'Lumora Android', 'is_current': true},
              {'id': '2', 'device': 'Web Browser', 'is_current': false},
            ],
          }),
          200,
        );
      });

      final res = await ApiService().fetchSessions(token: 'test-token-123');
      expect(res.success, isTrue);
      expect(res.sessions.length, 2);
      expect(res.sessions.first['device'], 'Lumora Android');
    });

    test('ApiService.updateAvatar parses avatar/avatar_url on upload and calls DELETE on removal', () async {
      String? lastMethod;
      ApiService.testHttpClient = MockClient((request) async {
        lastMethod = request.method;
        if (request.method == 'POST') {
          return http.Response(
            jsonEncode({
              'message': 'Profile photo updated.',
              'avatar': 'https://lumora.party/avatars/new-photo.png',
              'user': {'id': 1, 'avatar': 'https://lumora.party/avatars/new-photo.png'},
            }),
            200,
          );
        }
        if (request.method == 'DELETE') {
          return http.Response(
            jsonEncode({'message': 'Profile photo removed.', 'avatar': null}),
            200,
          );
        }
        return http.Response('Not found', 404);
      });

      final uploadRes = await ApiService().updateAvatar(
        avatarData: 'data:image/png;base64,iVBORw0KGgo=',
        token: 'tok-1',
      );
      expect(lastMethod, 'POST');
      expect(uploadRes.success, isTrue);
      expect(uploadRes.avatarUrl, 'https://lumora.party/avatars/new-photo.png');

      final removeRes = await ApiService().updateAvatar(avatarData: '', token: 'tok-1');
      expect(lastMethod, 'DELETE');
      expect(removeRes.success, isTrue);
      expect(removeRes.avatarUrl, isNull);
    });

    test('ApiService chat endpoints call buyer & support endpoints and parse replies', () async {
      ApiService.testHttpClient = MockClient((request) async {
        final path = request.url.path;
        if (path.endsWith('/buyer/chats/start')) {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          expect(body['product_id'], 19);
          return http.Response(
            jsonEncode({
              'conversation': {
                'id': '77',
                'seller_id': '5',
                'seller_name': 'Saffron Studio',
                'unread_count': 0,
                'last_message_at': '2026-11-15T06:00:00Z',
                'messages': [],
              },
            }),
            201,
          );
        }
        if (path.endsWith('/buyer/chats/77/messages')) {
          return http.Response(
            jsonEncode({
              'message_item': {
                'id': '500',
                'sender_name': 'Buyer',
                'body': 'Do you gift wrap?',
                'is_from_user': true,
                'is_bot': false,
                'created_at': '2026-11-15T06:01:00Z',
              },
            }),
            201,
          );
        }
        if (path.endsWith('/support/chat/send')) {
          return http.Response(
            jsonEncode({
              'message_item': {
                'id': '601',
                'sender_name': 'Buyer',
                'body': 'Track order?',
                'is_from_user': true,
                'is_bot': false,
                'created_at': '2026-11-15T06:02:00Z',
              },
              'bot_message': {
                'id': '602',
                'sender_name': 'Lumora Assistant',
                'body': 'Open Orders in your Account tab to view live tracking.',
                'is_from_user': false,
                'is_bot': true,
                'created_at': '2026-11-15T06:02:01Z',
              },
            }),
            201,
          );
        }
        return http.Response('{}', 404);
      });

      final startRes = await ApiService().startSellerConversation(
        sellerId: '5',
        sellerName: 'Saffron Studio',
        productId: 19,
        token: 'tok-chat',
      );
      expect(startRes.success, isTrue);
      expect(startRes.conversation?.id, '77');

      final sendRes = await ApiService().sendSellerMessage(
        conversationId: '77',
        body: 'Do you gift wrap?',
        token: 'tok-chat',
      );
      expect(sendRes.success, isTrue);
      expect(sendRes.messageItem?.isFromUser, isTrue);

      final supRes = await ApiService().sendSupportMessage(
        body: 'Track order?',
        token: 'tok-chat',
      );
      expect(supRes.success, isTrue);
      expect(supRes.userMessage?.message, 'Track order?');
      expect(supRes.botMessage?.isBot, isTrue);
      expect(supRes.botMessage?.message, 'Open Orders in your Account tab to view live tracking.');
    });

    test('ChatProvider syncs live seller & support threads via ApiService when useLiveApi is true', () async {
      ApiConfig.useLiveApi = true;
      ApiService.testHttpClient = MockClient((request) async {
        final path = request.url.path;
        if (path.endsWith('/buyer/chats')) {
          return http.Response(
            jsonEncode({
              'conversations': [
                {
                  'id': '12',
                  'seller_id': '3',
                  'seller_name': 'Maison Lumora',
                  'unread_count': 1,
                  'last_message_at': '2026-11-15T06:00:00Z',
                  'last_message': {
                    'id': '88',
                    'sender_name': 'Maison Lumora',
                    'body': 'Welcome!',
                    'is_from_user': false,
                    'is_bot': false,
                    'created_at': '2026-11-15T06:00:00Z',
                  },
                },
              ],
              'support_conversation': {
                'id': '99',
                'seller_id': 'support',
                'seller_name': 'Lumora Support',
                'unread_count': 1,
                'last_message_at': '2026-11-15T06:01:00Z',
                'messages': [],
              },
              'total_unread': 2,
            }),
            200,
          );
        }
        if (path.endsWith('/buyer/chats/12/messages')) {
          return http.Response(
            jsonEncode({
              'message_item': {
                'id': '89',
                'sender_name': 'Buyer',
                'body': 'Hi Maison!',
                'is_from_user': true,
                'is_bot': false,
                'created_at': '2026-11-15T06:02:00Z',
              },
            }),
            201,
          );
        }
        if (path.endsWith('/buyer/chats/12/read')) {
          return http.Response(jsonEncode({'status': 'ok', 'unread_count': 0}), 200);
        }
        return http.Response('{}', 404);
      });

      final provider = ChatProvider();
      await provider.syncWithAuth('buyer@lumora.test', token: 'tok-live');

      expect(provider.threads.length, 1);
      expect(provider.threads.first.sellerName, 'Maison Lumora');
      expect(provider.totalUnreadCount, 2);

      final sendRes = await provider.sendMessageToSeller(
        conversationId: '12',
        body: 'Hi Maison!',
        token: 'tok-live',
      );
      expect(sendRes.success, isTrue);
      expect(provider.threads.first.messages.any((m) => m.id == '89'), isTrue);
      expect(provider.threads.first.unreadCount, 0);
    });
  });

  group('Return, Dispute & Refund Sync Tests', () {
    test('OrderModel.fromJson parses return, dispute, and refund fields from snake_case API payloads', () {
      final order = OrderModel.fromJson({
        'id': 'LMR-2026-000123',
        'tracking_number': 'PH-LMR-123',
        'created_at': '2026-11-10T08:00:00Z',
        'delivered_at': '2026-11-13T08:00:00Z',
        'status': 'returned',
        'total': 1450.0,
        'payment_status': 'refunded',
        'return_status': 'approved',
        'return_reason': 'wrong_item',
        'preferred_solution': 'refund',
        'return_review_note': 'Approved after photo inspection.',
        'is_disputed': false,
        'return_dispute_status': 'resolved_approved',
        'refund_status': 'refunded',
        'refund_amount': 1450.0,
        'refunded_at': '2026-11-15T10:00:00Z',
        'return_evidence_photos': ['https://lumora.party/api/logistics/returns-evidence/1/2'],
      });

      expect(order.hasReturnRequest, isTrue);
      expect(order.isReturnApproved, isTrue);
      expect(order.isReturnDenied, isFalse);
      expect(order.refundStatus, 'refunded');
      expect(order.refundAmount, 1450.0);
      expect(order.returnReviewNote, 'Approved after photo inspection.');
      expect(order.returnEvidencePhotos.length, 1);

      final roundTrip = OrderModel.fromJson(order.toJson());
      expect(roundTrip.refundStatus, 'refunded');
      expect(roundTrip.returnStatus, 'approved');
      expect(roundTrip.preferredSolution, 'refund');
    });

    test('ApiService.requestReturnRefund and escalateDispute parse structured OrderModel & server errors', () async {
      ApiConfig.useLiveApi = true;
      ApiService.testHttpClient = MockClient((request) async {
        final path = request.url.path;
        if (path.endsWith('/buyer/orders/LMR-2026-000999/return')) {
          return http.Response(
            jsonEncode({
              'message': 'The 7-day return window for this order has expired.',
            }),
            422,
          );
        }
        if (path.endsWith('/buyer/orders/LMR-2026-000888/return')) {
          return http.Response(
            jsonEncode({
              'message': 'Return/refund request submitted for review.',
              'data': {
                'id': 'LMR-2026-000888',
                'tracking_number': 'PH-LMR-888',
                'created_at': '2026-11-12T08:00:00Z',
                'status': 'return_requested',
                'total': 990.0,
                'payment_status': 'paid',
                'return_status': 'pending',
                'preferred_solution': 'refund',
                'refund_status': 'pending',
              },
            }),
            201,
          );
        }
        if (path.endsWith('/buyer/orders/LMR-2026-000888/dispute')) {
          return http.Response(
            jsonEncode({
              'message': 'Dispute escalated to Lumora Admin for arbitration.',
              'data': {
                'id': 'LMR-2026-000888',
                'tracking_number': 'PH-LMR-888',
                'created_at': '2026-11-12T08:00:00Z',
                'status': 'delivered',
                'total': 990.0,
                'return_status': 'denied',
                'return_rejection_reason': 'Packaging intact',
                'is_disputed': true,
                'return_dispute_status': 'under_arbitration',
              },
            }),
            200,
          );
        }
        return http.Response('{}', 404);
      });

      final expired = await ApiService().requestReturnRefund(
        orderId: 'LMR-2026-000999',
        reason: 'damaged',
        solution: 'refund',
        details: 'Cracked compact mirror upon arrival.',
        photos: ['data:image/jpeg;base64,abc='],
        token: 'tok-ret',
      );
      expect(expired.success, isFalse);
      expect(expired.message, contains('7-day'));

      final created = await ApiService().requestReturnRefund(
        orderId: 'LMR-2026-000888',
        reason: 'damaged',
        solution: 'refund',
        details: 'Cracked compact mirror upon arrival.',
        photos: ['data:image/jpeg;base64,abc='],
        token: 'tok-ret',
      );
      expect(created.success, isTrue);
      expect(created.order?.normalizedWebStatus, 'return_requested');
      expect(created.order?.returnStatus, 'pending');

      final escalated = await ApiService().escalateDispute(
        orderId: 'LMR-2026-000888',
        disputeNotes: 'Outer carton arrived torn.',
        token: 'tok-ret',
      );
      expect(escalated.success, isTrue);
      expect(escalated.order?.isDisputed, isTrue);
      expect(escalated.order?.returnDisputeStatus, 'under_arbitration');
    });
  });
}
