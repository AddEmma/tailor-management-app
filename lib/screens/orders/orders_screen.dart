import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../services/firebase_service.dart';
import '../../models/models.dart';
import 'add_order_screen.dart';
import 'order_detail_screen.dart';
import '../../utils/constants.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  _OrdersScreenState createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late TabController _tabController;
  final List<OrderStatus> _statusTabs = [
    OrderStatus.pending,
    OrderStatus.inProgress,
    OrderStatus.completed,
    OrderStatus.delivered,
  ];

  List<TailorOrder> _allOrders = [];
  bool _isLoading = true;
  String? _error;
  String? _currentTailorId;
  StreamSubscription<List<TailorOrder>>? _ordersSubscription;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _statusTabs.length, vsync: this);
    WidgetsBinding.instance.addObserver(this);

    // Load orders after the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadOrders();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tabController.dispose();
    _ordersSubscription?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Refresh orders when app comes back to foreground
      _loadOrders();
    }
  }

  Future<void> _loadOrders() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final tailorId = authProvider.user?.uid;

    if (tailorId == null) {
      setState(() {
        _isLoading = false;
        _error = 'No authenticated user';
      });
      return;
    }

    // Cancel existing subscription if user changed
    if (tailorId != _currentTailorId) {
      _ordersSubscription?.cancel();
      _ordersSubscription = null;

      setState(() {
        _isLoading = true;
        _error = null;
        _currentTailorId = tailorId;
        _allOrders = []; // Clear previous data
      });
    }

    // If we already have a subscription for this user, don't create another one
    if (_ordersSubscription != null && tailorId == _currentTailorId) {
      return;
    }

    try {
      print('OrdersScreen: Starting to listen to orders for $tailorId');

      _ordersSubscription = FirebaseService.getOrders(tailorId).listen(
        (orders) {
          print('OrdersScreen: Received ${orders.length} orders');
          if (mounted) {
            setState(() {
              _allOrders = orders;
              _isLoading = false;
              _error = null;
            });
          }
        },
        onError: (error) {
          print('OrdersScreen: Error receiving orders: $error');
          if (mounted) {
            setState(() {
              _isLoading = false;
              _error = error.toString();
            });
          }
        },
      );
    } catch (e) {
      print('OrdersScreen: Exception setting up stream: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final tailorId = authProvider.user?.uid;

    // Check if user changed
    if (tailorId != _currentTailorId && tailorId != null) {
      Future.microtask(() => _loadOrders());
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Orders',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
        ),
        elevation: 4,
        shadowColor: Colors.black26,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.indigo, Colors.indigo.shade700],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            tooltip: 'Refresh Orders',
            onPressed: () {
              _ordersSubscription?.cancel();
              _ordersSubscription = null;
              _loadOrders();
            },
          ),
          IconButton(
            icon: Icon(Icons.filter_list),
            tooltip: 'Filter Orders',
            onPressed: () {
              _showFilterDialog();
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withOpacity(0.6),
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          indicatorSize: TabBarIndicatorSize.label,
          labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          unselectedLabelStyle: TextStyle(fontWeight: FontWeight.normal, fontSize: 14),
          tabs: _statusTabs.map((status) {
            final count = _getOrderCountForStatus(status);
            return Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_getStatusDisplayName(status)),
                  if (count > 0) ...[
                    SizedBox(width: 8),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white.withOpacity(0.3)),
                      ),
                      constraints: BoxConstraints(minWidth: 20),
                      child: Text(
                        count.toString(),
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ],
              ),
            );
          }).toList(),
        ),
      ),
      body: tailorId == null
          ? Center(child: Text('Please login to view orders'))
          : _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddOrderScreen()),
          );
          // No need to manually reload as the stream will update automatically
        },
        child: Icon(Icons.add),
        backgroundColor: Colors.indigo,
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading orders...'),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error, size: 64, color: Colors.red),
            SizedBox(height: 16),
            Text('Error loading orders'),
            SizedBox(height: 8),
            Text(
              _error!,
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                _ordersSubscription?.cancel();
                _ordersSubscription = null;
                _loadOrders();
              },
              child: Text('Retry'),
            ),
          ],
        ),
      );
    }

    return TabBarView(
      controller: _tabController,
      children: _statusTabs.map((status) {
        return _buildOrdersList(status);
      }).toList(),
    );
  }

  Widget _buildOrdersList(OrderStatus status) {
    final filteredOrders = _allOrders
        .where((order) => order.status == status)
        .toList();

    if (filteredOrders.isEmpty) {
      return _buildEmptyState(status);
    }

    return RefreshIndicator(
      onRefresh: () async {
        _ordersSubscription?.cancel();
        _ordersSubscription = null;
        await _loadOrders();
      },
      child: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: filteredOrders.length,
        itemBuilder: (context, index) {
          final order = filteredOrders[index];
          return _buildOrderCard(order);
        },
      ),
    );
  }

  Widget _buildEmptyState(OrderStatus status) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment_outlined, size: 64, color: Colors.grey[400]),
          SizedBox(height: 16),
          Text(
            'No ${_getStatusDisplayName(status).toLowerCase()} orders',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          SizedBox(height: 8),
          Text(
            'Orders with ${_getStatusDisplayName(status).toLowerCase()} status will appear here',
            style: TextStyle(color: Colors.grey[500]),
          ),
          if (status == OrderStatus.pending) ...[
            SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AddOrderScreen()),
                );
                // No need to manually reload as the stream will update automatically
              },
              icon: Icon(Icons.add),
              label: Text('Create Order'),
            ),
          ],
        ],
      ),
    );
  }

  int _getOrderCountForStatus(OrderStatus status) {
    return _allOrders.where((order) => order.status == status).length;
  }

  Widget _buildOrderCard(TailorOrder order) {
    final isOverdue =
        order.deliveryDate.isBefore(DateTime.now()) &&
        order.status != OrderStatus.delivered &&
        order.status != OrderStatus.completed;
    final statusColor = _getStatusColor(order.status);
    final daysUntilDelivery = order.deliveryDate
        .difference(DateTime.now())
        .inDays;

    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: isOverdue ? 3 : 1,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: isOverdue
              ? Border.all(color: Colors.red.withOpacity(0.5), width: 2)
              : null,
        ),
        child: ListTile(
          contentPadding: EdgeInsets.all(16),
          leading: Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getStatusIcon(order.status),
              color: statusColor,
              size: 24,
            ),
          ),
          title: Text(
            order.customerName,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 4),
              Text(
                '${order.style} - ${order.fabric}',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                ),
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                  SizedBox(width: 4),
                  Text(
                    'Due: ${DateFormat('MMM dd').format(order.deliveryDate)}',
                    style: TextStyle(
                      color: isOverdue ? Colors.red : Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                  if (isOverdue) ...[
                    SizedBox(width: 8),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'OVERDUE',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 9,
                        ),
                      ),
                    ),
                  ] else if (daysUntilDelivery <= 3 &&
                      daysUntilDelivery >= 0) ...[
                    SizedBox(width: 8),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
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
              SizedBox(height: 4),
              Wrap(
                spacing: 16,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    '${AppConstants.currencySymbol} ${order.price.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: order.isFullyPaid
                          ? Colors.green.withOpacity(0.1)
                          : Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      order.isFullyPaid
                          ? 'Paid'
                          : 'Balance: ${AppConstants.currencySymbol} ${order.balanceAmount.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: order.isFullyPaid ? Colors.green : Colors.orange,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          trailing: PopupMenuButton(
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'view',
                child: ListTile(
                  leading: Icon(Icons.visibility),
                  title: Text('View Details'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 'edit',
                child: ListTile(
                  leading: Icon(Icons.edit),
                  title: Text('Edit'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 'status',
                child: ListTile(
                  leading: Icon(Icons.update),
                  title: Text('Update Status'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: ListTile(
                  leading: Icon(Icons.delete, color: Colors.red),
                  title: Text('Delete', style: TextStyle(color: Colors.red)),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
            onSelected: (value) async {
              switch (value) {
                case 'view':
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => OrderDetailScreen(order: order),
                    ),
                  );
                  break;
                case 'edit':
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddOrderScreen(order: order),
                    ),
                  );
                  // No need to manually reload as the stream will update automatically
                  break;
                case 'status':
                  _showStatusUpdateDialog(order);
                  break;
                case 'delete':
                  _showDeleteDialog(order);
                  break;
              }
            },
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => OrderDetailScreen(order: order),
              ),
            );
          },
          isThreeLine: true,
        ),
      ),
    );
  }

  void _showStatusUpdateDialog(TailorOrder order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Update Order Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: OrderStatus.values.map((status) {
            return RadioListTile<OrderStatus>(
              title: Text(_getStatusDisplayName(status)),
              value: status,
              groupValue: order.status,
              onChanged: (OrderStatus? value) async {
                if (value != null) {
                  try {
                    final updatedOrder = TailorOrder(
                      id: order.id,
                      customerId: order.customerId,
                      customerName: order.customerName,
                      style: order.style,
                      fabric: order.fabric,
                      price: order.price,
                      paidAmount: order.paidAmount,
                      deliveryDate: order.deliveryDate,
                      materialBroughtDate: order.materialBroughtDate,
                      createdAt: order.createdAt,
                      status: value,
                      tailorId: order.tailorId,
                      notes: order.notes,
                    );

                    await FirebaseService.updateOrder(updatedOrder);
                    Navigator.pop(context);

                    // No need to manually update state - stream will handle it

                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Order status updated successfully'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } catch (e) {
                    Navigator.pop(context);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error updating order status'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showDeleteDialog(TailorOrder order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Order'),
        content: Text(
          'Are you sure you want to delete this order for ${order.customerName}? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await FirebaseService.deleteOrder(order.id, order.tailorId);
                Navigator.pop(context);

                // No need to manually update state - stream will handle it

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Order deleted successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                Navigator.pop(context);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error deleting order'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Filter Orders'),
        content: Text('Filter functionality will be implemented here'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  String _getStatusDisplayName(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.inProgress:
        return 'In Progress';
      case OrderStatus.completed:
        return 'Completed';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.cancelled:
        return 'Cancelled';
    }
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Colors.orange;
      case OrderStatus.inProgress:
        return Colors.blue;
      case OrderStatus.completed:
        return Colors.green;
      case OrderStatus.delivered:
        return Colors.purple;
      case OrderStatus.cancelled:
        return Colors.red;
    }
  }

  IconData _getStatusIcon(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Icons.schedule;
      case OrderStatus.inProgress:
        return Icons.build;
      case OrderStatus.completed:
        return Icons.check_circle;
      case OrderStatus.delivered:
        return Icons.local_shipping;
      case OrderStatus.cancelled:
        return Icons.cancel;
    }
  }
}
