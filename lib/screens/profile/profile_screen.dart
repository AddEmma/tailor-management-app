import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        elevation: 0,
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          final user = authProvider.user;

          if (user == null) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading profile...'),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Profile Header
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.indigo,
                          child: Text(
                            _getInitials(user.displayName),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          user.displayName ?? 'No Name',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          user.email ?? 'No Email',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                        if (user.phoneNumber?.isNotEmpty == true) ...[
                          const SizedBox(height: 4),
                          Text(
                            user.phoneNumber!,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Settings Options
                _buildSettingsSection(context, authProvider),
                const SizedBox(height: 20),

                // App Information
                _buildAppInfoSection(context),
                const SizedBox(height: 20),

                // Sign Out Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: (_isLoading || authProvider.isLoading)
                        ? null
                        : () => _showSignOutDialog(context, authProvider),
                    icon: (_isLoading || authProvider.isLoading)
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.logout),
                    label: const Text('Sign Out'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _getInitials(String? displayName) {
    if (displayName?.isNotEmpty == true) {
      return displayName![0].toUpperCase();
    }
    return '?';
  }

  Widget _buildSettingsSection(
    BuildContext context,
    AuthProvider authProvider,
  ) {
    return Card(
      child: Column(
        children: [
          _buildSettingsTile(
            context,
            icon: Icons.person,
            title: 'Edit Profile',
            subtitle: 'Update your personal information',
            onTap: () {
              _showEditProfileDialog(context, authProvider.user!);
            },
          ),
          const Divider(height: 1),
          _buildSettingsTile(
            context,
            icon: Icons.notifications,
            title: 'Notifications',
            subtitle: 'Manage notification preferences',
            onTap: () {
              _showNotificationSettings(context);
            },
          ),
          const Divider(height: 1),
          _buildSettingsTile(
            context,
            icon: Icons.backup,
            title: 'Backup & Sync',
            subtitle: 'Your data is automatically synced',
            trailing: const Icon(Icons.cloud_done, color: Colors.green),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Your data is automatically backed up to the cloud',
                  ),
                  backgroundColor: Colors.green,
                ),
              );
            },
          ),
          const Divider(height: 1),
          _buildSettingsTile(
            context,
            icon: Icons.security,
            title: 'Privacy & Security',
            subtitle: 'Manage your account security',
            onTap: () {
              _showPrivacySettings(context);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAppInfoSection(BuildContext context) {
    return Card(
      child: Column(
        children: [
          _buildSettingsTile(
            context,
            icon: Icons.help,
            title: 'Help & Support',
            subtitle: 'Get help and contact support',
            onTap: () {
              _showHelpDialog(context);
            },
          ),
          const Divider(height: 1),
          _buildSettingsTile(
            context,
            icon: Icons.info,
            title: 'About',
            subtitle: 'Tailor Management App v1.0.0',
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'Tailor Management',
                applicationVersion: '1.0.0',
                applicationIcon: const Icon(
                  Icons.content_cut,
                  size: 48,
                  color: Colors.indigo,
                ),
                children: const [
                  Text(
                    'A comprehensive solution for managing your tailoring business.',
                  ),
                  SizedBox(height: 16),
                  Text('Features:'),
                  Text('• Customer management with measurements'),
                  Text('• Order tracking and status updates'),
                  Text('• Payment tracking and history'),
                  Text('• Real-time sync across devices'),
                  Text('• Delivery reminders'),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.indigo.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Colors.indigo),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      trailing: trailing ?? const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  void _showEditProfileDialog(BuildContext context, user) {
    final nameController = TextEditingController(text: user.displayName ?? '');
    final businessController = TextEditingController(text: '');
    final phoneController = TextEditingController(text: user.phoneNumber ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Profile'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: businessController,
                decoration: const InputDecoration(
                  labelText: 'Business Name (Optional)',
                  prefixIcon: Icon(Icons.business),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone Number (Optional)',
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Profile update coming soon!')),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showNotificationSettings(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Notification Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SwitchListTile(
              title: const Text('Order Updates'),
              subtitle: const Text('Get notified about order status changes'),
              value: true,
              onChanged: (value) {
                // TODO: Implement notification settings
              },
            ),
            SwitchListTile(
              title: const Text('Payment Alerts'),
              subtitle: const Text('Get notified about new payments'),
              value: true,
              onChanged: (value) {
                // TODO: Implement notification settings
              },
            ),
            SwitchListTile(
              title: const Text('Delivery Reminders'),
              subtitle: const Text('Get reminded about upcoming deliveries'),
              value: true,
              onChanged: (value) {
                // TODO: Implement notification settings
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showPrivacySettings(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const AlertDialog(
        title: Text('Privacy & Security'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your data is securely stored and synchronized across your devices.',
            ),
            SizedBox(height: 16),
            Text(
              'Data Protection:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text('• All data is encrypted in transit and at rest'),
            Text('• Only you can access your customer and order data'),
            Text('• We never share your data with third parties'),
            SizedBox(height: 16),
            Text(
              'Account Security:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text('• Use a strong password for your account'),
            Text('• Enable two-factor authentication (coming soon)'),
            Text('• Regular security updates are automatically applied'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: null, // This will be handled by Navigator.pop
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const AlertDialog(
        title: Text('Help & Support'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Need help? Here are some resources:'),
            SizedBox(height: 16),
            Text('Quick Start:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('1. Add your first customer with measurements'),
            Text('2. Create an order for that customer'),
            Text('3. Track payments and update order status'),
            Text('4. Monitor upcoming deliveries on the dashboard'),
            SizedBox(height: 16),
            Text('Support:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('Email: support@tailormanagement.com'),
            Text('Phone: +1 (555) 123-4567'),
            SizedBox(height: 16),
            Text(
              'Your data syncs automatically across all your devices when connected to the internet.',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: null, // This will be handled by Navigator.pop
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showSignOutDialog(BuildContext context, AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text(
          'Are you sure you want to sign out? Your data will be synced when you sign back in.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              setState(() {
                _isLoading = true;
              });

              try {
                await authProvider.signOut();
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Sign out failed. Please try again.'),
                      backgroundColor: Colors.red,
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
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}
