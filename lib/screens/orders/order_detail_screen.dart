import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../models/models.dart';
import '../../services/firebase_service.dart';
import '../../utils/constants.dart';

import 'add_order_screen.dart';

class OrderDetailScreen extends StatefulWidget {
  final TailorOrder order;

  const OrderDetailScreen({super.key, required this.order});

  @override
  OrderDetailScreenState createState() => OrderDetailScreenState();
}

class OrderDetailScreenState extends State<OrderDetailScreen> {
  late TailorOrder _currentOrder;
  final _paymentAmountController = TextEditingController();
  final _paymentNotesController = TextEditingController();
  String _paymentMethod = 'Cash';
  bool _isProcessingPayment = false;

  @override
  void initState() {
    super.initState();
    _currentOrder = widget.order;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<TailorOrder>>(
      stream: FirebaseService.getOrders(_currentOrder.tailorId),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final updatedOrder = snapshot.data!.firstWhere(
            (o) => o.id == _currentOrder.id,
            orElse: () => _currentOrder,
          );
          _currentOrder = updatedOrder;
        }

        return Scaffold(
          appBar: AppBar(
            title: Text('Order Details'),
            actions: [
              PopupMenuButton<String>(
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'edit',
                    child: ListTile(
                      leading: Icon(Icons.edit),
                      title: Text('Edit Order'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: ListTile(
                      leading: Icon(Icons.delete, color: Colors.red),
                      title: Text('Delete Order', style: TextStyle(color: Colors.red)),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
                onSelected: (value) {
                  if (value == 'edit') {
                    _editOrder();
                  } else if (value == 'delete') {
                    _showDeleteConfirmation();
                  }
                },
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Order Summary Card
                Card(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Order Summary',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: _getStatusColor(_currentOrder.status).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                _getStatusDisplayName(_currentOrder.status),
                                style: TextStyle(
                                  color: _getStatusColor(_currentOrder.status),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 20),
                        
                        _buildDetailRow('Customer:', _currentOrder.customerName),
                        _buildDetailRow('Style:', _currentOrder.style),
                        _buildDetailRow('Fabric:', _currentOrder.fabric),
                        _buildDetailRow('Material Date:', DateFormat('MMM dd, yyyy').format(_currentOrder.materialBroughtDate)),
                        _buildDetailRow('Collection Date:', DateFormat('MMM dd, yyyy').format(_currentOrder.deliveryDate)),
                        _buildDetailRow('Order Date:', DateFormat('MMM dd, yyyy').format(_currentOrder.createdAt)),
                        if (_currentOrder.notes != null && _currentOrder.notes!.isNotEmpty)
                          _buildDetailRow('Notes:', _currentOrder.notes!),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 16),
                
                // Payment Summary Card
                Card(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Payment Chart',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 16),
                        
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Total Price:', style: TextStyle(fontSize: 16)),
                            Text(
                              '${AppConstants.currencySymbol} ${_currentOrder.price.toStringAsFixed(2)}',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Advanced Payment:', style: TextStyle(fontSize: 16)),
                            Text(
                              '${AppConstants.currencySymbol} ${_currentOrder.paidAmount.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 16, 
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        
                        Divider(),
                        SizedBox(height: 8),
                        
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Balance:',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              '${AppConstants.currencySymbol} ${_currentOrder.balanceAmount.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: _currentOrder.isFullyPaid ? Colors.green : Colors.red,
                              ),
                            ),
                          ],
                        ),
                        
                        if (_currentOrder.isFullyPaid) ...[
                          SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.check_circle, color: Colors.green),
                                SizedBox(width: 8),
                                Text(
                                  'Fully Paid',
                                  style: TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ] else ...[
                          SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () => _showAddPaymentDialog(),
                              icon: Icon(Icons.payment),
                              label: Text('Add Payment'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 16),
                
                // Payment History Card
                Card(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Payment History',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 16),
                        
                        StreamBuilder<List<Payment>>(
                          stream: FirebaseService.getPayments(_currentOrder.id),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return Center(child: Padding(
                                padding: const EdgeInsets.all(20.0),
                                child: CircularProgressIndicator(),
                              ));
                            }
                            
                            final payments = snapshot.data ?? [];
                            
                            if (payments.isEmpty) {
                              return Center(
                                child: Padding(
                                  padding: EdgeInsets.all(24),
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.payment_outlined,
                                        size: 48,
                                        color: Colors.grey[400],
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        'No payments recorded',
                                        style: TextStyle(color: Colors.grey[600]),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }
                            
                            return ListView.separated(
                              shrinkWrap: true,
                              physics: NeverScrollableScrollPhysics(),
                              itemCount: payments.length,
                              separatorBuilder: (context, index) => Divider(),
                              itemBuilder: (context, index) {
                                final payment = payments[index];
                                return ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: Container(
                                    padding: EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(Icons.payment, color: Colors.green),
                                  ),
                                  title: Text(
                                    '${AppConstants.currencySymbol} ${payment.amount.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(payment.method),
                                      Text(
                                        DateFormat('MMM dd, yyyy - hh:mm a').format(payment.paymentDate),
                                        style: TextStyle(fontSize: 12),
                                      ),
                                      if (payment.notes != null && payment.notes!.isNotEmpty)
                                        Text(
                                          payment.notes!,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                    ],
                                  ),
                                  isThreeLine: payment.notes != null && payment.notes!.isNotEmpty,
                                );
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddPaymentDialog() {
    _paymentMethod = 'Cash'; // Reset method
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text('Add Payment'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _paymentAmountController,
                    decoration: InputDecoration(
                      labelText: 'Payment Amount',
                      prefixIcon: Icon(Icons.payments_outlined),
                      prefixText: '${AppConstants.currencySymbol} ',
                      hintText: 'Max: ${AppConstants.currencySymbol} ${_currentOrder.balanceAmount.toStringAsFixed(2)}',
                    ),
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                    autofocus: true,
                  ),
                  SizedBox(height: 16),
                  
                  DropdownButtonFormField<String>(
                    value: _paymentMethod,
                    decoration: InputDecoration(
                      labelText: 'Payment Method',
                      prefixIcon: Icon(Icons.payment),
                    ),
                    items: ['Cash', 'Credit Card', 'Debit Card', 'Bank Transfer', 'Check', 'Other']
                        .map((method) => DropdownMenuItem(
                              value: method,
                              child: Text(method),
                            ))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() {
                          _paymentMethod = value;
                        });
                      }
                    },
                  ),
                  SizedBox(height: 16),
                  
                  TextFormField(
                    controller: _paymentNotesController,
                    decoration: InputDecoration(
                      labelText: 'Notes (Optional)',
                      prefixIcon: Icon(Icons.notes),
                      hintText: 'Payment reference, notes...',
                    ),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _clearPaymentForm();
                },
                child: Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: _isProcessingPayment ? null : () => _processPayment(setDialogState),
                child: _isProcessingPayment
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text('Add Payment'),
              ),
            ],
          );
        }
      ),
    );
  }

  Future<void> _processPayment(StateSetter setDialogState) async {
    final amountText = _paymentAmountController.text.trim();
    if (amountText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter payment amount')),
      );
      return;
    }

    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }

    if (amount > _currentOrder.balanceAmount) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Amount cannot exceed balance due')),
      );
      return;
    }

    setDialogState(() {
      _isProcessingPayment = true;
    });

    try {
      final payment = Payment(
        id: Uuid().v4(),
        orderId: _currentOrder.id,
        amount: amount,
        paymentDate: DateTime.now(),
        method: _paymentMethod,
        notes: _paymentNotesController.text.trim().isEmpty 
            ? null 
            : _paymentNotesController.text.trim(),
      );

      await FirebaseService.addPayment(payment);
      
      if (mounted) {
        Navigator.pop(context);
        _clearPaymentForm();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment added successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding payment: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setDialogState(() {
          _isProcessingPayment = false;
        });
      }
    }
  }

  void _editOrder() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddOrderScreen(order: _currentOrder),
      ),
    );
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Order'),
        content: Text('Are you sure you want to delete this order? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: _deleteOrder,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteOrder() async {
    try {
      await FirebaseService.deleteOrder(_currentOrder.id, _currentOrder.tailorId);
      if (mounted) {
        Navigator.pop(context); // Close dialog
        Navigator.pop(context); // Go back to orders list
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Order deleted successfully'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting order: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _clearPaymentForm() {
    _paymentAmountController.clear();
    _paymentNotesController.clear();
    _paymentMethod = 'Cash';
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

  @override
  void dispose() {
    _paymentAmountController.dispose();
    _paymentNotesController.dispose();
    super.dispose();
  }
}
