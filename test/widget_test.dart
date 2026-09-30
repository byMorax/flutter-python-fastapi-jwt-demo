import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_auth/main.dart';

void main() {
  test('LoginRequest serializes to JSON Map', () {
    final request = LoginRequest(username: 'admin', password: 'password123');
    final jsonMap = request.toJson();

    expect(jsonMap['username'], equals('admin'));
    expect(jsonMap['password'], equals('password123'));

    final encoded = jsonEncode(jsonMap);
    expect(encoded, contains('"username":"admin"'));
    expect(encoded, contains('"password":"password123"'));
  });

  test('TokenResponse deserializes from JSON Map', () {
    final sampleJson = {
      'access_token': 'sample_jwt_token',
      'token_type': 'bearer',
    };

    final token = TokenResponse.fromJson(sampleJson);
    expect(token.accessToken, equals('sample_jwt_token'));
    expect(token.tokenType, equals('bearer'));
  });

  test('ProtectedData deserializes from JSON Map', () {
    final sampleJson = {
      'message': 'Hello admin',
      'secret_data': 'Secret Vault 42',
    };

    final data = ProtectedData.fromJson(sampleJson);
    expect(data.message, equals('Hello admin'));
    expect(data.secretData, equals('Secret Vault 42'));
  });

  testWidgets('Renders Login Screen with basic inputs', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.text('NexusAuth - Login'), findsOneWidget);
    expect(find.text('Username'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
  });
}
