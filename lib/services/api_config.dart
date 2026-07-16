/// Tink API Configuration
/// 
/// To get started:
/// 1. Sign up at https://console.tink.com
/// 2. Create an app to get CLIENT_ID and CLIENT_SECRET
/// 3. Set redirect URI to your app's custom scheme (e.g., ping://callback)
///
/// For MVP, you can use Tink's sandbox environment with test banks.
class ApiConfig {
  // ── Tink ──
  static const String tinkBaseUrl = 'https://api.tink.com';
  static const String tinkClientId = 'YOUR_TINK_CLIENT_ID';
  static const String tinkClientSecret = 'YOUR_TINK_CLIENT_SECRET';
  static const String tinkRedirectUri = 'ping://callback';
  static const String tinkMarket = 'DE'; // DE, FR, ES, NL, IT, GB, etc.

  // ── Feature flags ──
  static const bool useRealApi = false; // set true when Tink credentials configured
  static const bool useMockData = true; // fallback when API unavailable
}
