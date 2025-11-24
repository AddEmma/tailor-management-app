import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:form_field_validator/form_field_validator.dart';
import '../../providers/auth_provider.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  LoginScreenState createState() => LoginScreenState(); // Fixed: Made public
}

class LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: 60),
              // Logo/Icon
              Container(
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.indigo.withValues(
                    alpha: 0.1,
                  ), // Fixed deprecated withOpacity
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.content_cut, size: 60, color: Colors.indigo),
              ),
              SizedBox(height: 40),

              // Title
              Text(
                'Tailor Management',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              Text(
                'Manage your tailoring business with ease',
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 40),

              // Login Form
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email),
                      ),
                      validator: MultiValidator([
                        RequiredValidator(errorText: 'Email is required'),
                        EmailValidator(errorText: 'Please enter a valid email'),
                      ]).call,
                    ),
                    SizedBox(height: 16),

                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: Icon(Icons.lock),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                      validator: RequiredValidator(
                        errorText: 'Password is required',
                      ).call,
                    ),
                    SizedBox(height: 24),

                    // Login Button
                    Consumer<AuthProvider>(
                      builder: (context, authProvider, child) {
                        return SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: authProvider.isLoading
                                ? null
                                : _handleLogin,
                            child: authProvider.isLoading
                                ? CircularProgressIndicator(color: Colors.white)
                                : Text('Login', style: TextStyle(fontSize: 16)),
                          ),
                        );
                      },
                    ),

                    // Error Message - Fixed to use errorMessage instead of error
                    Consumer<AuthProvider>(
                      builder: (context, authProvider, child) {
                        if (authProvider.hasError &&
                            authProvider.errorMessage != null) {
                          return Container(
                            margin: EdgeInsets.only(top: 16),
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(
                                alpha: 0.1,
                              ), // Fixed deprecated withOpacity
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.red.withValues(
                                  alpha: 0.3,
                                ), // Fixed deprecated withOpacity
                              ),
                            ),
                            child: Text(
                              authProvider.errorMessage!,
                              style: TextStyle(color: Colors.red),
                              textAlign: TextAlign.center,
                            ),
                          );
                        }
                        return SizedBox.shrink();
                      },
                    ),
                  ],
                ),
              ),

              SizedBox(height: 24),

              // Forgot Password
              TextButton(
                onPressed: _showForgotPasswordDialog,
                child: Text('Forgot Password?'),
              ),

              SizedBox(height: 16),

              // Sign Up Link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Don\'t have an account? '),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => SignUpScreen()),
                      );
                    },
                    child: Text('Sign Up'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.signIn(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (success && mounted) {
        // Navigation handled by AuthWrapper
      }
    }
  }

  void _showForgotPasswordDialog() {
    final emailController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Reset Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Enter your email address to receive a password reset link.'),
            SizedBox(height: 16),
            TextFormField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email),
              ),
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
              if (emailController.text.trim().isNotEmpty) {
                final authProvider = Provider.of<AuthProvider>(
                  context,
                  listen: false,
                );
                final success = await authProvider.resetPassword(
                  emailController.text.trim(),
                );

                Navigator.pop(context);

                if (success && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Password reset email sent!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              }
            },
            child: Text('Send Reset Link'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
