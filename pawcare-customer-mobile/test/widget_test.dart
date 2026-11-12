import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pawcare_customer_mobile/app/pawcare_app.dart';
import 'package:pawcare_customer_mobile/core/network/pawcare_api.dart';
import 'package:pawcare_customer_mobile/core/storage/session_store.dart';
import 'package:pawcare_customer_mobile/core/theme/app_theme.dart';
import 'package:pawcare_customer_mobile/features/auth/presentation/auth_screen.dart';
import 'package:pawcare_customer_mobile/features/booking/presentation/booking_screen.dart';
import 'package:pawcare_customer_mobile/features/activity/presentation/activity_screen.dart';
import 'package:pawcare_customer_mobile/features/home/presentation/home_screen.dart';
import 'package:pawcare_customer_mobile/features/profile/presentation/profile_screen.dart';
import 'package:pawcare_customer_mobile/features/notifications/presentation/notifications_screen.dart';

void main() {
  test('persists dark mode and customer session', () async {
    SharedPreferences.setMockInitialValues({});
    final store = SessionStore();
    await store.saveDarkMode(true);
    await store.saveSession(
        const AuthSession(
            accessToken: 'access',
            refreshToken: 'refresh',
            profile: {'fullName': 'An'}),
        'https://api.pawcare.test/api/v1');
    expect(await store.readDarkMode(), isTrue);
    expect((await store.readSession())?.profile['fullName'], 'An');
    expect(await store.readApiUrl(), 'https://api.pawcare.test/api/v1');
  });

  testWidgets('shows PawCare sign in screen', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
        PawCareApp(api: PawCareApi(baseUrl: 'http://pawcare.test')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Đăng nhập'), findsOneWidget);
  });

  testWidgets('profile renders the authenticated name and email',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: buildTheme(),
      home: ProfileScreen(
        profile: const {'fullName': 'Nguyễn Hải An', 'email': 'an@example.com'},
        api: PawCareApi(),
        darkMode: false,
        onThemeChanged: (_) {},
        onProfileUpdated: (_) {},
        onLogout: () {},
      ),
    ));

    expect(find.text('Nguyễn Hải An'), findsOneWidget);
    expect(find.text('an@example.com'), findsOneWidget);
    expect(find.text('Minh Anh'), findsNothing);
  });

  testWidgets('keeps every character typed in the login email field',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: buildTheme(),
      home: AuthScreen(onAuthenticated: (_, __) async {}),
    ));

    final emailField = find.byKey(const ValueKey('auth-email'));
    await tester.tap(emailField);
    tester.testTextInput.enterText('k');
    await tester.pump();
    tester.testTextInput.enterText('kien@pawcare.vn');
    await tester.pump();

    expect(find.text('kien@pawcare.vn'), findsOneWidget);
  });

  testWidgets('booking renders its form after services and pets load',
      (tester) async {
    final api = PawCareApi(
        baseUrl: 'http://pawcare.test/api/v1',
        client: MockClient((request) async {
          if (request.url.path.endsWith('/services')) {
            return _jsonResponse([
              {
                'id': 10,
                'name': 'Tắm & vệ sinh',
                'duration_minutes': 45,
                'price': 120000
              }
            ]);
          }
          if (request.url.path.endsWith('/pets')) {
            return _jsonResponse([
              {'id': 11, 'name': 'Bé Mây', 'species': 'Chó', 'breed': 'Poodle'}
            ]);
          }
          return _jsonResponse({'error': 'Not found'}, 404);
        }));
    addTearDown(api.close);

    await tester.pumpWidget(MaterialApp(
      theme: buildTheme(),
      home: BookingScreen(api: api, providerId: 1, providerName: 'Happy Pet'),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Chọn dịch vụ'), findsOneWidget);
    expect(find.text('Tắm & vệ sinh'), findsOneWidget);
    expect(find.text('Bé Mây'), findsOneWidget);
  });

  testWidgets('SERVICE_DONE booking exposes confirm and dispute',
      (tester) async {
    var confirmed = false;
    final api = PawCareApi(
        baseUrl: 'http://pawcare.test/api/v1',
        client: MockClient((request) async {
          if (request.url.path.endsWith('/bookings'))
            return _jsonResponse([
              {
                'id': 7,
                'status': 'SERVICE_DONE',
                'booking_start': '2026-11-10T09:00:00',
                'service_name': 'Tắm bé',
                'provider_name': 'Paw Spa',
                'estimated_price': 100000
              }
            ]);
          if (request.url.path.endsWith('/reviews') ||
              request.url.path.endsWith('/complaints'))
            return _jsonResponse([]);
          if (request.method == 'POST' &&
              request.url.path.endsWith('/confirm-completion')) {
            confirmed = true;
            return _jsonResponse({'success': true});
          }
          return _jsonResponse({'error': 'Not found'}, 404);
        }));
    addTearDown(api.close);
    await tester.pumpWidget(MaterialApp(
        theme: buildTheme(), home: Scaffold(body: ActivityScreen(api: api))));
    await tester.pumpAndSettle();
    expect(find.text('Xác nhận hoàn tất'), findsOneWidget);
    expect(find.text('Có vấn đề / Khiếu nại'), findsOneWidget);
    await tester.tap(find.text('Xác nhận hoàn tất'));
    await tester.pumpAndSettle();
    expect(confirmed, isTrue);
  });

  testWidgets('marks notifications read through the real API route',
      (tester) async {
    var readAll = false;
    final api = PawCareApi(
        baseUrl: 'http://pawcare.test/api/v1',
        client: MockClient((request) async {
          if (request.url.path.endsWith('/notifications') &&
              request.method == 'GET') {
            return _jsonResponse([
              {
                'id': 1,
                'title': 'Đơn mới',
                'content': 'Booking đã xác nhận',
                'is_read': 0
              }
            ]);
          }
          if (request.url.path.endsWith('/notifications/read-all') &&
              request.method == 'PUT') {
            readAll = true;
            return _jsonResponse({'success': true, 'updated': 1});
          }
          return _jsonResponse({'error': 'Not found'}, 404);
        }));
    addTearDown(api.close);
    await tester.pumpWidget(MaterialApp(
        theme: buildTheme(),
        home: NotificationsScreen(api: api, onChanged: () {})));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Đọc tất cả'));
    await tester.pumpAndSettle();
    expect(readAll, isTrue);
  });

  testWidgets('saves a care note without disposing active text fields',
      (tester) async {
    final api = PawCareApi(
        baseUrl: 'http://pawcare.test/api/v1',
        client: MockClient((request) async {
          if (request.method == 'POST' &&
              request.url.path.endsWith('/care-notes')) {
            return _jsonResponse({'success': true, 'id': 99});
          }
          return _jsonResponse([]);
        }));
    addTearDown(api.close);

    await tester.pumpWidget(MaterialApp(
      theme: buildTheme(),
      home: Scaffold(
        body:
            HomeScreen(profile: const {'fullName': 'Nguyễn Hải An'}, api: api),
      ),
    ));
    await tester.pumpAndSettle();

    final notesButton = find.widgetWithText(TextButton, 'Ghi chú');
    await tester.ensureVisible(notesButton);
    await tester.tap(notesButton);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Thêm ghi chú'));
    await tester.pumpAndSettle();

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(1), 'Uống thuốc');
    await tester.enterText(fields.at(2), 'Sau bữa tối');
    await tester.tap(find.text('Lưu ghi chú'));
    await tester.pumpAndSettle();

    expect(find.text('Uống thuốc'), findsOneWidget);
    expect(find.text('Sau bữa tối'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

http.Response _jsonResponse(Object body, [int statusCode = 200]) =>
    http.Response.bytes(utf8.encode(jsonEncode(body)), statusCode,
        headers: const {'content-type': 'application/json; charset=utf-8'});
