import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:form_field_validator/form_field_validator.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../services/firebase_service.dart';
import '../../models/models.dart';
import '../../utils/constants.dart';

class AddOrderScreen extends StatefulWidget {
  final TailorOrder? order;
  final Customer? customer;

  const AddOrderScreen({super.key, this.order, this.customer});

  @override
  _AddOrderScreenState createState() => _AddOrderScreenState();
}

class _AddOrderScreenState extends State<AddOrderScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _styleController;
  late TextEditingController _fabricController;
  late TextEditingController _priceController;
  late TextEditingController _paidAmountController;
  late TextEditingController _notesController;
  
  Customer? _selectedCustomer;
  DateTime _selectedDeliveryDate = DateTime.now().add(Duration(days: 7));
  OrderStatus _selectedStatus = OrderStatus.pending;
  bool _isLoading = false;
  List<Customer> _customers = [];

  @override
  void initState() {
    super.initState();
    _selectedCustomer = widget.customer;
    
    _styleController = TextEditingController(text: widget.order?.style ?? '');
    _fabricController = TextEditingController(text: widget.order?.fabric ?? '');
    _priceController = TextEditingController(text: widget.order?.price.toString() ?? '');
    _paidAmountController = TextEditingController(text: widget.order?.paidAmount.toString() ?? '0');
    _notesController = TextEditingController(text: widget.order?.notes ?? '');
    
    if (widget.order != null) {
      _selectedDeliveryDate = widget.order!.deliveryDate;
      _selectedStatus = widget.order!.status;
    }
    
    _loadCustomers();
  }

  Future<void> _loadCustomers() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final tailorId = authProvider.user?.uid;
    
    if (tailorId != null) {
      FirebaseService.getCustomers(tailorId).listen((customers) {
        setState(() {
          _customers = customers;
          if (widget.order != null && _selectedCustomer == null) {
            _selectedCustomer = customers.firstWhere(
              (c) => c.id == widget.order!.customerId,
              orElse: () => customers.first,
            );
          }
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.order != null;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Order' : 'New Order'),
        actions: [
          if (_isLoading)
            Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Customer Selection
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Customer',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 16),
                      
                      if (widget.customer != null)
                        Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.indigo.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.indigo.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: Colors.indigo,
                                child: Text(
                                  widget.customer!.name[0].toUpperCase(),
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.customer!.name,
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      widget.customer!.phone,
                                      style: TextStyle(color: Colors.grey[600]),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        DropdownButtonFormField<Customer>(
                          value: _selectedCustomer,
                          decoration: InputDecoration(
                            labelText: 'Select Customer *',
                            prefixIcon: Icon(Icons.person),
                          ),
                          items: _customers.map((customer) {
                            return DropdownMenuItem<Customer>(
                              value: customer,
                              child: Text(customer.name),
                            );
                          }).toList(),
                          onChanged: (Customer? value) {
                            setState(() {
                              _selectedCustomer = value;
                            });
                          },
                          validator: (value) {
                            if (value == null) {
                              return 'Please select a customer';
                            }
                            return null;
                          },
                        ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16),
              
              // Order Details
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Order Details',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 16),
                      
                      TextFormField(
                        controller: _styleController,
                        decoration: InputDecoration(
                          labelText: 'Style/Type *',
                          prefixIcon: Icon(Icons.style),
                          hintText: 'e.g., Shirt, Pants, Dress',
                        ),
                        validator: RequiredValidator(errorText: 'Style is required'),
                        textCapitalization: TextCapitalization.words,
                      ),
                      SizedBox(height: 16),
                      
                      TextFormField(
                        controller: _fabricController,
                        decoration: InputDecoration(
                          labelText: 'Fabric *',
                          prefixIcon: Icon(Icons.texture),
                          hintText: 'e.g., Cotton, Silk, Wool',
                        ),
                        validator: RequiredValidator(errorText: 'Fabric is required'),
                        textCapitalization: TextCapitalization.words,
                      ),
                      SizedBox(height: 16),
                      
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _priceController,
                              decoration: InputDecoration(
                                labelText: 'Total Price *',
                                prefixIcon: Icon(Icons.payments_outlined),
                                prefixText: '${AppConstants.currencySymbol} ',
                              ),
                              keyboardType: TextInputType.numberWithOptions(decimal: true),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Price is required';
                                }
                                final price = double.tryParse(value);
                                if (price == null || price <= 0) {
                                  return 'Enter valid price';
                                }
                                return null;
                              },
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _paidAmountController,
                              decoration: InputDecoration(
                                labelText: 'Amount Paid',
                                prefixIcon: Icon(Icons.wallet_outlined),
                                prefixText: '${AppConstants.currencySymbol} ',
                              ),
                              keyboardType: TextInputType.numberWithOptions(decimal: true),
                              validator: (value) {
                                if (value != null && value.isNotEmpty) {
                                  final paidAmount = double.tryParse(value);
                                  final totalPrice = double.tryParse(_priceController.text);
                                  if (paidAmount == null || paidAmount < 0) {
                                    return 'Enter valid amount';
                                  }
                                  if (totalPrice != null && paidAmount > totalPrice) {
                                    return 'Cannot exceed total price';
                                  }
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      
                      // Delivery Date
                      InkWell(
                        onTap: _selectDeliveryDate,
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Delivery Date *',
                            prefixIcon: Icon(Icons.calendar_today),
                          ),
                          child: Text(
                            DateFormat('MMM dd, yyyy').format(_selectedDeliveryDate),
                          ),
                        ),
                      ),
                      SizedBox(height: 16),
                      
                      // Status (only for editing)
                      if (isEditing)
                        DropdownButtonFormField<OrderStatus>(
                          value: _selectedStatus,
                          decoration: InputDecoration(
                            labelText: 'Status',
                            prefixIcon: Icon(Icons.flag),
                          ),
                          items: OrderStatus.values.map((status) {
                            return DropdownMenuItem<OrderStatus>(
                              value: status,
                              child: Text(_getStatusDisplayName(status)),
                            );
                          }).toList(),
                          onChanged: (OrderStatus? value) {
                            if (value != null) {
                              setState(() {
                                _selectedStatus = value;
                              });
                            }
                          },
                        ),
                      
                      if (isEditing) SizedBox(height: 16),
                      
                      TextFormField(
                        controller: _notesController,
                        decoration: InputDecoration(
                          labelText: 'Notes (Optional)',
                          prefixIcon: Icon(Icons.notes),
                          hintText: 'Additional details, special instructions...',
                        ),
                        maxLines: 3,
                        textCapitalization: TextCapitalization.sentences,
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 24),
              
              // Save Button
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveOrder,
                  child: _isLoading
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text(
                          isEditing ? 'Update Order' : 'Create Order',
                          style: TextStyle(fontSize: 16),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectDeliveryDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDeliveryDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 365)),
    );
    if (picked != null && picked != _selectedDeliveryDate) {
      setState(() {
        _selectedDeliveryDate = picked;
      });
    }
  }

  Future<void> _saveOrder() async {
    if (!_formKey.currentState!.validate() || _selectedCustomer == null) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final tailorId = authProvider.user?.uid;

      if (tailorId == null) {
        throw Exception('User not authenticated');
      }

      final order = TailorOrder(
        id: widget.order?.id ?? Uuid().v4(),
        customerId: _selectedCustomer!.id,
        customerName: _selectedCustomer!.name,
        style: _styleController.text.trim(),
        fabric: _fabricController.text.trim(),
        price: double.parse(_priceController.text),
        paidAmount: double.tryParse(_paidAmountController.text) ?? 0,
        deliveryDate: _selectedDeliveryDate,
        createdAt: widget.order?.createdAt ?? DateTime.now(),
        status: _selectedStatus,
        tailorId: tailorId,
        notes: _notesController.text.trim().isEmpty 
            ? null 
            : _notesController.text.trim(),
      );

      if (widget.order == null) {
        await FirebaseService.addOrder(order);
      } else {
        await FirebaseService.updateOrder(order);
      }

      Navigator.pop(context);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.order == null 
                ? 'Order created successfully' 
                : 'Order updated successfully',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving order: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
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

  @override
  void dispose() {
    _styleController.dispose();
    _fabricController.dispose();
    _priceController.dispose();
    _paidAmountController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}
