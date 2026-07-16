import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';

/// Tink API Service
/// Handles OAuth2 flow and fetches bank transactions via PSD2 Open Banking.
class TinkService {
  String? _accessToken;
  final http.Client _client = http.Client();

  // ── OAuth2: Get access token ──
  Future<String> _authenticate() async {
    final response = await _client.post(
      Uri.parse('${ApiConfig.tinkBaseUrl}/api/v1/oauth/token'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'client_id': ApiConfig.tinkClientId,
        'client_secret': ApiConfig.tinkClientSecret,
        'grant_type': 'client_credentials',
        'scope': 'accounts:read,transactions:read',
      },
    );
    if (response.statusCode != 200) {
      throw Exception('Tink auth failed: ${response.body}');
    }
    final data = jsonDecode(response.body);
    _accessToken = data['access_token'];
    return _accessToken!;
  }

  Future<Map<String, String>> _authHeaders() async {
    _accessToken ??= await _authenticate();
    return {
      'Authorization': 'Bearer $_accessToken',
      'Content-Type': 'application/json',
    };
  }

  // ── Create a user (representing one app user) ──
  Future<String> createUser({required String externalUserId}) async {
    final headers = await _authHeaders();
    final response = await _client.post(
      Uri.parse('${ApiConfig.tinkBaseUrl}/api/v1/user/create'),
      headers: headers,
      body: jsonEncode({
        'external_user_id': externalUserId,
        'market': ApiConfig.tinkMarket,
        'locale': 'en_US',
        'platform': 'PING',
      }),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to create Tink user: ${response.body}');
    }
    return jsonDecode(response.body)['user_id'];
  }

  // ── Get authorization URL for user to connect their bank ──
  Future<String> getAuthorizationUrl(String userId) async {
    final headers = await _authHeaders();
    final response = await _client.post(
      Uri.parse('${ApiConfig.tinkBaseUrl}/api/v1/oauth/authorization-grant/delegate'),
      headers: headers,
      body: jsonEncode({
        'user_id': userId,
        'id_hint': 'aggregation',
        'scope': 'accounts:read,transactions:read',
        'redirect_uri': ApiConfig.tinkRedirectUri,
        'market': ApiConfig.tinkMarket,
      }),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to get auth URL: ${response.body}');
    }
    return jsonDecode(response.body)['url'];
  }

  // ── Exchange authorization code for permanent credentials ──
  Future<void> exchangeCode(String code) async {
    final headers = await _authHeaders();
    final response = await _client.post(
      Uri.parse('${ApiConfig.tinkBaseUrl}/api/v1/oauth/token'),
      headers: headers,
      body: {
        'code': code,
        'grant_type': 'authorization_code',
        'redirect_uri': ApiConfig.tinkRedirectUri,
      },
    );
    if (response.statusCode != 200) {
      throw Exception('Code exchange failed: ${response.body}');
    }
    // Credentials stored; subsequent calls use the permanent token
  }

  // ── Fetch transactions ──
  Future<List<Map<String, dynamic>>> fetchTransactions({
    required String userId,
    int daysBack = 90,
  }) async {
    final headers = await _authHeaders();
    final from = DateTime.now().subtract(Duration(days: daysBack));
    final to = DateTime.now();

    final response = await _client.get(
      Uri.parse('${ApiConfig.tinkBaseUrl}/api/v1/transactions'
          '?userId=$userId'
          '&from=${from.toIso8601String()}'
          '&to=${to.toIso8601String()}'
          '&limit=500'),
      headers: headers,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch transactions: ${response.body}');
    }

    final data = jsonDecode(response.body);
    return List<Map<String, dynamic>>.from(data['transactions'] ?? []);
  }

  // ── Fetch accounts ──
  Future<List<Map<String, dynamic>>> fetchAccounts(String userId) async {
    final headers = await _authHeaders();
    final response = await _client.get(
      Uri.parse('${ApiConfig.tinkBaseUrl}/api/v1/accounts?userId=$userId'),
      headers: headers,
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to fetch accounts: ${response.body}');
    }
    final data = jsonDecode(response.body);
    return List<Map<String, dynamic>>.from(data['accounts'] ?? []);
  }

  void dispose() => _client.close();
}
