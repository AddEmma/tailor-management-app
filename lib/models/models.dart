class Customer {
  final String id;
  final String name;
  final String phone;
  final String? email;
  final Map<String, double> measurements;
  final DateTime createdAt;
  final String tailorId;

  Customer({
    required this.id,
    required this.name,
    required this.phone,
    this.email,
    required this.measurements,
    required this.createdAt,
    required this.tailorId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'measurements': measurements,
      'createdAt': createdAt.toIso8601String(),
      'tailorId': tailorId,
    };
  }

  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      email: map['email'],
      measurements: Map<String, double>.from(map['measurements'] ?? {}),
      createdAt: DateTime.parse(map['createdAt']),
      tailorId: map['tailorId'] ?? '',
    );
  }
}

class TailorOrder {
  final String id;
  final String customerId;
  final String customerName;
  final String style;
  final String fabric;
  final double price;
  final double paidAmount;
  final DateTime deliveryDate;
  final DateTime materialBroughtDate;
  final DateTime createdAt;
  final OrderStatus status;
  final String tailorId;
  final String? notes;
  final List<String> imageUrls;

  TailorOrder({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.style,
    required this.fabric,
    required this.price,
    required this.paidAmount,
    required this.deliveryDate,
    required this.materialBroughtDate,
    required this.createdAt,
    required this.status,
    required this.tailorId,
    this.notes,
    this.imageUrls = const [],
  });

  double get balanceAmount => price - paidAmount;
  bool get isFullyPaid => paidAmount >= price;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customerId': customerId,
      'customerName': customerName,
      'style': style,
      'fabric': fabric,
      'price': price,
      'paidAmount': paidAmount,
      'deliveryDate': deliveryDate.toIso8601String(),
      'materialBroughtDate': materialBroughtDate.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'status': status.name,
      'tailorId': tailorId,
      'notes': notes,
      'imageUrls': imageUrls,
    };
  }

  factory TailorOrder.fromMap(Map<String, dynamic> map) {
    return TailorOrder(
      id: map['id'] ?? '',
      customerId: map['customerId'] ?? '',
      customerName: map['customerName'] ?? '',
      style: map['style'] ?? '',
      fabric: map['fabric'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      paidAmount: (map['paidAmount'] ?? 0).toDouble(),
      deliveryDate: DateTime.parse(map['deliveryDate']),
      materialBroughtDate: map['materialBroughtDate'] != null 
          ? DateTime.parse(map['materialBroughtDate']) 
          : DateTime.parse(map['createdAt']), // Fallback to createdAt if missing
      createdAt: DateTime.parse(map['createdAt']),
      status: OrderStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => OrderStatus.pending,
      ),
      tailorId: map['tailorId'] ?? '',
      notes: map['notes'],
      imageUrls: List<String>.from(map['imageUrls'] ?? []),
    );
  }
}

enum OrderStatus {
  pending,
  inProgress,
  completed,
  delivered,
  cancelled,
}

class TailorUser {
  final String id;
  final String name;
  final String email;
  final String? businessName;
  final String? phone;
  final DateTime createdAt;

  TailorUser({
    required this.id,
    required this.name,
    required this.email,
    this.businessName,
    this.phone,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'businessName': businessName,
      'phone': phone,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory TailorUser.fromMap(Map<String, dynamic> map) {
    return TailorUser(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      businessName: map['businessName'],
      phone: map['phone'],
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
}

class Payment {
  final String id;
  final String orderId;
  final double amount;
  final DateTime paymentDate;
  final String method;
  final String? notes;

  Payment({
    required this.id,
    required this.orderId,
    required this.amount,
    required this.paymentDate,
    required this.method,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'orderId': orderId,
      'amount': amount,
      'paymentDate': paymentDate.toIso8601String(),
      'method': method,
      'notes': notes,
    };
  }

  factory Payment.fromMap(Map<String, dynamic> map) {
    return Payment(
      id: map['id'] ?? '',
      orderId: map['orderId'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      paymentDate: DateTime.parse(map['paymentDate']),
      method: map['method'] ?? '',
      notes: map['notes'],
    );
  }
}
