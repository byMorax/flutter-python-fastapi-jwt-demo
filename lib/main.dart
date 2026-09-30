import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// Backend server URL (Use 10.0.2.2 if running on Android Emulator, or 127.0.0.1 for Web/Desktop)
const String baseUrl = 'http://127.0.0.1:8000';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: LoginScreen(),
    );
  }
}

// ==============================================================================
// 1. DATA MODELS & JSON SERIALIZATION / DESERIALIZATION
// ==============================================================================

class LoginRequest {
  final String username;
  final String password;

  LoginRequest({required this.username, required this.password});

  // SERIALIZATION: Converts Dart object into a Map so it can be encoded into JSON
  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'password': password,
    };
  }
}

class TokenResponse {
  final String accessToken;
  final String tokenType;

  TokenResponse({required this.accessToken, required this.tokenType});

  // DESERIALIZATION: Converts JSON Map received from server into a Dart object
  factory TokenResponse.fromJson(Map<String, dynamic> json) {
    return TokenResponse(
      accessToken: json['access_token'] as String,
      tokenType: json['token_type'] as String,
    );
  }
}

class ProtectedData {
  final String message;
  final String secretData;

  ProtectedData({required this.message, required this.secretData});

  // DESERIALIZATION: Converts JSON Map received from server into a Dart object
  factory ProtectedData.fromJson(Map<String, dynamic> json) {
    return ProtectedData(
      message: json['message'] as String,
      secretData: json['secret_data'] as String,
    );
  }
}

// ==============================================================================
// 2. LOGIN SCREEN
// ==============================================================================

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController(text: 'admin');
  final TextEditingController _passwordController = TextEditingController(text: '123456');
  String _errorMessage = '';
  bool _isLoading = false;

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final requestData = LoginRequest(
        username: _usernameController.text,
        password: _passwordController.text,
      );

      // SERIALIZATION: Converts Dart object to JSON string to send over HTTP
      final String jsonBody = jsonEncode(requestData.toJson());

      final response = await http.post(
        Uri.parse('$baseUrl/api/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonBody,
      );

      if (response.statusCode == 200) {
        // DESERIALIZATION: Parses the JSON string from the response into a Map
        final Map<String, dynamic> responseMap = jsonDecode(response.body);

        // DESERIALIZATION: Converts Map into a strongly-typed TokenResponse Dart object
        final tokenResponse = TokenResponse.fromJson(responseMap);

        // JWT TOKEN HANDLING: Storing the received token in memory
        final String jwtToken = tokenResponse.accessToken;

        if (!mounted) return;

        // Navigate to Dashboard and pass the token in memory
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DashboardScreen(token: jwtToken),
          ),
        );
      } else {
        setState(() {
          _errorMessage = 'Invalid username or password';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error connecting to server. Is FastAPI running?';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('NexusAuth - Login'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(labelText: 'Username'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password'),
            ),
            const SizedBox(height: 20),
            if (_isLoading)
              const CircularProgressIndicator()
            else
              ElevatedButton(
                onPressed: _login,
                child: const Text('Login'),
              ),
            const SizedBox(height: 20),
            if (_errorMessage.isNotEmpty)
              Text(
                _errorMessage,
                style: const TextStyle(color: Colors.red),
              ),
          ],
        ),
      ),
    );
  }
}

// ==============================================================================
// 3. DASHBOARD SCREEN (PROTECTED DATA)
// ==============================================================================

class DashboardScreen extends StatefulWidget {
  // JWT TOKEN HANDLING: The token passed and held in memory
  final String token;

  const DashboardScreen({super.key, required this.token});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String _message = '';
  String _secretData = '';
  bool _isLoading = false;

  Future<void> _fetchProtectedData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // JWT TOKEN HANDLING: Attaching the token to the 'Authorization: Bearer' header
      final response = await http.get(
        Uri.parse('$baseUrl/api/protected-data'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
      );

      if (response.statusCode == 200) {
        // DESERIALIZATION: Parses the JSON string from the response into a Map
        final Map<String, dynamic> responseMap = jsonDecode(response.body);

        // DESERIALIZATION: Converts Map into a strongly-typed ProtectedData Dart object
        final protectedData = ProtectedData.fromJson(responseMap);

        setState(() {
          _message = protectedData.message;
          _secretData = protectedData.secretData;
        });
      } else {
        setState(() {
          _message = 'Failed to fetch protected data: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _message = 'Error connecting to server: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('NexusAuth - Dashboard'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'JWT Token in Memory:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5),
            Text(
              widget.token,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 20),
            if (_isLoading)
              const CircularProgressIndicator()
            else
              ElevatedButton(
                onPressed: _fetchProtectedData,
                child: const Text('Get Protected Data'),
              ),
            const SizedBox(height: 20),
            if (_message.isNotEmpty) ...[
              Text(
                _message,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 10),
              Text(
                _secretData,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                // Return to login screen
                Navigator.pop(context);
              },
              child: const Text('Logout'),
            ),
          ],
        ),
      ),
    );
  }
}
