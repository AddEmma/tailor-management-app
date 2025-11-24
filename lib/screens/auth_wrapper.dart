import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'auth/login_screen.dart';
import 'dashboard/dashboard_screen.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        // Use debugPrint instead of print for better debugging
        debugPrint(
          'AuthWrapper: isAuthenticated=${authProvider.isAuthenticated}, '
          'isLoading=${authProvider.isLoading}, '
          'hasInitialized=${authProvider.hasInitialized}, '
          'user=${authProvider.user?.displayName ?? authProvider.user?.email}',
        );

        // Handle error states
        if (authProvider.hasError) {
          return _buildErrorScreen(authProvider);
        }

        // Show loading screen while checking auth state or during login/signup
        if (authProvider.isLoading || !authProvider.hasInitialized) {
          return _buildLoadingScreen();
        }

        // Navigate based on authentication state
        if (authProvider.isAuthenticated) {
          debugPrint(
            'AuthWrapper: User authenticated, navigating to DashboardScreen',
          );
          return const DashboardScreen();
        } else {
          debugPrint(
            'AuthWrapper: User not authenticated, navigating to LoginScreen',
          );
          return const LoginScreen();
        }
      },
    );
  }

  Widget _buildErrorScreen(AuthProvider authProvider) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
              const SizedBox(height: 16),
              Text(
                'Authentication Error',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  authProvider.errorMessage ?? 'An unexpected error occurred',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  authProvider.clearError();
                  // The AuthProvider will automatically re-initialize
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF6C63FF), Color(0xFFE91E63)],
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App logo/icon
              CircleAvatar(
                radius: 40,
                backgroundColor: Colors.white,
                child: Icon(
                  Icons.design_services,
                  size: 40,
                  color: Color(0xFFE91E63),
                ),
              ),
              SizedBox(height: 32),

              Text(
                'Atelier Management',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
              SizedBox(height: 8),

              Text(
                'Fashion Studio Management',
                style: TextStyle(fontSize: 16, color: Colors.white70),
              ),
              SizedBox(height: 48),

              // Loading indicator
              SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              SizedBox(height: 16),

              Text(
                'Loading...',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
