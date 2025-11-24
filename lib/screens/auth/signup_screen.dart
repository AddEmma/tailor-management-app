import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:form_field_validator/form_field_validator.dart';
import '../../providers/auth_provider.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  SignUpScreenState createState() => SignUpScreenState();
}

class SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _businessNameController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Create Account'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Icon
                Container(
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.indigo.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.person_add, size: 40, color: Colors.indigo),
                ),
                SizedBox(height: 32),

                Text(
                  'Join Tailor Management',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 24),

                // Form Fields
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Full Name',
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator: RequiredValidator(
                    errorText: 'Name is required',
                  ).call,
                ),
                SizedBox(height: 16),

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
                  controller: _businessNameController,
                  decoration: InputDecoration(
                    labelText: 'Business Name (Optional)',
                    prefixIcon: Icon(Icons.business),
                  ),
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
                  validator: MultiValidator([
                    RequiredValidator(errorText: 'Password is required'),
                    MinLengthValidator(
                      6,
                      errorText: 'Password must be at least 6 characters',
                    ),
                  ]).call,
                ),
                SizedBox(height: 16),

                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  decoration: InputDecoration(
                    labelText: 'Confirm Password',
                    prefixIcon: Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value != _passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 32),

                // Sign Up Button
                Consumer<AuthProvider>(
                  builder: (context, authProvider, child) {
                    return SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: authProvider.isLoading
                            ? null
                            : _handleSignUp,
                        child: authProvider.isLoading
                            ? CircularProgressIndicator(color: Colors.white)
                            : Text(
                                'Create Account',
                                style: TextStyle(fontSize: 16),
                              ),
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
                          color: Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.red.withValues(alpha: 0.3),
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

                SizedBox(height: 24),

                // Login Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Already have an account? '),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: Text('Login'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleSignUp() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      // Fixed method call - removed extra parameter and fixed businessName parameter
      final success = await authProvider.signUp(
        _emailController.text.trim(),
        _passwordController.text,
        _nameController.text.trim(),
        businessName: _businessNameController.text.trim().isEmpty
            ? null
            : _businessNameController.text.trim(),
      );

      if (success && mounted) {
        Navigator.pop(context);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _businessNameController.dispose();
    super.dispose();
  }
}
