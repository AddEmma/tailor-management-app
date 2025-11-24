import 'package:flutter/material.dart';
import 'dashboard/dashboard_screen.dart';
import 'customers/customers_screen.dart';
import 'orders/orders_screen.dart';
import 'profile/profile_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  // Create screens lazily to avoid initialization issues
  late final List<Widget Function()> _screenBuilders = [
    () => const DashboardScreen(), // Use your separate DashboardScreen
    () => const CustomersScreen(),
    () => const OrdersScreen(),
    () => const ProfileScreen(),
  ];

  Widget? _currentScreen;

  @override
  void initState() {
    super.initState();
    _currentScreen = _screenBuilders[0](); // Initialize with dashboard
  }

  void _onItemTapped(int index) {
    if (index != _currentIndex) {
      setState(() {
        _currentIndex = index;
        _currentScreen = _screenBuilders[index]();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _currentScreen,
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.indigo,
        unselectedItemColor: Colors.grey,
        elevation: 8,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Customers'),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment),
            label: 'Orders',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
