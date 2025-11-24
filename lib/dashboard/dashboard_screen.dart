import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import '../../providers/auth_provider.dart';
import '../../services/firebase_service.dart';
import '../../models/models.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  DashboardScreenState createState() => DashboardScreenState();
}

class DashboardScreenState extends State<DashboardScreen>
    with AutomaticKeepAliveClientMixin {
  StreamSubscription<List<Customer>>? _customersSubscription;
  StreamSubscription<List<TailorOrder>>? _ordersSubscription;

  List<Customer> _customers = [];
  List<TailorOrder> _orders = [];

  bool _isLoading = false;
  bool _hasError = false;
  String? _error;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeStreams();
    });
  }

  @override
  void dispose() {
    _customersSubscription?.cancel();
    _ordersSubscription?.cancel();
    super.dispose();
  }

  void _initializeStreams() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final tailorId = authProvider.user?.uid;

    if (tailorId == null) {
      setState(() {
        _hasError = true;
        _error = 'No authenticated user';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    // Listen to customers stream
    _customersSubscription = FirebaseService.getCustomers(tailorId).listen(
      (customers) {
        if (mounted) {
          setState(() {
            _customers = customers;
            _isLoading = false;
          });
        }
      },
      onError: (error) {
        if (mounted) {
          setState(() {
            _hasError = true;
            _error = error.toString();
            _isLoading = false;
          });
        }
      },
    );

    // Listen to orders stream
    _ordersSubscription = FirebaseService.getOrders(tailorId).listen(
      (orders) {
        if (mounted) {
          setState(() {
            _orders = orders;
            _isLoading = false;
          });
        }
      },
      onError: (error) {
        if (mounted) {
          setState(() {
            _hasError = true;
            _error = error.toString();
            _isLoading = false;
          });
        }
      },
    );
  }

  void _refreshData() {
    _customersSubscription?.cancel();
    _ordersSubscription?.cancel();
    _initializeStreams();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

    return Scaffold(appBar: _buildAppBar(), body: _buildBody());
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('Dashboard'),
      backgroundColor: Colors.indigo,
      foregroundColor: Colors.white,
      elevation: 0,
      actions: [
        if (!_isLoading)
          IconButton(icon: const Icon(Icons.refresh), onPressed: _refreshData),
      ],
    );
  }

  Widget _buildBody() {
    if (_hasError) {
      return _buildErrorState();
    }

    if (_isLoading && _customers.isEmpty && _orders.isEmpty) {
      return _buildLoadingState();
    }

    return RefreshIndicator(
      onRefresh: () async {
        _refreshData();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeCard(),
            const SizedBox(height: 20),
            _buildStatsSection(),
            const SizedBox(height: 24),
            _buildUpcomingDeliveriesSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(strokeWidth: 2, color: Colors.indigo),
          SizedBox(height: 16),
          Text('Loading dashboard...', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          const Text(
            'Failed to load dashboard',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            _error ?? 'Please check your connection and try again',
            style: const TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(onPressed: _refreshData, child: const Text('Retry')),
        ],
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final userName =
            authProvider.user?.displayName?.split(' ').first ??
            authProvider.user?.email?.split('@').first ??
            'User';

        return Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.indigo,
                  child: Text(
                    userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Welcome back!',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(userName, style: TextStyle(color: Colors.grey[600])),
                    ],
                  ),
                ),
                Text(
                  DateFormat('MMM dd, yyyy').format(DateTime.now()),
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatsSection() {
    // Calculate active orders (not delivered or cancelled)
    final activeOrders = _orders
        .where(
          (order) =>
              order.status != OrderStatus.delivered &&
              order.status != OrderStatus.cancelled,
        )
        .length;

    // Calculate monthly revenue (current month's completed/delivered orders)
    final now = DateTime.now();
    final monthlyRevenue = _orders
        .where((order) {
          return (order.status == OrderStatus.completed ||
                  order.status == OrderStatus.delivered) &&
              order.deliveryDate.year == now.year &&
              order.deliveryDate.month == now.month;
        })
        .fold<double>(0, (sum, order) => sum + order.price);

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _StatCard(
                title: 'Total Customers',
                value: _customers.length.toString(),
                icon: Icons.people,
                color: Colors.blue,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _StatCard(
                title: 'Active Orders',
                value: activeOrders.toString(),
                icon: Icons.assignment,
                color: Colors.orange,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _StatCard(
          title: 'Monthly Revenue',
          value: '\$${monthlyRevenue.toStringAsFixed(2)}',
          icon: Icons.attach_money,
          color: Colors.green,
          isFullWidth: true,
        ),
      ],
    );
  }

  Widget _buildUpcomingDeliveriesSection() {
    // Get upcoming orders (not delivered/cancelled) sorted by delivery date
    final upcomingOrders =
        _orders
            .where(
              (order) =>
                  order.status != OrderStatus.delivered &&
                  order.status != OrderStatus.cancelled,
            )
            .toList()
          ..sort((a, b) => a.deliveryDate.compareTo(b.deliveryDate));

    // Take only the next 5 upcoming orders
    final displayOrders = upcomingOrders.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Upcoming Deliveries',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            if (upcomingOrders.length > 5)
              Text(
                '+${upcomingOrders.length - 5} more',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (displayOrders.isEmpty)
          _buildEmptyDeliveries()
        else
          ...displayOrders.map((order) => _UpcomingOrderCard(order: order)),
      ],
    );
  }

  Widget _buildEmptyDeliveries() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(Icons.check_circle_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No upcoming deliveries',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            Text(
              'You\'re all caught up!',
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }
}

// Stateless widget for better performance
class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final bool isFullWidth;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.isFullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: isFullWidth ? _buildFullWidthLayout() : _buildCompactLayout(),
      ),
    );
  }

  Widget _buildFullWidthLayout() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCompactLayout() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 32),
        ),
        const SizedBox(height: 12),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          title,
          style: TextStyle(color: Colors.grey[600], fontSize: 12),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

// Optimized upcoming order card
class _UpcomingOrderCard extends StatelessWidget {
  final TailorOrder order;

  const _UpcomingOrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final deliveryDate = order.deliveryDate;
    final daysUntilDelivery = deliveryDate.difference(DateTime.now()).inDays;
    final isOverdue = daysUntilDelivery < 0;
    final isUrgent = daysUntilDelivery <= 2 && daysUntilDelivery >= 0;

    final statusColor = isOverdue
        ? Colors.red
        : isUrgent
        ? Colors.orange
        : Colors.blue;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: 1,
        child: ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.schedule, color: statusColor),
          ),
          title: Text(
            order.customerName,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${order.style} - ${order.fabric}'),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    'Due: ${DateFormat('MMM dd, yyyy').format(deliveryDate)}',
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: isOverdue || isUrgent
                          ? FontWeight.bold
                          : null,
                      fontSize: 12,
                    ),
                  ),
                  if (isOverdue) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'OVERDUE',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 9,
                        ),
                      ),
                    ),
                  ] else if (isUrgent) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'URGENT',
                        style: TextStyle(
                          color: Colors.orange,
                          fontWeight: FontWeight.bold,
                          fontSize: 9,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                isOverdue
                    ? '${daysUntilDelivery.abs()}d late'
                    : isUrgent
                    ? '${daysUntilDelivery}d left'
                    : '${daysUntilDelivery}d',
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '\$${order.price.toStringAsFixed(0)}',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ],
          ),
          isThreeLine: true,
          onTap: () {
            // Navigate to order details if needed
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Order details for ${order.customerName}'),
                duration: const Duration(seconds: 2),
              ),
            );
          },
        ),
      ),
    );
  }
}
