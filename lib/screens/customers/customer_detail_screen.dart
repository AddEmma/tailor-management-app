import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/models.dart';
import '../../services/firebase_service.dart';
import '../../utils/constants.dart';
import 'add_customer_screen.dart';
import '../orders/add_order_screen.dart';

class CustomerDetailScreen extends StatefulWidget {
  final Customer customer;

  const CustomerDetailScreen({super.key, required this.customer});

  @override
  State<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends State<CustomerDetailScreen> {
  final List<String> _topMeasurementFields = [
    'Across Back',
    'Top Length (Long)',
    'Top Length (Short)',
    'Chest',
    'Sleeve Length (Long)',
    'Sleeve Length (Short)',
    'Around Arm',
    'Vest Length',
    'Neck',
  ];

  final List<String> _downMeasurementFields = [
    'Waist',
    'Trouser Length',
    'Shorts Length',
    'Hip',
    'Tie',
    'Bass',
  ];

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Customer>>(
      stream: FirebaseService.getCustomers(widget.customer.tailorId),
      builder: (context, snapshot) {
        Customer currentCustomer = widget.customer;
        if (snapshot.hasData) {
          try {
            currentCustomer = snapshot.data!.firstWhere((c) => c.id == widget.customer.id);
          } catch (e) {
            // Customer might have been deleted
          }
        }

        return Scaffold(
          backgroundColor: Colors.grey[50],
          body: CustomScrollView(
            slivers: [
              // Custom App Bar with Hero Image
              SliverAppBar(
                expandedHeight: 200,
                floating: false,
                pinned: true,
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    currentCustomer.name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      shadows: [Shadow(color: Colors.black45, blurRadius: 2)],
                    ),
                  ),
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.indigo, Colors.indigo.shade300],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    child: Center(
                      child: Hero(
                        tag: 'customer_avatar_${currentCustomer.id}',
                        child: CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.white.withOpacity(0.2),
                          child: CircleAvatar(
                            radius: 45,
                            backgroundColor: Colors.white,
                            child: Text(
                              currentCustomer.name.isNotEmpty
                                  ? currentCustomer.name[0].toUpperCase()
                                  : '?',
                              style: TextStyle(
                                color: Colors.indigo,
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                actions: [
                  IconButton(
                    icon: Icon(Icons.edit),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              AddCustomerScreen(customer: currentCustomer),
                        ),
                      );
                    },
                  ),
                  PopupMenuButton<String>(
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'edit',
                        child: ListTile(
                          leading: Icon(Icons.edit, color: Colors.blue),
                          title: Text('Edit Customer'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: ListTile(
                          leading: Icon(Icons.delete, color: Colors.red),
                          title: Text(
                            'Delete Customer',
                            style: TextStyle(color: Colors.red),
                          ),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                    onSelected: (value) {
                      if (value == 'edit') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                AddCustomerScreen(customer: currentCustomer),
                          ),
                        );
                      } else if (value == 'delete') {
                        _showDeleteDialog(context, currentCustomer);
                      }
                    },
                  ),
                ],
              ),
    
              // Content
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Customer Info Card
                      Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.person,
                                    color: Colors.indigo,
                                    size: 24,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Contact Information',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.indigo,
                                    ),
                                  ),
                                ],
                              ),
                              Divider(color: Colors.indigo.shade100),
                              SizedBox(height: 16),
    
                              _buildInfoItem(
                                Icons.phone,
                                'Phone Number',
                                currentCustomer.phone,
                                onTap: () {
                                  // Could add phone calling functionality
                                },
                              ),
    
                              if (currentCustomer.email != null &&
                                  currentCustomer.email!.isNotEmpty) ...[
                                SizedBox(height: 16),
                                _buildInfoItem(
                                  Icons.email,
                                  'Email Address',
                                  currentCustomer.email!,
                                  onTap: () {
                                    // Could add email functionality
                                  },
                                ),
                              ],
    
                              SizedBox(height: 16),
                              _buildInfoItem(
                                Icons.calendar_today,
                                'Customer Since',
                                DateFormat(
                                  'MMMM dd, yyyy',
                                ).format(currentCustomer.createdAt),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 16),
    
                      // Quick Stats Card
                      Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: Row(
                            children: [
                              Expanded(
                                child: _buildStatItem(
                                  Icons.straighten,
                                  'Measurements',
                                  '${currentCustomer.measurements.length}',
                                  Colors.blue,
                                ),
                              ),
                              Container(
                                height: 50,
                                width: 1,
                                color: Colors.grey[300],
                              ),
                              Expanded(
                                child: StreamBuilder<List<TailorOrder>>(
                                  stream:
                                      FirebaseService.getOrders(
                                        currentCustomer.tailorId,
                                      ).map(
                                        (orders) => orders
                                            .where(
                                              (order) =>
                                                  order.customerId == currentCustomer.id,
                                            )
                                            .toList(),
                                      ),
                                  builder: (context, snapshot) {
                                    final orderCount = snapshot.data?.length ?? 0;
                                    return _buildStatItem(
                                      Icons.assignment,
                                      'Orders',
                                      '$orderCount',
                                      Colors.green,
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 16),
    
                      // Measurements Card
                      Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.straighten,
                                        color: Colors.indigo,
                                        size: 24,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'Body Measurements',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.indigo,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (currentCustomer.measurements.isNotEmpty)
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.indigo.shade50,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        'in inches',
                                        style: TextStyle(
                                          color: Colors.indigo,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              Divider(color: Colors.indigo.shade100),
                              SizedBox(height: 16),
    
                              if (currentCustomer.measurements.isEmpty)
                                _buildEmptyMeasurements()
                              else
                                _buildMeasurementsGrid(currentCustomer),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 16),
    
                      // Orders Section
                      Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Flexible(
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.assignment,
                                          color: Colors.indigo,
                                          size: 24,
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          'Order History',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.indigo,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              AddOrderScreen(customer: currentCustomer),
                                        ),
                                      );
                                    },
                                    icon: Icon(Icons.add, size: 18),
                                    label: Text('New Order'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.indigo,
                                      foregroundColor: Colors.white,
                                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              Divider(color: Colors.indigo.shade100),
                              SizedBox(height: 16),
    
                              _buildOrdersSection(currentCustomer),
                            ],
                          ),
                        ),
                      ),
    
                      SizedBox(height: 100), // Bottom padding for FAB
                    ],
                  ),
                ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddOrderScreen(customer: currentCustomer),
                ),
              );
            },
            icon: Icon(Icons.add_shopping_cart),
            label: Text('Create Order'),
            backgroundColor: Colors.indigo,
            foregroundColor: Colors.white,
          ),
        );
      }
    );
  }

  Widget _buildInfoItem(
    IconData icon,
    String label,
    String value, {
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.indigo.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 20, color: Colors.indigo),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    value,
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildEmptyMeasurements() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.straighten, size: 48, color: Colors.grey[400]),
            ),
            SizedBox(height: 16),
            Text(
              'No measurements recorded',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Add measurements to create accurate orders',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMeasurementsGrid(Customer customer) {
    // Categorize measurements
    final topMeasurements = customer.measurements.entries
        .where((e) => _topMeasurementFields.contains(e.key))
        .toList();
    final downMeasurements = customer.measurements.entries
        .where((e) => _downMeasurementFields.contains(e.key))
        .toList();
    final otherMeasurements = customer.measurements.entries
        .where((e) => !_topMeasurementFields.contains(e.key) && !_downMeasurementFields.contains(e.key))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (topMeasurements.isNotEmpty) ...[
          _buildMeasurementSection('Top Measurements', topMeasurements),
          SizedBox(height: 16),
        ],
        if (downMeasurements.isNotEmpty) ...[
          _buildMeasurementSection('Down Measurements', downMeasurements),
          SizedBox(height: 16),
        ],
        if (otherMeasurements.isNotEmpty) ...[
          _buildMeasurementSection('Other Measurements', otherMeasurements),
        ],
      ],
    );
  }

  Widget _buildMeasurementSection(String title, List<MapEntry<String, double>> entries) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
          child: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.indigo.shade700,
              fontSize: 14,
            ),
          ),
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            final crossAxisCount = 2;
            final spacing = 12.0;
            final totalSpacing = (crossAxisCount - 1) * spacing;
            final itemWidth = (constraints.maxWidth - totalSpacing) / crossAxisCount;
            const itemHeight = 70.0;
            final childAspectRatio = itemWidth / itemHeight;

            return GridView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                childAspectRatio: childAspectRatio,
                crossAxisSpacing: spacing,
                mainAxisSpacing: spacing,
              ),
              itemCount: entries.length,
              itemBuilder: (context, index) {
                final entry = entries[index];
                return Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.indigo.shade50, Colors.indigo.shade100],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.indigo.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          entry.key,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.indigo.shade700,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(height: 2),
                      Flexible(
                        child: FittedBox(
                          child: Text(
                            '${entry.value}"',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.indigo,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildOrdersSection(Customer customer) {
    return StreamBuilder<List<TailorOrder>>(
      stream: FirebaseService.getOrders(customer.tailorId).map(
        (orders) =>
            orders.where((order) => order.customerId == customer.id).toList(),
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(color: Colors.indigo),
            ),
          );
        }

        final orders = snapshot.data ?? [];

        if (orders.isEmpty) {
          return _buildEmptyOrders();
        }

        return Column(
          children: orders.map((order) => _buildOrderItem(order)).toList(),
        );
      },
    );
  }

  Widget _buildEmptyOrders() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.assignment_outlined,
                size: 48,
                color: Colors.grey[400],
              ),
            ),
            SizedBox(height: 16),
            Text(
              'No orders yet',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Create the first order for this customer',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderItem(TailorOrder order) {
    final statusColor = _getStatusColor(order.status);
    final isOverdue =
        order.deliveryDate.isBefore(DateTime.now()) &&
        order.status != OrderStatus.delivered &&
        order.status != OrderStatus.completed;

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isOverdue ? Colors.red.withOpacity(0.3) : Colors.grey[200]!,
          width: isOverdue ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '${order.style} - ${order.fabric}',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(width: 8),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusColor.withOpacity(0.3)),
                ),
                child: Text(
                  order.status.name.toUpperCase(),
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),

          Row(
            children: [
              Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
              SizedBox(width: 6),
              Text(
                'Due: ${DateFormat('MMM dd, yyyy').format(order.deliveryDate)}',
                style: TextStyle(
                  color: isOverdue ? Colors.red : Colors.grey[600],
                  fontSize: 13,
                  fontWeight: isOverdue ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
              if (isOverdue) ...[
                SizedBox(width: 8),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'OVERDUE',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 9,
                    ),
                  ),
                ),
              ],
            ],
          ),
          SizedBox(height: 8),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total: ${AppConstants.currencySymbol} ${order.price.toStringAsFixed(2)}',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                  fontSize: 15,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: order.isFullyPaid
                      ? Colors.green.shade50
                      : Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  order.isFullyPaid
                      ? 'Paid'
                      : 'Bal: ${AppConstants.currencySymbol} ${order.balanceAmount.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: order.isFullyPaid
                        ? Colors.green.shade700
                        : Colors.orange.shade700,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
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

  void _showDeleteDialog(BuildContext context, Customer customer) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.red, size: 28),
            SizedBox(width: 12),
            Text('Delete Customer'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to delete ${customer.name}?',
              style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
            ),
            SizedBox(height: 8),
            Text(
              'This action cannot be undone and will also delete:',
              style: TextStyle(color: Colors.grey[600]),
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.fiber_manual_record, size: 8, color: Colors.red),
                SizedBox(width: 8),
                Text(
                  'All measurements',
                  style: TextStyle(color: Colors.grey[700]),
                ),
              ],
            ),
            Row(
              children: [
                Icon(Icons.fiber_manual_record, size: 8, color: Colors.red),
                SizedBox(width: 8),
                Text(
                  'All associated orders',
                  style: TextStyle(color: Colors.grey[700]),
                ),
              ],
            ),
            Row(
              children: [
                Icon(Icons.fiber_manual_record, size: 8, color: Colors.red),
                SizedBox(width: 8),
                Text(
                  'Order history',
                  style: TextStyle(color: Colors.grey[700]),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await FirebaseService.deleteCustomer(
                  customer.id,
                  customer.tailorId,
                );
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Go back to customers list
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.white),
                        SizedBox(width: 8),
                        Text('${customer.name} deleted successfully'),
                      ],
                    ),
                    backgroundColor: Colors.green,
                    duration: Duration(seconds: 3),
                  ),
                );
              } catch (e) {
                Navigator.pop(context); // Close dialog
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        Icon(Icons.error, color: Colors.white),
                        SizedBox(width: 8),
                        Text('Error deleting customer'),
                      ],
                    ),
                    backgroundColor: Colors.red,
                    duration: Duration(seconds: 3),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text('Delete'),
          ),
        ],
      ),
    );
  }
}
