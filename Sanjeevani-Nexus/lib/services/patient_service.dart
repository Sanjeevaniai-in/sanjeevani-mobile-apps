import 'dart:convert';

import 'api_client.dart';
import 'api_config.dart';

class PatientService {
  final ApiClient _client = ApiClient();

  Future<Map<String, dynamic>> getLivePatients({String? search}) async {
    final query = <String, String>{
      if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
    };

    // Try the live summary endpoint first; fall back to plain customers list.
    try {
      final uri = Uri.parse('${ApiConfig.customersEndpoint}/live/summary')
          .replace(queryParameters: query);
      final response = await _client.get(uri);

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body) as Map<String, dynamic>;
        final data = decoded['data'];
        if (data is Map<String, dynamic>) return data;
      }
    } catch (_) {}

    // Fallback: plain customers list
    try {
      final params = <String, String>{
        'page': '1',
        'page_size': '20',
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
      };
      final uri = Uri.parse('${ApiConfig.customersEndpoint}/')
          .replace(queryParameters: params);
      final response = await _client.get(uri);

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body) as Map<String, dynamic>;
        final data = decoded['data'];
        if (data is List) {
          return {
            'patients': data.whereType<Map<String, dynamic>>().toList(),
            'summary': <String, dynamic>{},
          };
        }
      }
    } catch (_) {}

    // Return empty rather than crashing the whole overview
    return const {
      'patients': <Map<String, dynamic>>[],
      'summary': <String, dynamic>{},
    };
  }
}
