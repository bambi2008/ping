import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Simple auth provider — stores user info locally (no backend).
/// In production, this would connect to Firebase Auth or a custom backend.
class AuthProvider extends ChangeNotifier {
  static const _userKey = 'auth_user_v1';

  PingUser? _user;
  bool _isLoading = false;

  PingUser? get user => _user;
  bool get isLoggedIn => _user != null;
  bool get isLoading => _isLoading;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_userKey);
    if (raw != null) {
      _user = PingUser.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    }
    notifyListeners();
  }

  Future<void> signInWithEmail({
    required String email,
    String? displayName,
  }) async {
    _isLoading = true;
    notifyListeners();
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 600));
    _user = PingUser(
      id: 'email_${email.hashCode}',
      email: email,
      displayName: displayName ?? email.split('@').first,
      provider: AuthProviderType.email,
      createdAt: DateTime.now(),
    );
    await _persistUser();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> signInWithApple({
    required String email,
    String? displayName,
  }) async {
    _isLoading = true;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 400));
    _user = PingUser(
      id: 'apple_${email.hashCode}',
      email: email,
      displayName: displayName ?? email.split('@').first,
      provider: AuthProviderType.apple,
      createdAt: DateTime.now(),
    );
    await _persistUser();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> signInWithGoogle({
    required String email,
    String? displayName,
  }) async {
    _isLoading = true;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 400));
    _user = PingUser(
      id: 'google_${email.hashCode}',
      email: email,
      displayName: displayName ?? email.split('@').first,
      provider: AuthProviderType.google,
      createdAt: DateTime.now(),
    );
    await _persistUser();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> signOut() async {
    _user = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
    notifyListeners();
  }

  Future<void> _persistUser() async {
    final prefs = await SharedPreferences.getInstance();
    if (_user != null) {
      await prefs.setString(_userKey, jsonEncode(_user!.toJson()));
    }
  }
}

enum AuthProviderType { email, apple, google }

extension AuthProviderTypeLabel on AuthProviderType {
  String get label => switch (this) {
        AuthProviderType.email => 'Email',
        AuthProviderType.apple => 'Apple',
        AuthProviderType.google => 'Google',
      };
  IconData get icon => switch (this) {
        AuthProviderType.email => Icons.email,
        AuthProviderType.apple => Icons.apple,
        AuthProviderType.google => Icons.g_mobiledata,
      };
}

class PingUser {
  final String id;
  final String email;
  final String displayName;
  final AuthProviderType provider;
  final DateTime createdAt;

  PingUser({
    required this.id,
    required this.email,
    required this.displayName,
    required this.provider,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'displayName': displayName,
        'provider': provider.name,
        'createdAt': createdAt.toIso8601String(),
      };

  factory PingUser.fromJson(Map<String, dynamic> json) => PingUser(
        id: json['id'] as String,
        email: json['email'] as String,
        displayName: json['displayName'] as String,
        provider: AuthProviderType.values.firstWhere(
          (v) => v.name == json['provider'],
          orElse: () => AuthProviderType.email,
        ),
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
