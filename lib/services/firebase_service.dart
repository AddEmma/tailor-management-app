import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

class FirebaseService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // In-memory storage for quick access
  static final Map<String, List<Customer>> _mockCustomers = {};
  static final Map<String, List<TailorOrder>> _mockOrders = {};
  static final Map<String, TailorUser> _mockUsers = {};

  // Stream controllers
  static final Map<String, StreamController<List<Customer>>>
  _customerControllers = {};
  static final Map<String, StreamController<List<TailorOrder>>>
  _orderControllers = {};
  static final Map<String, List<Payment>> _mockPayments = {};
  static final Map<String, StreamController<List<Payment>>>
  _paymentControllers = {};

  // Counters
  static int _customerIdCounter = 1000;
  static int _orderIdCounter = 2000;

  // Storage keys
  static const String _customersKey = 'mock_customers';
  static const String _ordersKey = 'mock_orders';
  static const String _paymentsKey = 'mock_payments';
  static const String _usersKey = 'mock_users';
  static const String _customerCounterKey = 'customer_counter';
  static const String _orderCounterKey = 'order_counter';

  // Initialization flag to prevent multiple loads
  static bool _isInitialized = false;

  // Initialize storage - IMPROVED with better error handling
  static Future<void> _initializeStorage() async {
    if (_isInitialized) return; // Skip if already initialized

    try {
      _log('Initializing storage...');
      final prefs = await SharedPreferences.getInstance();

      // Load counters
      _customerIdCounter = prefs.getInt(_customerCounterKey) ?? 1000;
      _orderIdCounter = prefs.getInt(_orderCounterKey) ?? 2000;
      _log(
        'Loaded counters - Customer: $_customerIdCounter, Order: $_orderIdCounter',
      );

      // Load customers with better error handling
      final customersJson = prefs.getString(_customersKey);
      if (customersJson != null && customersJson.isNotEmpty) {
        try {
          final customersData =
              json.decode(customersJson) as Map<String, dynamic>;
          _mockCustomers.clear();
          customersData.forEach((tailorId, customersList) {
            if (customersList is List) {
              _mockCustomers[tailorId] = customersList
                  .map((customerJson) {
                    try {
                      return Customer.fromMap(customerJson);
                    } catch (e) {
                      _log('Error parsing customer: $e', level: 'WARNING');
                      return null;
                    }
                  })
                  .where((customer) => customer != null)
                  .cast<Customer>()
                  .toList();
            }
          });
          _log(
            'Loaded ${_mockCustomers.length} tailor customer lists from storage',
          );
        } catch (e) {
          _log('Error parsing customers JSON: $e', level: 'ERROR');
          _mockCustomers.clear();
        }
      }

      // Load orders with better error handling
      final ordersJson = prefs.getString(_ordersKey);
      if (ordersJson != null && ordersJson.isNotEmpty) {
        try {
          final ordersData = json.decode(ordersJson) as Map<String, dynamic>;
          _mockOrders.clear();
          ordersData.forEach((tailorId, ordersList) {
            if (ordersList is List) {
              _mockOrders[tailorId] = ordersList
                  .map((orderJson) {
                    try {
                      return TailorOrder.fromMap(orderJson);
                    } catch (e) {
                      _log('Error parsing order: $e', level: 'WARNING');
                      return null;
                    }
                  })
                  .where((order) => order != null)
                  .cast<TailorOrder>()
                  .toList();
            }
          });
          _log('Loaded ${_mockOrders.length} tailor order lists from storage');
        } catch (e) {
          _log('Error parsing orders JSON: $e', level: 'ERROR');
          _mockOrders.clear();
        }
      }

      // Load payments with better error handling
      final paymentsJson = prefs.getString(_paymentsKey);
      if (paymentsJson != null && paymentsJson.isNotEmpty) {
        try {
          final paymentsData = json.decode(paymentsJson) as Map<String, dynamic>;
          _mockPayments.clear();
          paymentsData.forEach((orderId, paymentsList) {
            if (paymentsList is List) {
              _mockPayments[orderId] = paymentsList
                  .map((paymentJson) {
                    try {
                      return Payment.fromMap(paymentJson);
                    } catch (e) {
                      _log('Error parsing payment: $e', level: 'WARNING');
                      return null;
                    }
                  })
                  .where((payment) => payment != null)
                  .cast<Payment>()
                  .toList();
            }
          });
          _log('Loaded ${_mockPayments.length} order payment lists from storage');
        } catch (e) {
          _log('Error parsing payments JSON: $e', level: 'ERROR');
          _mockPayments.clear();
        }
      }

      // Load users with better error handling
      final usersJson = prefs.getString(_usersKey);
      if (usersJson != null && usersJson.isNotEmpty) {
        try {
          final usersData = json.decode(usersJson) as Map<String, dynamic>;
          _mockUsers.clear();
          usersData.forEach((userId, userJson) {
            try {
              _mockUsers[userId] = TailorUser.fromMap(userJson);
            } catch (e) {
              _log('Error parsing user $userId: $e', level: 'WARNING');
            }
          });
          _log('Loaded ${_mockUsers.length} users from storage');
        } catch (e) {
          _log('Error parsing users JSON: $e', level: 'ERROR');
          _mockUsers.clear();
        }
      }

      _isInitialized = true;
      _log('Storage initialization complete');
    } catch (e) {
      _log('Critical error initializing storage: $e', level: 'ERROR');
      _isInitialized = false;
      // Reset to defaults on critical error
      _customerIdCounter = 1000;
      _orderIdCounter = 2000;
      _mockCustomers.clear();
      _mockOrders.clear();
      _mockUsers.clear();
    }
  }

  // Save to storage with improved error handling
  static Future<void> _saveCustomersToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final customersData = <String, dynamic>{};

      _mockCustomers.forEach((tailorId, customers) {
        try {
          customersData[tailorId] = customers.map((c) => c.toMap()).toList();
        } catch (e) {
          _log('Error serializing customers for $tailorId: $e', level: 'ERROR');
        }
      });

      await prefs.setString(_customersKey, json.encode(customersData));
      await prefs.setInt(_customerCounterKey, _customerIdCounter);
      _log('Saved customers to storage successfully');
    } catch (e) {
      _log('Error saving customers: $e', level: 'ERROR');
      throw Exception('Failed to save customer data');
    }
  }

  static Future<void> _saveOrdersToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ordersData = <String, dynamic>{};

      _mockOrders.forEach((tailorId, orders) {
        try {
          ordersData[tailorId] = orders.map((o) => o.toMap()).toList();
        } catch (e) {
          _log('Error serializing orders for $tailorId: $e', level: 'ERROR');
        }
      });

      await prefs.setString(_ordersKey, json.encode(ordersData));
      await prefs.setInt(_orderCounterKey, _orderIdCounter);
      _log('Saved orders to storage successfully');
    } catch (e) {
      _log('Error saving orders: $e', level: 'ERROR');
      throw Exception('Failed to save order data');
    }
  }

  static Future<void> _savePaymentsToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final paymentsData = <String, dynamic>{};

      _mockPayments.forEach((orderId, payments) {
        try {
          paymentsData[orderId] = payments.map((p) => p.toMap()).toList();
        } catch (e) {
          _log('Error serializing payments for $orderId: $e', level: 'ERROR');
        }
      });

      await prefs.setString(_paymentsKey, json.encode(paymentsData));
      _log('Saved payments to storage successfully');
    } catch (e) {
      _log('Error saving payments: $e', level: 'ERROR');
      throw Exception('Failed to save payment data');
    }
  }

  static Future<void> _saveUsersToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final usersData = <String, dynamic>{};

      _mockUsers.forEach((userId, user) {
        try {
          usersData[userId] = user.toMap();
        } catch (e) {
          _log('Error serializing user $userId: $e', level: 'ERROR');
        }
      });

      await prefs.setString(_usersKey, json.encode(usersData));
      _log('Saved users to storage successfully');
    } catch (e) {
      _log('Error saving users: $e', level: 'ERROR');
      throw Exception('Failed to save user data');
    }
  }

  // Improved logging utility
  static void _log(String message, {String level = 'INFO'}) {
    final timestamp = DateTime.now().toIso8601String();
    developer.log(
      '[$timestamp] $message',
      name: 'FirebaseService',
      level: _getLogLevel(level),
    );
  }

  static int _getLogLevel(String level) {
    switch (level.toUpperCase()) {
      case 'ERROR':
        return 1000;
      case 'WARNING':
        return 900;
      case 'INFO':
        return 800;
      case 'DEBUG':
        return 700;
      default:
        return 800;
    }
  }

  // Auth Methods (keep real auth)
  static Future<UserCredential?> signIn(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      _log('Sign in failed: $e', level: 'ERROR');
      throw Exception('Sign in failed: $e');
    }
  }

  static Future<UserCredential?> signUp(
    String email,
    String password,
    String name,
    String? businessName,
  ) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (result.user != null) {
        await createUserProfile(
          TailorUser(
            id: result.user!.uid,
            name: name,
            email: email,
            businessName: businessName,
            createdAt: DateTime.now(),
          ),
        );
      }

      return result;
    } catch (e) {
      _log('Sign up failed: $e', level: 'ERROR');
      throw Exception('Sign up failed: $e');
    }
  }

  static Future<void> signOut() async {
    try {
      await _auth.signOut();
      _log('User signed out successfully');
    } catch (e) {
      _log('Sign out failed: $e', level: 'ERROR');
      throw Exception('Sign out failed: $e');
    }
  }

  static User? getCurrentUser() {
    return _auth.currentUser;
  }

  // User Profile Methods
  static Future<void> createUserProfile(TailorUser user) async {
    try {
      await _initializeStorage();
      await Future.delayed(const Duration(milliseconds: 100));
      _mockUsers[user.id] = user;
      await _saveUsersToStorage();
      _log('Created user profile for ${user.name}');
    } catch (e) {
      _log('Error creating user profile: $e', level: 'ERROR');
      throw Exception('Failed to create user profile: $e');
    }
  }

  static Future<void> createUserProfileFromData(
    String userId,
    String name,
    String email,
    String? businessName,
  ) async {
    final user = TailorUser(
      id: userId,
      name: name,
      email: email,
      businessName: businessName,
      createdAt: DateTime.now(),
    );
    await createUserProfile(user);
  }

  static Future<TailorUser?> getUserProfile(String userId) async {
    try {
      await _initializeStorage();
      await Future.delayed(const Duration(milliseconds: 50));
      return _mockUsers[userId];
    } catch (e) {
      _log('Error getting user profile: $e', level: 'ERROR');
      return null;
    }
  }

  // IMPROVED Customer Methods with better error handling
  static Future<Customer> addCustomer(Customer customer) async {
    try {
      await _initializeStorage();
      _log('Adding customer ${customer.name}');

      // Validate required fields
      if (customer.name.trim().isEmpty) {
        throw Exception('Customer name is required');
      }
      if (customer.phone.trim().isEmpty) {
        throw Exception('Customer phone is required');
      }
      if (customer.tailorId.trim().isEmpty) {
        throw Exception('Tailor ID is required');
      }

      await Future.delayed(const Duration(milliseconds: 100));

      if (!_mockCustomers.containsKey(customer.tailorId)) {
        _mockCustomers[customer.tailorId] = [];
      }

      final newCustomer = Customer(
        id: customer.id.isEmpty ? 'cust_${_customerIdCounter++}' : customer.id,
        name: customer.name,
        phone: customer.phone,
        email: customer.email,
        tailorId: customer.tailorId,
        createdAt: customer.createdAt,
        measurements: customer.measurements,
      );

      _mockCustomers[customer.tailorId]!.add(newCustomer);
      await _saveCustomersToStorage(); // Save to persistent storage
      _notifyCustomerListeners(customer.tailorId);

      _log('Customer added with ID: ${newCustomer.id}');
      return newCustomer;
    } catch (e) {
      _log('Error adding customer: $e', level: 'ERROR');
      throw Exception('Failed to add customer: $e');
    }
  }

  static Future<Customer> updateCustomer(Customer customer) async {
    try {
      await _initializeStorage();
      _log('Updating customer ${customer.name}');

      // Validate required fields
      if (customer.name.trim().isEmpty) {
        throw Exception('Customer name is required');
      }
      if (customer.phone.trim().isEmpty) {
        throw Exception('Customer phone is required');
      }

      await Future.delayed(const Duration(milliseconds: 100));

      if (_mockCustomers.containsKey(customer.tailorId)) {
        final customers = _mockCustomers[customer.tailorId]!;
        final index = customers.indexWhere((c) => c.id == customer.id);
        if (index != -1) {
          customers[index] = customer;
          await _saveCustomersToStorage();
          _notifyCustomerListeners(customer.tailorId);
          _log('Customer updated successfully');
          return customer;
        } else {
          throw Exception('Customer not found');
        }
      } else {
        throw Exception('No customers found for this tailor');
      }
    } catch (e) {
      _log('Error updating customer: $e', level: 'ERROR');
      throw Exception('Failed to update customer: $e');
    }
  }

  static Future<void> deleteCustomer(String customerId, String tailorId) async {
    try {
      await _initializeStorage();
      _log('Deleting customer $customerId');
      await Future.delayed(const Duration(milliseconds: 100));

      if (_mockCustomers.containsKey(tailorId)) {
        final removedCount = _mockCustomers[tailorId]!.length;
        _mockCustomers[tailorId]!.removeWhere((c) => c.id == customerId);
        final newCount = _mockCustomers[tailorId]!.length;

        if (removedCount > newCount) {
          await _saveCustomersToStorage();
          _log('Customer deleted successfully');
          _notifyCustomerListeners(tailorId);

          // Also delete related orders
          if (_mockOrders.containsKey(tailorId)) {
            _mockOrders[tailorId]!.removeWhere(
              (order) => order.customerId == customerId,
            );
            await _saveOrdersToStorage();
            _notifyOrderListeners(tailorId);
          }
        } else {
          throw Exception('Customer not found');
        }
      } else {
        throw Exception('No customers found for this tailor');
      }
    } catch (e) {
      _log('Error deleting customer: $e', level: 'ERROR');
      throw Exception('Failed to delete customer: $e');
    }
  }

  static Future<Customer?> getCustomer(
    String customerId,
    String tailorId,
  ) async {
    try {
      await _initializeStorage();
      await Future.delayed(const Duration(milliseconds: 50));

      if (_mockCustomers.containsKey(tailorId)) {
        try {
          return _mockCustomers[tailorId]!.firstWhere(
            (c) => c.id == customerId,
          );
        } catch (e) {
          _log('Customer $customerId not found', level: 'WARNING');
          return null;
        }
      }
      return null;
    } catch (e) {
      _log('Error getting customer: $e', level: 'ERROR');
      return null;
    }
  }

  // MAIN FIX: Proper stream handling with storage initialization and error recovery
  static Stream<List<Customer>> getCustomers(String tailorId) {
    _log('getCustomers called for tailorId: $tailorId');

    // Create controller if it doesn't exist
    if (!_customerControllers.containsKey(tailorId)) {
      _log('Creating new stream controller for $tailorId');
      _customerControllers[tailorId] =
          StreamController<List<Customer>>.broadcast(
            onCancel: () {
              _log('Stream cancelled for $tailorId');
            },
          );
    }

    // Initialize and emit data
    _initializeAndEmitCustomers(tailorId);

    return _customerControllers[tailorId]!.stream;
  }

  static Future<void> _initializeAndEmitCustomers(String tailorId) async {
    try {
      await _initializeStorage(); // Load from storage first

      // Initialize with mock data if no data exists
      if (!_mockCustomers.containsKey(tailorId) ||
          _mockCustomers[tailorId]!.isEmpty) {
        _log('Initializing mock customers for $tailorId');
        await _initializeMockCustomers(tailorId);
        await _saveCustomersToStorage(); // Save mock data
      }

      final customers = _mockCustomers[tailorId] ?? [];
      customers.sort(
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );

      if (_customerControllers.containsKey(tailorId) &&
          !_customerControllers[tailorId]!.isClosed) {
        _log('Emitting ${customers.length} customers to stream');
        _customerControllers[tailorId]!.add(List.from(customers));
      }
    } catch (e) {
      _log('Error in _initializeAndEmitCustomers: $e', level: 'ERROR');
      if (_customerControllers.containsKey(tailorId) &&
          !_customerControllers[tailorId]!.isClosed) {
        _customerControllers[tailorId]!.addError(e);
      }
    }
  }

  static Future<void> _initializeMockCustomers(String tailorId) async {
    try {
      _log('Initializing mock data for $tailorId');
      _mockCustomers[tailorId] = [
        Customer(
          id: 'cust_1',
          name: 'John Smith',
          phone: '+1234567890',
          email: 'john@example.com',
          tailorId: tailorId,
          createdAt: DateTime.now().subtract(const Duration(days: 30)),
          measurements: {'chest': 40.0, 'waist': 32.0, 'shoulder': 18.0},
        ),
        Customer(
          id: 'cust_2',
          name: 'Sarah Johnson',
          phone: '+1234567891',
          email: 'sarah@example.com',
          tailorId: tailorId,
          createdAt: DateTime.now().subtract(const Duration(days: 15)),
          measurements: {'bust': 36.0, 'waist': 28.0, 'hip': 38.0},
        ),
        Customer(
          id: 'cust_3',
          name: 'Mike Wilson',
          phone: '+1234567892',
          email: 'mike@example.com',
          tailorId: tailorId,
          createdAt: DateTime.now().subtract(const Duration(days: 7)),
          measurements: {'chest': 42.0, 'waist': 34.0, 'shoulder': 19.0},
        ),
        Customer(
          id: 'cust_4',
          name: 'Emma Davis',
          phone: '+1234567893',
          email: 'emma@example.com',
          tailorId: tailorId,
          createdAt: DateTime.now().subtract(const Duration(days: 3)),
          measurements: {'bust': 34.0, 'waist': 26.0, 'hip': 36.0},
        ),
      ];
      _log('Created ${_mockCustomers[tailorId]!.length} mock customers');
    } catch (e) {
      _log('Error initializing mock customers: $e', level: 'ERROR');
      _mockCustomers[tailorId] = []; // Initialize empty list on error
    }
  }

  static void _notifyCustomerListeners(String tailorId) {
    try {
      _log('Notifying customer listeners for $tailorId');
      if (_customerControllers.containsKey(tailorId) &&
          !_customerControllers[tailorId]!.isClosed) {
        final customers = _mockCustomers[tailorId] ?? [];
        customers.sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );
        _log('Broadcasting ${customers.length} customers');
        _customerControllers[tailorId]!.add(List.from(customers));
      } else {
        _log('No active listeners for $tailorId', level: 'WARNING');
      }
    } catch (e) {
      _log('Error notifying customer listeners: $e', level: 'ERROR');
    }
  }

  // Order Methods - IMPROVED with better error handling
  static Future<TailorOrder> addOrder(TailorOrder order) async {
    try {
      await _initializeStorage();
      _log('Adding order for customer ${order.customerName}');

      // Validate required fields
      if (order.customerId.trim().isEmpty) {
        throw Exception('Customer ID is required');
      }
      if (order.tailorId.trim().isEmpty) {
        throw Exception('Tailor ID is required');
      }

      await Future.delayed(const Duration(milliseconds: 100));

      if (!_mockOrders.containsKey(order.tailorId)) {
        _mockOrders[order.tailorId] = [];
      }

      final newOrder = TailorOrder(
        id: order.id.isEmpty ? 'order_${_orderIdCounter++}' : order.id,
        customerId: order.customerId,
        customerName: order.customerName,
        style: order.style,
        fabric: order.fabric,
        price: order.price,
        paidAmount: order.paidAmount,
        deliveryDate: order.deliveryDate,
        materialBroughtDate: order.materialBroughtDate,
        createdAt: order.createdAt,
        status: order.status,
        tailorId: order.tailorId,
        notes: order.notes,
        imageUrls: order.imageUrls,
      );

      _mockOrders[order.tailorId]!.add(newOrder);
      await _saveOrdersToStorage();
      _notifyOrderListeners(order.tailorId);

      _log('Order added with ID: ${newOrder.id}');
      return newOrder;
    } catch (e) {
      _log('Error adding order: $e', level: 'ERROR');
      throw Exception('Failed to add order: $e');
    }
  }

  static Future<TailorOrder> updateOrder(TailorOrder order) async {
    try {
      await _initializeStorage();
      _log('Updating order ${order.id}');
      await Future.delayed(const Duration(milliseconds: 100));

      if (_mockOrders.containsKey(order.tailorId)) {
        final orders = _mockOrders[order.tailorId]!;
        final index = orders.indexWhere((o) => o.id == order.id);
        if (index != -1) {
          orders[index] = order;
          await _saveOrdersToStorage();
          _notifyOrderListeners(order.tailorId);
          _log('Order updated successfully');
          return order;
        } else {
          throw Exception('Order not found');
        }
      } else {
        throw Exception('No orders found for this tailor');
      }
    } catch (e) {
      _log('Error updating order: $e', level: 'ERROR');
      throw Exception('Failed to update order: $e');
    }
  }

  static Future<void> deleteOrder(String orderId, String tailorId) async {
    try {
      await _initializeStorage();
      _log('Deleting order $orderId');
      await Future.delayed(const Duration(milliseconds: 100));

      if (_mockOrders.containsKey(tailorId)) {
        final removedCount = _mockOrders[tailorId]!.length;
        _mockOrders[tailorId]!.removeWhere((o) => o.id == orderId);
        final newCount = _mockOrders[tailorId]!.length;

        if (removedCount > newCount) {
          await _saveOrdersToStorage();
          _notifyOrderListeners(tailorId);
          _log('Order deleted successfully');
        } else {
          throw Exception('Order not found');
        }
      } else {
        throw Exception('No orders found for this tailor');
      }
    } catch (e) {
      _log('Error deleting order: $e', level: 'ERROR');
      throw Exception('Failed to delete order: $e');
    }
  }

  static Stream<List<TailorOrder>> getOrders(String tailorId) {
    _log('getOrders called for tailorId: $tailorId');

    // Create controller if it doesn't exist
    if (!_orderControllers.containsKey(tailorId)) {
      _log('Creating new order stream controller for $tailorId');
      _orderControllers[tailorId] =
          StreamController<List<TailorOrder>>.broadcast(
            onCancel: () {
              _log('Order stream cancelled for $tailorId');
            },
          );
    }

    // Initialize and emit data
    _initializeAndEmitOrders(tailorId);

    return _orderControllers[tailorId]!.stream;
  }

  static Future<void> _initializeAndEmitOrders(String tailorId) async {
    try {
      await _initializeStorage(); // Load from storage first

      // Initialize with mock data if no data exists
      if (!_mockOrders.containsKey(tailorId) ||
          _mockOrders[tailorId]!.isEmpty) {
        _log('Initializing mock orders for $tailorId');
        await _initializeMockOrders(tailorId);
        await _saveOrdersToStorage(); // Save mock data
      }

      final orders = _mockOrders[tailorId] ?? [];
      orders.sort((a, b) => a.deliveryDate.compareTo(b.deliveryDate));

      if (_orderControllers.containsKey(tailorId) &&
          !_orderControllers[tailorId]!.isClosed) {
        _log('Emitting ${orders.length} orders to stream');
        _orderControllers[tailorId]!.add(List.from(orders));
      }
    } catch (e) {
      _log('Error in _initializeAndEmitOrders: $e', level: 'ERROR');
      if (_orderControllers.containsKey(tailorId) &&
          !_orderControllers[tailorId]!.isClosed) {
        _orderControllers[tailorId]!.addError(e);
      }
    }
  }

  static Stream<List<TailorOrder>> getUpcomingOrders(String tailorId) {
    return getOrders(tailorId).map((orders) {
      final now = DateTime.now();
      final nextWeek = now.add(const Duration(days: 7));

      return orders.where((order) {
        return order.deliveryDate.isAfter(now) &&
            order.deliveryDate.isBefore(nextWeek) &&
            (order.status == OrderStatus.pending ||
                order.status == OrderStatus.inProgress);
      }).toList();
    });
  }

  static Future<void> _initializeMockOrders(String tailorId) async {
    try {
      _mockOrders[tailorId] = [
        TailorOrder(
          id: 'order_1',
          customerId: 'cust_1',
          customerName: 'John Smith',
          style: 'Business Suit',
          fabric: 'Wool Blend',
          price: 450.0,
          paidAmount: 200.0,
          deliveryDate: DateTime.now().add(const Duration(days: 5)),
          materialBroughtDate: DateTime.now().subtract(const Duration(days: 10)),
          createdAt: DateTime.now().subtract(const Duration(days: 10)),
          status: OrderStatus.inProgress,
          tailorId: tailorId,
          notes: 'Customer prefers navy blue',
        ),
        TailorOrder(
          id: 'order_2',
          customerId: 'cust_2',
          customerName: 'Sarah Johnson',
          style: 'Evening Dress',
          fabric: 'Silk',
          price: 320.0,
          paidAmount: 320.0,
          deliveryDate: DateTime.now().add(const Duration(days: 3)),
          materialBroughtDate: DateTime.now().subtract(const Duration(days: 7)),
          createdAt: DateTime.now().subtract(const Duration(days: 7)),
          status: OrderStatus.completed,
          tailorId: tailorId,
          notes: 'Red color, floor length',
        ),
        TailorOrder(
          id: 'order_3',
          customerId: 'cust_1',
          customerName: 'John Smith',
          style: 'Casual Shirt',
          fabric: 'Cotton',
          price: 80.0,
          paidAmount: 0.0,
          deliveryDate: DateTime.now().add(const Duration(days: 12)),
          materialBroughtDate: DateTime.now().subtract(const Duration(days: 2)),
          createdAt: DateTime.now().subtract(const Duration(days: 2)),
          status: OrderStatus.pending,
          tailorId: tailorId,
          notes: 'Blue checkered pattern',
        ),
      ];
      _log('Created ${_mockOrders[tailorId]!.length} mock orders');
    } catch (e) {
      _log('Error initializing mock orders: $e', level: 'ERROR');
      _mockOrders[tailorId] = []; // Initialize empty list on error
    }
  }

  static void _notifyOrderListeners(String tailorId) {
    try {
      if (_orderControllers.containsKey(tailorId) &&
          !_orderControllers[tailorId]!.isClosed) {
        final orders = _mockOrders[tailorId] ?? [];
        orders.sort((a, b) => a.deliveryDate.compareTo(b.deliveryDate));
        _orderControllers[tailorId]!.add(List.from(orders));
        _log('Notified order listeners for $tailorId');
      }
    } catch (e) {
      _log('Error notifying order listeners: $e', level: 'ERROR');
    }
  }

  static Future<String> uploadOrderImage(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('File does not exist');
      }

      final directory = await getApplicationDocumentsDirectory();
      final imagesDir = Directory('${directory.path}/order_images');
      if (!await imagesDir.exists()) {
        await imagesDir.create(recursive: true);
      }

      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${path.basename(filePath)}';
      final newPath = '${imagesDir.path}/$fileName';

      await file.copy(newPath);
      _log('Image "uploaded" to $newPath');
      return newPath;
    } catch (e) {
      _log('Error uploading image: $e', level: 'ERROR');
      throw Exception('Failed to upload image: $e');
    }
  }

  static Future<void> deleteOrderImage(String imagePath) async {
    try {
      final file = File(imagePath);
      if (await file.exists()) {
        await file.delete();
        _log('Image deleted: $imagePath');
      }
    } catch (e) {
      _log('Error deleting image: $e', level: 'ERROR');
    }
  }

  // Payment and other methods remain the same but with improved error handling
  static Future<void> addPayment(Payment payment) async {
    try {
      await _initializeStorage();
      _log('Adding payment for order ${payment.orderId}');
      await Future.delayed(const Duration(milliseconds: 100));

      // 1. Store the payment record
      if (!_mockPayments.containsKey(payment.orderId)) {
        _mockPayments[payment.orderId] = [];
      }
      _mockPayments[payment.orderId]!.add(payment);
      await _savePaymentsToStorage();
      _notifyPaymentListeners(payment.orderId);

      // 2. Update the order's paid amount
      for (var tailorId in _mockOrders.keys) {
        final orders = _mockOrders[tailorId]!;
        final orderIndex = orders.indexWhere((o) => o.id == payment.orderId);
        if (orderIndex != -1) {
          final order = orders[orderIndex];
          final updatedOrder = TailorOrder(
            id: order.id,
            customerId: order.customerId,
            customerName: order.customerName,
            style: order.style,
            fabric: order.fabric,
            price: order.price,
            paidAmount: order.paidAmount + payment.amount,
            deliveryDate: order.deliveryDate,
            materialBroughtDate: order.materialBroughtDate,
            createdAt: order.createdAt,
            status: order.status,
            tailorId: order.tailorId,
            notes: order.notes,
            imageUrls: order.imageUrls,
          );
          orders[orderIndex] = updatedOrder;
          await _saveOrdersToStorage();
          _notifyOrderListeners(tailorId);
          _log('Payment added and order updated successfully');
          break;
        }
      }
    } catch (e) {
      _log('Error adding payment: $e', level: 'ERROR');
      throw Exception('Failed to add payment: $e');
    }
  }

  static Stream<List<Payment>> getPayments(String orderId) {
    _log('getPayments called for orderId: $orderId');

    if (!_paymentControllers.containsKey(orderId)) {
      _paymentControllers[orderId] = StreamController<List<Payment>>.broadcast();
    }

    _initializeAndEmitPayments(orderId);

    return _paymentControllers[orderId]!.stream;
  }

  static Future<void> _initializeAndEmitPayments(String orderId) async {
    try {
      await _initializeStorage();
      final payments = _mockPayments[orderId] ?? [];
      payments.sort((a, b) => b.paymentDate.compareTo(a.paymentDate)); // Recent first

      if (_paymentControllers.containsKey(orderId) &&
          !_paymentControllers[orderId]!.isClosed) {
        _paymentControllers[orderId]!.add(List.from(payments));
      }
    } catch (e) {
      _log('Error emitting payments: $e', level: 'ERROR');
    }
  }

  static void _notifyPaymentListeners(String orderId) {
    if (_paymentControllers.containsKey(orderId) &&
        !_paymentControllers[orderId]!.isClosed) {
      final payments = _mockPayments[orderId] ?? [];
      payments.sort((a, b) => b.paymentDate.compareTo(a.paymentDate));
      _paymentControllers[orderId]!.add(List.from(payments));
    }
  }

  static Future<void> initializeNotifications() async {
    // Do nothing in development
  }

  static Future<Map<String, dynamic>> getDashboardData(String tailorId) async {
    try {
      await _initializeStorage();
      await Future.delayed(const Duration(milliseconds: 200));

      final customers = _mockCustomers[tailorId] ?? [];
      final orders = _mockOrders[tailorId] ?? [];
      final activeOrders = orders
          .where(
            (o) =>
                o.status == OrderStatus.pending ||
                o.status == OrderStatus.inProgress,
          )
          .length;

      final monthlyRevenue = orders
          .where((o) => o.createdAt.month == DateTime.now().month)
          .fold(0.0, (sum, order) => sum + order.paidAmount);

      final pendingPayments = orders
          .where((o) => o.price > o.paidAmount)
          .fold(0.0, (sum, order) => sum + (order.price - order.paidAmount));

      return {
        'totalCustomers': customers.length,
        'activeOrders': activeOrders,
        'monthlyRevenue': monthlyRevenue,
        'pendingPayments': pendingPayments,
        'completedOrders': orders
            .where((o) => o.status == OrderStatus.completed)
            .length,
        'deliveredOrders': orders
            .where((o) => o.status == OrderStatus.delivered)
            .length,
      };
    } catch (e) {
      _log('Error getting dashboard data: $e', level: 'ERROR');
      // Return default values on error
      return {
        'totalCustomers': 0,
        'activeOrders': 0,
        'monthlyRevenue': 0.0,
        'pendingPayments': 0.0,
        'completedOrders': 0,
        'deliveredOrders': 0,
      };
    }
  }

  static Future<void> refreshCustomers(String tailorId) async {
    try {
      _log('Force refreshing customers for $tailorId');
      await Future.delayed(const Duration(milliseconds: 200));
      _notifyCustomerListeners(tailorId);
    } catch (e) {
      _log('Error refreshing customers: $e', level: 'ERROR');
    }
  }

  // Enhanced cleanup method
  static void dispose() {
    try {
      _log('Disposing all streams');
      for (var controller in _customerControllers.values) {
        if (!controller.isClosed) {
          controller.close();
        }
      }
      for (var controller in _orderControllers.values) {
        if (!controller.isClosed) {
          controller.close();
        }
      }
      for (var controller in _paymentControllers.values) {
        if (!controller.isClosed) {
          controller.close();
        }
      }
      _customerControllers.clear();
      _orderControllers.clear();
      _paymentControllers.clear();
      _isInitialized = false; // Reset initialization flag
      _log('All streams disposed successfully');
    } catch (e) {
      _log('Error during disposal: $e', level: 'ERROR');
    }
  }

  static void debugPrintState(String tailorId) {
    _log('=== Debug State ===', level: 'DEBUG');
    _log('TailorId: $tailorId', level: 'DEBUG');
    _log('Customers: ${_mockCustomers[tailorId]?.length ?? 0}', level: 'DEBUG');
    _log('Orders: ${_mockOrders[tailorId]?.length ?? 0}', level: 'DEBUG');
    _log('Initialized: $_isInitialized', level: 'DEBUG');

    if (_mockCustomers.containsKey(tailorId)) {
      _log('Customer List:', level: 'DEBUG');
      for (var customer in _mockCustomers[tailorId]!) {
        _log('  - ${customer.name} (${customer.id})', level: 'DEBUG');
      }
    }
    _log('==================', level: 'DEBUG');
  }
}
