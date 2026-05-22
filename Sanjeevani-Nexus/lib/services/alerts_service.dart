import 'dart:convert';

import 'api_client.dart';
import 'api_config.dart';

class AlertsService {
  final ApiClient _client = ApiClient();

  Future<Map<String, dynamic>> getSummary() async {
    final uri = Uri.parse('${ApiConfig.apiUrl}/alerts/summary');
    final response = await _client.get(uri);
    if (response.statusCode != 200) {
      throw Exception('Failed to load alerts summary: ${response.statusCode}');
    }
    final decoded = json.decode(response.body) as Map<String, dynamic>;
    final data = decoded['data'];
    if (data is Map<String, dynamic>) return data;
    return const {};
  }
}
