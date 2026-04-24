import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../services/firebase_service.dart';
import '../../models/models.dart';
import '../../utils/responsive_utils.dart';
import '../../utils/constants.dart';
import '../orders/order_detail_screen.dart';
import '../../utils/export_utils.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  DashboardScreenState createState() => DashboardScreenState();
}

class DashboardScreenState extends State<DashboardScreen>
    with AutomaticKeepAliveClientMixin {
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;

  // Real data from streams
  List<Customer> _customers = [];
  List<TailorOrder> _orders = [];
  StreamSubscription<List<Customer>>? _customerSubscription;
  StreamSubscription<List<TailorOrder>>? _orderSubscription;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDashboardData();
    });
  }

  @override
  void dispose() {
    _customerSubscription?.cancel();
    _orderSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadDashboardData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;

    if (user == null) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = 'Please log in to view dashboard';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      // Subscribe to real-time customer updates
      _customerSubscription?.cancel();
      _customerSubscription = FirebaseService.getCustomers(user.uid).listen(
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
              _errorMessage = 'Failed to load customers';
              _isLoading = false;
            });
          }
        },
      );

      // Subscribe to real-time order updates
      _orderSubscription?.cancel();
      _orderSubscription = FirebaseService.getOrders(user.uid).listen(
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
              _errorMessage = 'Failed to load orders';
              _isLoading = false;
            });
          }
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = e.toString();
        });
      }
    }
  }

  // Calculate dashboard statistics from real data
  int get _totalCustomers => _customers.length;

  int get _activeOrders => _orders
      .where(
        (order) =>
            order.status == OrderStatus.pending ||
            order.status == OrderStatus.inProgress,
      )
      .length;

  double get _monthlyRevenue {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    return _orders
        .where(
          (order) =>
              order.createdAt.isAfter(startOfMonth) &&
              (order.status == OrderStatus.completed ||
                  order.status == OrderStatus.delivered),
        )
        .fold(0.0, (sum, order) => sum + order.paidAmount);
  }

  List<TailorOrder> get _upcomingOrders {
    final now = DateTime.now();
    final nextWeek = now.add(const Duration(days: 7));
    return _orders
        .where(
          (order) =>
              order.deliveryDate.isAfter(
                now.subtract(const Duration(days: 1)),
              ) &&
              order.deliveryDate.isBefore(nextWeek) &&
              (order.status == OrderStatus.pending ||
                  order.status == OrderStatus.inProgress ||
                  order.status == OrderStatus.completed),
        )
        .toList()
      ..sort((a, b) => a.deliveryDate.compareTo(b.deliveryDate));
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
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
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDashboardData,
            tooltip: 'Refresh',
          ),
        IconButton(
          icon: const Icon(Icons.file_download_outlined),
          onPressed: () async {
            if (_customers.isNotEmpty || _orders.isNotEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Generating Excel file...')),
              );
              try {
                await ExportUtils.exportAllData(
                  customers: _customers,
                  orders: _orders,
                );
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Export failed: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('No data to export')),
              );
            }
          },
          tooltip: 'Export All Data',
        ),
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
      onRefresh: _loadDashboardData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: context.responsivePadding,
        child: ResponsiveCenter(
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
      child: Padding(
        padding: const EdgeInsets.all(24),
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
              _errorMessage ?? 'Please check your connection and try again',
              style: const TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadDashboardData,
              child: const Text('Retry'),
            ),
          ],
        ),
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
                  radius: 24,
                  child: Text(
                    userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
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
    final isWide = !Breakpoints.isMobile(context);

    // Build stat cards
    final statCards = [
      _StatCard(
        title: 'Total Customers',
        value: _totalCustomers.toString(),
        icon: Icons.people,
        color: Colors.blue,
      ),
      _StatCard(
        title: 'Active Orders',
        value: _activeOrders.toString(),
        icon: Icons.assignment,
        color: Colors.orange,
      ),
      _StatCard(
        title: 'Monthly Revenue',
        value: '${AppConstants.currencySymbol} ${_monthlyRevenue.toStringAsFixed(2)}',
        icon: Icons.payments,
        color: Colors.green,
      ),
    ];

    // Use responsive grid for tablet/desktop
    if (isWide) {
      return Row(
        children: statCards
            .map(
              (card) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: card,
                ),
              ),
            )
            .toList(),
      );
    }

    // Stack layout for mobile
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: statCards[0]),
            const SizedBox(width: 16),
            Expanded(child: statCards[1]),
          ],
        ),
        const SizedBox(height: 16),
        _StatCard(
          title: 'Monthly Revenue',
          value: '${AppConstants.currencySymbol} ${_monthlyRevenue.toStringAsFixed(2)}',
          icon: Icons.payments,
          color: Colors.green,
          isFullWidth: true,
        ),
      ],
    );
  }

  Widget _buildUpcomingDeliveriesSection() {
    final upcomingOrders = _upcomingOrders;

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
            if (upcomingOrders.isNotEmpty)
              Text(
                '${upcomingOrders.length} orders',
                style: TextStyle(color: Colors.grey[600]),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (upcomingOrders.isEmpty)
          _buildEmptyDeliveries()
        else
          ...upcomingOrders.map((order) => _UpcomingOrderCard(order: order)),
      ],
    );
  }

  Widget _buildEmptyDeliveries() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.check_circle_outline,
                size: 64,
                color: Colors.grey[400],
              ),
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
          child: Icon(icon, color: color, size: 28),
        ),
        const SizedBox(height: 12),
        Text(
          value,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
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
    final daysUntilDelivery = order.deliveryDate
        .difference(DateTime.now())
        .inDays;
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
              Text(
                'Due: ${DateFormat('MMM dd, yyyy').format(order.deliveryDate)}',
                style: TextStyle(
                  color: statusColor,
                  fontWeight: isOverdue || isUrgent ? FontWeight.bold : null,
                ),
              ),
            ],
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isOverdue
                      ? 'OVERDUE'
                      : isUrgent
                      ? 'URGENT'
                      : '${daysUntilDelivery}d',
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${AppConstants.currencySymbol} ${order.price.toStringAsFixed(0)}',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ],
          ),
          isThreeLine: true,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => OrderDetailScreen(order: order),
              ),
            );
          },
        ),
      ),
    );
  }
}
