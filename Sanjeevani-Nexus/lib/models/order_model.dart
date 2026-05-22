class Order {
  final String orderId;
  final String patientId;
  final String patientName;
  final String medicineName;
  final dynamic quantityOrdered;
  final String orderStatus;
  final String orderChannel;
  final String? contactNumber;
  final String? orderDate;
  final String? paymentMethod;
  final String? notes;

  Order({
    required this.orderId,
    required this.patientId,
    required this.patientName,
    required this.medicineName,
    required this.quantityOrdered,
    required this.orderStatus,
    required this.orderChannel,
    this.contactNumber,
    this.orderDate,
    this.paymentMethod,
    this.notes,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      orderId: json['Order ID'] ?? '',
      patientId: json['Patient ID'] ?? '',
      patientName: json['Patient Name'] ?? '',
      medicineName: json['Medicine Name'] ?? '',
      quantityOrdered: json['Quantity Ordered'] ?? json['Quantity'] ?? 1,
      orderStatus: json['Order Status'] ?? 'Pending',
      orderChannel: json['Order Channel'] ?? 'Unknown',
      contactNumber: json['Contact Number']?.toString(),
      orderDate: json['Order Date'],
      paymentMethod: json['Payment Method'],
      notes: json['Notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Order ID': orderId,
      'Patient ID': patientId,
      'Patient Name': patientName,
      'Medicine Name': medicineName,
      'Quantity Ordered': quantityOrdered,
      'Order Status': orderStatus,
      'Order Channel': orderChannel,
      'Contact Number': contactNumber,
      'Order Date': orderDate,
      'Payment Method': paymentMethod,
      'Notes': notes,
    };
  }
}

class OrderStats {
  final List<StatusCount> byStatus;
  final List<ChannelCount> byChannel;
  final List<PaymentCount> byPayment;
  final int total;

  OrderStats({
    required this.byStatus,
    required this.byChannel,
    required this.byPayment,
    required this.total,
  });

  factory OrderStats.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? {};
    return OrderStats(
      byStatus: (data['by_status'] as List?)
              ?.map((e) => StatusCount.fromJson(e))
              .toList() ??
          [],
      byChannel: (data['by_channel'] as List?)
              ?.map((e) => ChannelCount.fromJson(e))
              .toList() ??
          [],
      byPayment: (data['by_payment'] as List?)
              ?.map((e) => PaymentCount.fromJson(e))
              .toList() ??
          [],
      total: data['total'] ?? 0,
    );
  }

  int getCountForStatus(String status) {
    try {
      return byStatus.firstWhere((s) => s.label == status).count;
    } catch (e) {
      return 0;
    }
  }
}

class StatusCount {
  final String label;
  final int count;

  StatusCount({required this.label, required this.count});

  factory StatusCount.fromJson(Map<String, dynamic> json) {
    return StatusCount(
      label: json['label'] ?? '',
      count: json['count'] ?? 0,
    );
  }
}

class ChannelCount {
  final String label;
  final int count;

  ChannelCount({required this.label, required this.count});

  factory ChannelCount.fromJson(Map<String, dynamic> json) {
    return ChannelCount(
      label: json['label'] ?? '',
      count: json['count'] ?? 0,
    );
  }
}

class PaymentCount {
  final String label;
  final int count;

  PaymentCount({required this.label, required this.count});

  factory PaymentCount.fromJson(Map<String, dynamic> json) {
    return PaymentCount(
      label: json['label'] ?? '',
      count: json['count'] ?? 0,
    );
  }
}
