import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:form_field_validator/form_field_validator.dart';
import 'package:email_validator/email_validator.dart' as EmailValidatorPackage;
import '../../providers/auth_provider.dart';
import '../../services/firebase_service.dart';
import '../../models/models.dart';

class AddCustomerScreen extends StatefulWidget {
  final Customer? customer;

  const AddCustomerScreen({super.key, this.customer});

  @override
  AddCustomerScreenState createState() => AddCustomerScreenState();
}

class AddCustomerScreenState extends State<AddCustomerScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;

  // Measurement controllers
  final Map<String, TextEditingController> _measurementControllers = {};

  bool _isLoading = false;

  final List<String> _measurementFields = [
    'Chest/Bust',
    'Waist',
    'Hip',
    'Shoulder Width',
    'Arm Length',
    'Neck',
    'Inseam',
    'Thigh',
    'Calf',
    'Wrist',
    'Bicep',
    'Length',
    'Sleeve Length',
    'Back Width',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.customer?.name ?? '');
    _phoneController = TextEditingController(
      text: widget.customer?.phone ?? '',
    );
    _emailController = TextEditingController(
      text: widget.customer?.email ?? '',
    );

    // Initialize measurement controllers
    for (String field in _measurementFields) {
      _measurementControllers[field] = TextEditingController(
        text: widget.customer?.measurements[field]?.toString() ?? '',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.customer != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Customer' : 'Add New Customer'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_isLoading)
            const Padding(
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
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.indigo, Colors.indigo.shade300],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Icon(
                      isEditing ? Icons.edit : Icons.person_add,
                      color: Colors.white,
                      size: 48,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isEditing
                          ? 'Update Customer Details'
                          : 'Add New Customer',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      isEditing
                          ? 'Modify customer information'
                          : 'Fill in the customer details below',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Personal Information Section
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.person, color: Colors.indigo),
                          const SizedBox(width: 8),
                          Text(
                            'Personal Information',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.indigo,
                                ),
                          ),
                        ],
                      ),
                      Divider(color: Colors.indigo.shade100),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Full Name *',
                          prefixIcon: const Icon(
                            Icons.person_outline,
                            color: Colors.indigo,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                              color: Colors.indigo,
                              width: 2,
                            ),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                        validator: RequiredValidator(
                          errorText: 'Customer name is required',
                        ).call,
                        textCapitalization: TextCapitalization.words,
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _phoneController,
                        decoration: InputDecoration(
                          labelText: 'Phone Number *',
                          prefixIcon: const Icon(
                            Icons.phone_outlined,
                            color: Colors.indigo,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                              color: Colors.indigo,
                              width: 2,
                            ),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                        keyboardType: TextInputType.phone,
                        validator: MultiValidator([
                          RequiredValidator(
                            errorText: 'Phone number is required',
                          ),
                          MinLengthValidator(
                            10,
                            errorText: 'Enter a valid phone number',
                          ),
                        ]).call,
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          labelText: 'Email Address (Optional)',
                          prefixIcon: const Icon(
                            Icons.email_outlined,
                            color: Colors.indigo,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                              color: Colors.indigo,
                              width: 2,
                            ),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value != null &&
                              value.isNotEmpty &&
                              !EmailValidatorPackage.EmailValidator.validate(
                                value,
                              )) {
                            return 'Please enter a valid email address';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Measurements Section - FIXED OVERFLOW ISSUE
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Fixed the Row that was causing overflow
                      Row(
                        children: [
                          const Icon(Icons.straighten, color: Colors.indigo),
                          const SizedBox(width: 8),
                          Expanded(
                            // FIXED: Wrapped in Expanded to prevent overflow
                            child: Text(
                              'Body Measurements',
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.indigo,
                                  ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.indigo.shade50,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
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
                      const SizedBox(height: 16),

                      // Use LayoutBuilder to ensure proper sizing
                      LayoutBuilder(
                        builder: (context, constraints) {
                          // Calculate cross-axis count based on available width
                          int crossAxisCount = constraints.maxWidth > 600
                              ? 3
                              : 2;

                          return GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: crossAxisCount,
                                  childAspectRatio:
                                      2.5, // Adjusted for better fit
                                  crossAxisSpacing: 12, // Reduced spacing
                                  mainAxisSpacing: 12, // Reduced spacing
                                ),
                            itemCount: _measurementFields.length,
                            itemBuilder: (context, index) {
                              final field = _measurementFields[index];
                              return TextFormField(
                                controller: _measurementControllers[field],
                                decoration: InputDecoration(
                                  labelText: field,
                                  suffixText: '"',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(
                                      color: Colors.indigo,
                                      width: 2,
                                    ),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 8, // Reduced padding
                                    vertical: 8,
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey[50],
                                  labelStyle: const TextStyle(
                                    fontSize: 11,
                                  ), // Smaller font
                                ),
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                validator: (value) {
                                  if (value != null && value.isNotEmpty) {
                                    final double? measurement = double.tryParse(
                                      value,
                                    );
                                    if (measurement == null) {
                                      return 'Invalid';
                                    }
                                    if (measurement <= 0 || measurement > 100) {
                                      return 'Invalid range';
                                    }
                                  }
                                  return null;
                                },
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // Save Button - FIXED OVERFLOW PROTECTION
              SizedBox(
                width: double.infinity, // Ensure button takes full width
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveCustomer,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                  ),
                  child: _isLoading
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min, // Prevent overflow
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            ),
                            SizedBox(width: 12),
                            Flexible(
                              // FIXED: Wrapped in Flexible
                              child: Text(
                                'Saving...',
                                style: TextStyle(fontSize: 16),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min, // Prevent overflow
                          children: [
                            Icon(isEditing ? Icons.update : Icons.person_add),
                            const SizedBox(width: 8),
                            Flexible(
                              // FIXED: Wrapped in Flexible
                              child: Text(
                                isEditing ? 'Update Customer' : 'Add Customer',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveCustomer() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all required fields correctly'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final tailorId = authProvider.user?.uid;

      if (tailorId == null) {
        throw Exception('User not authenticated. Please login again.');
      }

      // Collect measurements
      Map<String, double> measurements = {};
      _measurementControllers.forEach((field, controller) {
        final value = controller.text.trim();
        if (value.isNotEmpty) {
          final double? measurement = double.tryParse(value);
          if (measurement != null) {
            measurements[field] = measurement;
          }
        }
      });

      final customer = Customer(
        id: widget.customer?.id ?? const Uuid().v4(),
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        email: _emailController.text.trim().isEmpty
            ? null
            : _emailController.text.trim(),
        measurements: measurements,
        createdAt: widget.customer?.createdAt ?? DateTime.now(),
        tailorId: tailorId,
      );

      Customer savedCustomer;
      if (widget.customer == null) {
        savedCustomer = await FirebaseService.addCustomer(customer);
      } else {
        savedCustomer = await FirebaseService.updateCustomer(customer);
      }

      // Return to previous screen with the saved customer
      if (mounted) {
        Navigator.pop(context, savedCustomer);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('Error saving customer: ${e.toString()}')),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    for (var controller in _measurementControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }
}
