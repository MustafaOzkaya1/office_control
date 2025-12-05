import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:office_control/providers/auth_provider.dart';
import 'package:office_control/screens/admin/admin_panel_screen.dart';
import 'package:office_control/screens/admin/create_notification_screen.dart';
import 'package:office_control/screens/admin/office_location_screen.dart';
import 'package:office_control/utils/app_theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final isAdmin = authProvider.isAdmin;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Text(
              'Settings',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 24),

            // Admin Section (only for admins)
            if (isAdmin) ...[
              _SectionTitle(title: 'Admin'),
              const SizedBox(height: 12),
              _SettingsCard(
                items: [
                  _SettingsItem(
                    icon: Icons.admin_panel_settings,
                    title: 'Admin Panel',
                    subtitle: 'Manage access requests & users',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AdminPanelScreen(),
                        ),
                      );
                    },
                  ),
                  _SettingsItem(
                    icon: Icons.notifications_active,
                    title: 'Bildirim Oluştur',
                    subtitle: 'Çalışanlara bildirim gönder',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CreateNotificationScreen(),
                        ),
                      );
                    },
                  ),
                  _SettingsItem(
                    icon: Icons.location_on_outlined,
                    title: 'Ofis Konumu',
                    subtitle: 'Ofis koordinatlarını ve erişim yarıçapını ayarla',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const OfficeLocationScreen(),
                        ),
                      );
                    },
                  ),
                  _SettingsItem(
                    icon: Icons.wifi,
                    title: 'ESP32 Settings',
                    subtitle: 'Configure door controller',
                    onTap: () {
                      // TODO: ESP32 settings
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],

            // General Settings
            _SectionTitle(title: 'General'),
            const SizedBox(height: 12),
            _SettingsCard(
              items: [
                _SettingsItem(
                  icon: Icons.notifications_outlined,
                  title: 'Notifications',
                  subtitle: 'Manage notification preferences',
                  onTap: () {
                    // TODO: Notifications settings
                  },
                ),
                _SettingsItem(
                  icon: Icons.language,
                  title: 'Language',
                  subtitle: 'English',
                  onTap: () {
                    // TODO: Language settings
                  },
                ),
                _SettingsItem(
                  icon: Icons.palette_outlined,
                  title: 'Theme',
                  subtitle: 'Dark',
                  onTap: () {
                    // TODO: Theme settings
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Security
            _SectionTitle(title: 'Security'),
            const SizedBox(height: 12),
            _SettingsCard(
              items: [
                _SettingsItem(
                  icon: Icons.lock_outline,
                  title: 'Change Password',
                  subtitle: 'Update your password',
                  onTap: () {
                    // TODO: Change password
                  },
                ),
                _SettingsItem(
                  icon: Icons.fingerprint,
                  title: 'Biometric Login',
                  subtitle: 'Enable fingerprint/Face ID',
                  trailing: Switch(
                    value: false,
                    onChanged: (value) {
                      // TODO: Toggle biometric
                    },
                    activeColor: AppColors.accent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // About
            _SectionTitle(title: 'About'),
            const SizedBox(height: 12),
            _SettingsCard(
              items: [
                _SettingsItem(
                  icon: Icons.info_outline,
                  title: 'App Version',
                  subtitle: '1.0.0',
                  onTap: null,
                ),
                _SettingsItem(
                  icon: Icons.description_outlined,
                  title: 'Terms of Service',
                  onTap: () {
                    // TODO: Terms
                  },
                ),
                _SettingsItem(
                  icon: Icons.privacy_tip_outlined,
                  title: 'Privacy Policy',
                  onTap: () {
                    // TODO: Privacy
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Logout Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _showLogoutDialog(context),
                icon: const Icon(Icons.logout, color: AppColors.error),
                label: const Text(
                  'Log Out',
                  style: TextStyle(color: AppColors.error),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.error),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<AuthProvider>().signOut();
            },
            child: const Text(
              'Log Out',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppColors.textSecondary,
          ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final List<_SettingsItem> items;

  const _SettingsCard({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          return Column(
            children: [
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    item.icon,
                    color: AppColors.primaryLight,
                    size: 20,
                  ),
                ),
                title: Text(item.title),
                subtitle: item.subtitle != null ? Text(item.subtitle!) : null,
                trailing: item.trailing ??
                    (item.onTap != null
                        ? const Icon(
                            Icons.chevron_right,
                            color: AppColors.textMuted,
                          )
                        : null),
                onTap: item.onTap,
              ),
              if (index < items.length - 1)
                const Divider(height: 1, indent: 16, endIndent: 16),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _SettingsItem {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;

  const _SettingsItem({
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.trailing,
  });
}

