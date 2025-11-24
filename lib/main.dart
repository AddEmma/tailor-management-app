import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/main_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase with error handling
  try {
    await Firebase.initializeApp();
    debugPrint('Firebase initialized successfully');
  } catch (e) {
    debugPrint('Firebase initialization error: $e');
    // Continue without Firebase for now
  }

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(),
          lazy: true, // Load only when needed
        ),
      ],
      child: MaterialApp(
        title: 'Tailor Management',
        theme: ThemeData(
          primarySwatch: Colors.indigo,
          useMaterial3: true,
          // Optimize theme for performance
          splashFactory: InkSparkle.splashFactory,
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.grey.shade50,
          ),
        ),
        home: const AuthWrapper(),
        debugShowCheckedModeBanner: false,
        // Optimize scrolling and animation performance
        scrollBehavior: const MaterialScrollBehavior().copyWith(
          scrollbars: false,
        ),
        builder: (context, child) {
          // Simplified error boundary
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(1.0), // Prevent text scaling issues
            ),
            child: child!,
          );
        },
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isInitializing = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    try {
      // Add a small delay to prevent immediate UI blocking
      await Future.delayed(const Duration(milliseconds: 100));

      // Wait for AuthProvider to initialize (it initializes automatically in constructor)
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      // Wait for initialization to complete
      int attempts = 0;
      const maxAttempts = 50; // 5 seconds total

      while (!authProvider.hasInitialized && attempts < maxAttempts) {
        await Future.delayed(const Duration(milliseconds: 100));
        attempts++;
      }

      if (!authProvider.hasInitialized) {
        throw Exception('Authentication initialization timeout');
      }

      if (mounted) {
        setState(() {
          _isInitializing = false;
          _error = authProvider.hasError ? authProvider.errorMessage : null;
        });
      }
    } catch (e) {
      debugPrint('Auth initialization error: $e');
      if (mounted) {
        setState(() {
          _isInitializing = false;
          _error = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return _buildLoadingScreen();
    }

    if (_error != null) {
      return _buildErrorScreen();
    }

    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        // Simple auth state check without complex logic
        if (authProvider.isLoading) {
          return _buildLoadingScreen();
        }

        return authProvider.isAuthenticated
            ? const MainScreen()
            : const LoginScreen();
      },
    );
  }

  Widget _buildLoadingScreen() {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(strokeWidth: 2, color: Colors.indigo),
            SizedBox(height: 24),
            Text(
              'Loading...',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorScreen() {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.orange,
                  size: 64,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Setup Issue',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Text(
                  _error ?? 'Something went wrong during setup',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _error = null;
                        _isInitializing = true;
                      });
                      _initializeAuth();
                    },
                    child: const Text('Try Again'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
