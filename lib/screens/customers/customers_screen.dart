import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/firebase_service.dart';
import '../../models/models.dart';
import 'add_customer_screen.dart';
import 'customer_detail_screen.dart';
import 'dart:async';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  CustomersScreenState createState() => CustomersScreenState();
}

class CustomersScreenState extends State<CustomersScreen>
    with AutomaticKeepAliveClientMixin {
  bool _isRefreshing = false;
  StreamSubscription<List<Customer>>? _customerSubscription;
  List<Customer> _cachedCustomers = [];
  String? _lastError;

  @override
  bool get wantKeepAlive => true; // Keep state alive

  @override
  void initState() {
    super.initState();
    debugPrint('CustomersScreen: initState called');
    // Force refresh when screen is first created
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeCustomerStream();
    });
  }

  void _initializeCustomerStream() {
    if (!mounted) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final tailorId = authProvider.user?.uid;

    if (tailorId != null) {
      debugPrint('Initializing customer stream for $tailorId');

      // Cancel existing subscription
      _customerSubscription?.cancel();

      _customerSubscription = FirebaseService.getCustomers(tailorId).listen(
        (customers) {
          if (mounted) {
            setState(() {
              _cachedCustomers = customers;
              _lastError = null;
              _isRefreshing = false;
            });
            debugPrint('Received ${customers.length} customers from stream');
          }
        },
        onError: (error) {
          if (mounted) {
            setState(() {
              _lastError = error.toString();
              _isRefreshing = false;
            });
            debugPrint('Stream error: $error');
          }
        },
      );
    }
  }

  Future<void> _forceRefresh() async {
    if (mounted && !_isRefreshing) {
      setState(() {
        _isRefreshing = true;
      });

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final tailorId = authProvider.user?.uid;

      if (tailorId != null) {
        try {
          // Add a small delay to ensure Firebase has time to sync
          await Future.delayed(const Duration(milliseconds: 500));
          await FirebaseService.refreshCustomers(tailorId);

          // Re-initialize the stream to ensure fresh data
          _initializeCustomerStream();
        } catch (e) {
          debugPrint('Error during refresh: $e');
          if (mounted) {
            setState(() {
              _lastError = e.toString();
            });
          }
        } finally {
          if (mounted) {
            setState(() {
              _isRefreshing = false;
            });
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

    final authProvider = Provider.of<AuthProvider>(context);
    final tailorId = authProvider.user?.uid;

    debugPrint('CustomersScreen: build() called - tailorId: $tailorId');
    debugPrint(
      'CustomersScreen: authProvider.isAuthenticated: ${authProvider.isAuthenticated}',
    );
    debugPrint(
      'CustomersScreen: authProvider.hasInitialized: ${authProvider.hasInitialized}',
    );

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'My Customers',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              if (tailorId != null) {
                showSearch(
                  context: context,
                  delegate: CustomerSearchDelegate(tailorId, _cachedCustomers),
                );
              }
            },
          ),
          IconButton(
            icon: _isRefreshing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.refresh),
            onPressed: _isRefreshing ? null : _forceRefresh,
          ),
        ],
      ),
      body: tailorId == null ? _buildNotLoggedIn() : _buildCustomerContent(),
      floatingActionButton: tailorId != null
          ? FloatingActionButton.extended(
              onPressed: () async {
                // Store the current context and check mounted state
                if (!mounted) return;
                final currentContext = context;

                final result = await Navigator.push<Customer>(
                  currentContext,
                  MaterialPageRoute(
                    builder: (context) => const AddCustomerScreen(),
                  ),
                );

                // Force refresh after adding a customer
                if (result != null && mounted) {
                  debugPrint(
                    'Customer added: ${result.name} with ID: ${result.id}',
                  );

                  // Show success message
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            const Icon(Icons.check_circle, color: Colors.white),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text('${result.name} added successfully!'),
                            ),
                          ],
                        ),
                        backgroundColor: Colors.green,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }

                  // Refresh the stream
                  await _forceRefresh();
                }
              },
              icon: const Icon(Icons.person_add),
              label: const Text('Add Customer'),
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
            )
          : null,
    );
  }

  Widget _buildCustomerContent() {
    // Handle different states
    if (_isRefreshing && _cachedCustomers.isEmpty) {
      return _buildLoading();
    }

    if (_lastError != null && _cachedCustomers.isEmpty) {
      return _buildError(_lastError!);
    }

    if (_cachedCustomers.isEmpty) {
      return _buildEmptyState();
    }

    return _buildCustomerList(_cachedCustomers);
  }

  Widget _buildNotLoggedIn() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.account_circle_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Please login to view customers',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              // Navigate to login or handle authentication
            },
            icon: const Icon(Icons.login),
            label: const Text('Login'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoading() {
    debugPrint('CustomersScreen: Displaying loading widget');
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Colors.indigo),
          SizedBox(height: 16),
          Text('Loading customers...', style: TextStyle(color: Colors.grey)),
          SizedBox(height: 8),
          Text(
            'Syncing with server...',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildError(String error) {
    debugPrint('CustomersScreen: Displaying error widget - $error');
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          const Text(
            'Error loading customers',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Please check your connection and try again',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.symmetric(horizontal: 32),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Error: $error',
              style: const TextStyle(
                color: Colors.red,
                fontSize: 12,
                fontFamily: 'monospace',
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _forceRefresh,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    debugPrint('CustomersScreen: Displaying empty state widget');
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.indigo.shade50,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.people_outline,
                size: 64,
                color: Colors.indigo,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No customers yet',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add your first customer to get started with managing orders and measurements',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
            const SizedBox(height: 16),
            Text(
              'Customers will sync across all your devices automatically',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[500], fontSize: 14),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () async {
                if (!mounted) return;
                final currentContext = context;

                final result = await Navigator.push<Customer>(
                  currentContext,
                  MaterialPageRoute(
                    builder: (context) => const AddCustomerScreen(),
                  ),
                );

                if (result != null && mounted) {
                  await _forceRefresh();
                }
              },
              icon: const Icon(Icons.person_add),
              label: const Text('Add Your First Customer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                textStyle: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerList(List<Customer> customers) {
    debugPrint(
      'CustomersScreen: Building customer list with ${customers.length} customers',
    );
    return RefreshIndicator(
      onRefresh: _forceRefresh,
      color: Colors.indigo,
      child: Column(
        children: [
          // Customer count header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.indigo, Colors.indigo.shade300],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.people, color: Colors.white, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  // FIXED: Wrapped in Expanded to prevent overflow
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${customers.length} Customer${customers.length != 1 ? 's' : ''}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        'Synced across devices • Tap to view details',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.sync, color: Colors.white, size: 14),
                      SizedBox(width: 4),
                      Text(
                        'Synced',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Customer list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: customers.length,
              itemBuilder: (context, index) {
                final customer = customers[index];
                return _buildCustomerCard(context, customer, index);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerCard(
    BuildContext context,
    Customer customer,
    int index,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CustomerDetailScreen(customer: customer),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Customer Avatar
              Hero(
                tag: 'customer_avatar_${customer.id}',
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor:
                          Colors.primaries[index % Colors.primaries.length],
                      child: Text(
                        customer.name.isNotEmpty
                            ? customer.name[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                    ),
                    // Sync indicator
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 10,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),

              // Customer Info - FIXED OVERFLOW ISSUES
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customer.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      overflow: TextOverflow.ellipsis, // Prevent overflow
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.phone, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Expanded(
                          // FIXED: Wrapped in Expanded
                          child: Text(
                            customer.phone,
                            style: TextStyle(color: Colors.grey[700]),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (customer.email != null &&
                        customer.email!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.email, size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              customer.email!,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: Colors.grey[700]),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 8),
                    // Fixed measurements row with better wrapping
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.indigo.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${customer.measurements.length} measurements',
                            style: const TextStyle(
                              color: Colors.indigo,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.sync,
                                color: Colors.green.shade600,
                                size: 10,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                'Synced',
                                style: TextStyle(
                                  color: Colors.green.shade600,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Actions Menu
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, color: Colors.grey[600]),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: ListTile(
                      leading: Icon(Icons.edit, color: Colors.blue),
                      title: Text('Edit Customer'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const PopupMenuItem(
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
                onSelected: (value) async {
                  if (value == 'edit') {
                    if (mounted) {
                      final currentContext = context;
                      final result = await Navigator.push<Customer>(
                        currentContext,
                        MaterialPageRoute(
                          builder: (context) =>
                              AddCustomerScreen(customer: customer),
                        ),
                      );

                      if (result != null && mounted) {
                        await _forceRefresh();
                      }
                    }
                  } else if (value == 'delete') {
                    if (mounted) {
                      _showDeleteDialog(context, customer);
                    }
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, Customer customer) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 8),
            Expanded(
              child: Text('Delete Customer'),
            ), // FIXED: Wrapped in Expanded
          ],
        ),
        content: Text(
          'Are you sure you want to delete ${customer.name}?\n\nThis action cannot be undone and will also delete all associated orders. The deletion will sync across all your devices.',
          style: const TextStyle(height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                Navigator.pop(dialogContext); // Close dialog first

                if (!mounted) return;
                final scaffoldMessenger = ScaffoldMessenger.of(context);

                // Show loading snackbar
                scaffoldMessenger.showSnackBar(
                  const SnackBar(
                    content: Row(
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(child: Text('Deleting customer...')), // FIXED
                      ],
                    ),
                    backgroundColor: Colors.orange,
                    duration: Duration(seconds: 3),
                  ),
                );

                await FirebaseService.deleteCustomer(
                  customer.id,
                  customer.tailorId,
                );

                if (mounted) {
                  scaffoldMessenger.hideCurrentSnackBar();
                  scaffoldMessenger.showSnackBar(
                    const SnackBar(
                      content: Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.white),
                          SizedBox(width: 8),
                          Text('Customer deleted successfully'),
                        ],
                      ),
                      backgroundColor: Colors.green,
                    ),
                  );

                  // Force refresh to ensure sync
                  await _forceRefresh();
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Icon(Icons.error, color: Colors.white),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Error deleting customer: ${e.toString()}',
                            ),
                          ),
                        ],
                      ),
                      backgroundColor: Colors.red,
                      duration: const Duration(seconds: 5),
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _customerSubscription?.cancel();
    super.dispose();
  }
}

// IMPROVED Search Delegate with cached data
class CustomerSearchDelegate extends SearchDelegate<Customer?> {
  final String tailorId;
  final List<Customer> customers;

  CustomerSearchDelegate(this.tailorId, this.customers);

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults(context);
  }

  Widget _buildSearchResults(BuildContext context) {
    if (query.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Search for customers',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Enter customer name or phone number',
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    if (customers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No customers found',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    final filteredCustomers = customers
        .where(
          (customer) =>
              customer.name.toLowerCase().contains(query.toLowerCase()) ||
              customer.phone.contains(query) ||
              (customer.email?.toLowerCase().contains(query.toLowerCase()) ??
                  false),
        )
        .toList();

    if (filteredCustomers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_search, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text(
              'No customers found',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'No customers match "$query"',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                close(context, null);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddCustomerScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.person_add),
              label: const Text('Add New Customer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredCustomers.length,
      itemBuilder: (context, index) {
        final customer = filteredCustomers[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Stack(
              children: [
                CircleAvatar(
                  backgroundColor:
                      Colors.primaries[index % Colors.primaries.length],
                  child: Text(
                    customer.name.isNotEmpty
                        ? customer.name[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1),
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 8,
                    ),
                  ),
                ),
              ],
            ),
            title: Text(
              customer.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(customer.phone, overflow: TextOverflow.ellipsis),
                if (customer.email != null && customer.email!.isNotEmpty)
                  Text(
                    customer.email!,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              close(context, customer);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      CustomerDetailScreen(customer: customer),
                ),
              );
            },
            isThreeLine: customer.email != null && customer.email!.isNotEmpty,
          ),
        );
      },
    );
  }
}

