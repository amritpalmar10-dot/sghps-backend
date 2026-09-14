// api_service.dart
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl =
      'https://rewash-bullpen-rejoicing.ngrok-free.dev';

  // ✅ GLOBAL HEADERS - All API calls vich use karo
  static Map<String, String> get headers => {
        'Content-Type': 'application/json',
        'ngrok-skip-browser-warning': 'true', // ← Bypass ngrok warning
      };

  static Map<String, String> authHeaders(String token) => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
        'ngrok-skip-browser-warning': 'true',
      };
}
