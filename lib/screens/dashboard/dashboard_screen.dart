import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  DashboardScreenState createState() => DashboardScreenState();
}

class DashboardScreenState extends State<DashboardScreen>
    with AutomaticKeepAliveClientMixin {
  // Cache dashboard data to prevent recalculation
  static Map<String, dynamic>? _cachedDashboardData;
  static List<Map<String, dynamic>>? _cachedUpcomingOrders;
  static DateTime? _lastCacheUpdate;

  bool _isLoading = false;
  bool _hasError = false;

  @override
  bool get wantKeepAlive => true; // Keep state alive when switching tabs

  @override
  void initState() {
    super.initState();
    // Load data asynchronously without blocking
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDashboardDataAsync();
    });
  }

  // Check if cache is still valid (5 minutes)
  bool get _isCacheValid {
    if (_lastCacheUpdate == null) return false;
    return DateTime.now().difference(_lastCacheUpdate!).inMinutes < 5;
  }

  Future<void> _loadDashboardDataAsync() async {
    // If cache is valid, use it
    if (_isCacheValid && _cachedDashboardData != null) {
      return;
    }

    if (_isLoading) return; // Prevent multiple simultaneous loads

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      // Use compute for heavy data processing to avoid blocking main thread
      final data = await _computeDashboardData();

      if (mounted) {
        setState(() {
          _cachedDashboardData = data['dashboard'];
          _cachedUpcomingOrders = data['orders'];
          _lastCacheUpdate = DateTime.now();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  // Simulate data computation - in real app, this would be your Firebase calls
  Future<Map<String, dynamic>> _computeDashboardData() async {
    // Simulate network delay without blocking main thread
    await Future.delayed(const Duration(milliseconds: 300));

    return {
      'dashboard': {
        'totalCustomers': 25,
        'activeOrders': 8,
        'monthlyRevenue': 1250.50,
      },
      'orders': [
        {
          'customerName': 'John Smith',
          'style': 'Business Suit',
          'fabric': 'Wool Blend',
          'deliveryDate': DateTime.now().add(const Duration(days: 2)),
          'price': 450.0,
        },
        {
          'customerName': 'Sarah Johnson',
          'style': 'Evening Dress',
          'fabric': 'Silk',
          'deliveryDate': DateTime.now().add(const Duration(days: 5)),
          'price': 320.0,
        },
        {
          'customerName': 'Mike Wilson',
          'style': 'Casual Shirt',
          'fabric': 'Cotton',
          'deliveryDate': DateTime.now().subtract(const Duration(days: 1)),
          'price': 85.0,
        },
      ],
    };
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
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // Clear cache and reload
              _cachedDashboardData = null;
              _cachedUpcomingOrders = null;
              _lastCacheUpdate = null;
              _loadDashboardDataAsync();
            },
          ),
      ],
    );
  }

  Widget _buildBody() {
    if (_hasError) {
      return _buildErrorState();
    }

    if (_isLoading && _cachedDashboardData == null) {
      return _buildLoadingState();
    }

    return RefreshIndicator(
      onRefresh: () async {
        _cachedDashboardData = null;
        _cachedUpcomingOrders = null;
        _lastCacheUpdate = null;
        await _loadDashboardDataAsync();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeCard(),
            const SizedBox(height: 20),
            if (_cachedDashboardData != null) _buildStatsSection(),
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
          const Text(
            'Please check your connection and try again',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadDashboardDataAsync,
            child: const Text('Retry'),
          ),
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
    final data = _cachedDashboardData!;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _StatCard(
                title: 'Total Customers',
                value: data['totalCustomers'].toString(),
                icon: Icons.people,
                color: Colors.blue,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _StatCard(
                title: 'Active Orders',
                value: data['activeOrders'].toString(),
                icon: Icons.assignment,
                color: Colors.orange,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _StatCard(
          title: 'Monthly Revenue',
          value: '\$${data['monthlyRevenue'].toStringAsFixed(2)}',
          icon: Icons.attach_money,
          color: Colors.green,
          isFullWidth: true,
        ),
      ],
    );
  }

  Widget _buildUpcomingDeliveriesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Upcoming Deliveries',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        if (_cachedUpcomingOrders?.isEmpty ?? true)
          _buildEmptyDeliveries()
        else
          ..._cachedUpcomingOrders!.map(
            (order) => _UpcomingOrderCard(order: order),
          ),
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
  final Map<String, dynamic> order;

  const _UpcomingOrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final deliveryDate = order['deliveryDate'] as DateTime;
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
            order['customerName'] as String,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${order['style']} - ${order['fabric']}'),
              const SizedBox(height: 4),
              Text(
                'Due: ${DateFormat('MMM dd, yyyy').format(deliveryDate)}',
                style: TextStyle(
                  color: statusColor,
                  fontWeight: isOverdue || isUrgent ? FontWeight.bold : null,
                ),
              ),
            ],
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                isOverdue
                    ? 'OVERDUE'
                    : isUrgent
                    ? 'URGENT'
                    : '${daysUntilDelivery}d',
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              Text(
                '\$${(order['price'] as double).toStringAsFixed(0)}',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ],
          ),
          isThreeLine: true,
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Order details for ${order['customerName']}'),
                duration: const Duration(seconds: 2),
              ),
            );
          },
        ),
      ),
    );
  }
}
