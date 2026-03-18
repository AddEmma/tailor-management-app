import 'package:flutter/material.dart';
import '../utils/responsive_utils.dart';
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

  // Screen builders for lazy loading
  late final List<Widget Function()> _screenBuilders = [
    () => const DashboardScreen(),
    () => const CustomersScreen(),
    () => const OrdersScreen(),
    () => const ProfileScreen(),
  ];

  // Cache built screens
  final Map<int, Widget> _screenCache = {};

  Widget _getScreen(int index) {
    _screenCache[index] ??= _screenBuilders[index]();
    return _screenCache[index]!;
  }

  void _onItemTapped(int index) {
    if (index != _currentIndex) {
      setState(() {
        _currentIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWideScreen = !Breakpoints.isMobile(context);

    return Scaffold(
      body: Row(
        children: [
          // Navigation Rail for tablet/desktop
          if (isWideScreen)
            NavigationRail(
              selectedIndex: _currentIndex,
              onDestinationSelected: _onItemTapped,
              extended: Breakpoints.isDesktop(context),
              minExtendedWidth: 200,
              backgroundColor: Colors.indigo.shade50,
              selectedIconTheme: const IconThemeData(color: Colors.white),
              unselectedIconTheme: IconThemeData(color: Colors.indigo.shade400),
              selectedLabelTextStyle: TextStyle(
                color: Colors.indigo.shade700,
                fontWeight: FontWeight.bold,
              ),
              unselectedLabelTextStyle: TextStyle(
                color: Colors.indigo.shade600,
              ),
              indicatorColor: Colors.indigo,
              leading: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.indigo,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.content_cut,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    if (Breakpoints.isDesktop(context)) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Tailor',
                        style: TextStyle(
                          color: Colors.indigo.shade700,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.dashboard_outlined),
                  selectedIcon: Icon(Icons.dashboard),
                  label: Text('Dashboard'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.people_outline),
                  selectedIcon: Icon(Icons.people),
                  label: Text('Customers'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.assignment_outlined),
                  selectedIcon: Icon(Icons.assignment),
                  label: Text('Orders'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.person_outline),
                  selectedIcon: Icon(Icons.person),
                  label: Text('Profile'),
                ),
              ],
            ),
          // Divider between rail and content
          if (isWideScreen) const VerticalDivider(thickness: 1, width: 1),
          // Main content area
          Expanded(child: _getScreen(_currentIndex)),
        ],
      ),
      // Bottom navigation for mobile only
      bottomNavigationBar: isWideScreen
          ? null
          : BottomNavigationBar(
              type: BottomNavigationBarType.fixed,
              currentIndex: _currentIndex,
              onTap: _onItemTapped,
              selectedItemColor: Colors.indigo,
              unselectedItemColor: Colors.grey,
              elevation: 8,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.dashboard_outlined),
                  activeIcon: Icon(Icons.dashboard),
                  label: 'Dashboard',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.people_outline),
                  activeIcon: Icon(Icons.people),
                  label: 'Customers',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.assignment_outlined),
                  activeIcon: Icon(Icons.assignment),
                  label: 'Orders',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person_outline),
                  activeIcon: Icon(Icons.person),
                  label: 'Profile',
                ),
              ],
            ),
    );
  }
}
