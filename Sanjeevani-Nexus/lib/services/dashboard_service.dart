import 'dart:convert';

import 'api_config.dart';
import 'api_client.dart';

class DashboardService {
  final ApiClient _client = ApiClient();

  Future<Map<String, dynamic>> getOverview() async {
    final uri = Uri.parse('${ApiConfig.dashboardEndpoint}/overview');
    final response = await _client.get(uri);

    if (response.statusCode != 200) {
      throw Exception('Failed to load dashboard overview: ${response.statusCode}');
    }

    final decoded = json.decode(response.body) as Map<String, dynamic>;
    final data = decoded['data'];
    if (data is! Map<String, dynamic>) {
      throw Exception('Invalid dashboard response format');
    }
    return data;
  }
}
