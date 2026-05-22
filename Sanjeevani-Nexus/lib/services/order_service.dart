import 'dart:convert';
import '../models/order_model.dart';
import 'api_config.dart';
import 'api_client.dart';

class OrderService {
  final ApiClient _client = ApiClient();

  Future<Map<String, dynamic>> getOrders({
    int page = 1,
    int pageSize = 20,
    String? status,
    String? patientId,
    String? medicine,
    String? channel,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'page_size': pageSize.toString(),
      };

      if (status != null && status != 'All') {
        queryParams['status'] = status;
      }
      if (patientId != null) queryParams['patient_id'] = patientId;
      if (medicine != null) queryParams['medicine'] = medicine;
      if (channel != null) queryParams['channel'] = channel;

      final uri = Uri.parse(ApiConfig.ordersEndpoint)
          .replace(queryParameters: queryParams);

      final response = await _client.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final orders = (data['data'] as List)
            .map((orderJson) => Order.fromJson(orderJson))
            .toList();

        return {
          'orders': orders,
          'total': data['total'] ?? 0,
          'page': data['page'] ?? 1,
          'total_pages': data['total_pages'] ?? 1,
        };
      } else {
        throw Exception('Failed to load orders: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching orders: $e');
    }
  }

  Future<OrderStats> getOrderStats() async {
    try {
      final uri = Uri.parse('${ApiConfig.ordersEndpoint}/stats');
      final response = await _client.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return OrderStats.fromJson(data);
      } else {
        throw Exception('Failed to load order stats: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching order stats: $e');
    }
  }

  Future<Order> getOrderById(String orderId) async {
    try {
      final uri = Uri.parse('${ApiConfig.ordersEndpoint}/$orderId');
      final response = await _client.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Order.fromJson(data['data']);
      } else {
        throw Exception('Failed to load order: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching order: $e');
    }
  }

  Future<Map<String, dynamic>> updateOrderStatus(
      String orderId, String status) async {
    try {
      final uri = Uri.parse('${ApiConfig.ordersEndpoint}/$orderId/status');
      final response = await _client.patch(uri, body: {'status': status});

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to update order status');
      }
    } catch (e) {
      throw Exception('Error updating order status: $e');
    }
  }

  Future<Map<String, dynamic>> confirmAndDispatchOrder(String orderId) async {
    try {
      final uri = Uri.parse('${ApiConfig.ordersEndpoint}/$orderId/confirm');
      final response = await _client.post(uri);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['detail'] ?? 'Failed to confirm order');
      }
    } catch (e) {
      throw Exception('Error confirming order: $e');
    }
  }
}
