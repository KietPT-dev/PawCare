import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pawcare_customer_mobile/app/pawcare_app.dart';
import 'package:pawcare_customer_mobile/core/network/pawcare_api.dart';
import 'package:pawcare_customer_mobile/core/theme/app_theme.dart';
import 'package:pawcare_customer_mobile/features/auth/presentation/auth_screen.dart';
import 'package:pawcare_customer_mobile/features/booking/presentation/booking_screen.dart';
import 'package:pawcare_customer_mobile/features/home/presentation/home_screen.dart';
import 'package:pawcare_customer_mobile/features/profile/presentation/profile_screen.dart';

void main() {
  testWidgets('shows PawCare sign in screen', (tester) async {
    await tester.pumpWidget(
        PawCareApp(api: PawCareApi(baseUrl: 'http://pawcare.test')));
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

    final emailField = find.byType(TextFormField).first;
    await tester.tap(emailField);
    await tester.enterText(emailField, 'hello@pawcare.vn');
    await tester.pump();

    expect(find.text('hello@pawcare.vn'), findsOneWidget);
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
