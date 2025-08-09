import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../../constants/app_colors.dart';

class SettingScreen extends StatefulWidget {
  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = false;
  bool _biometricEnabled = false;
  bool _autoBackup = true;
  String _selectedLanguage = 'English';
  String _selectedCurrency = 'PHP';

  final List<String> _languages = ['English', 'Filipino', 'Cebuano'];
  final List<String> _currencies = ['PHP', 'USD', 'EUR'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Account Settings'),
            _buildSettingsGroup([
              _buildSettingsTile(
                icon: Icons.person_outline,
                title: 'Edit Profile',
                subtitle: 'Update your personal information',
                onTap: () => _navigateToProfile(),
              ),
              _buildSettingsTile(
                icon: Icons.lock_outline,
                title: 'Change Password',
                subtitle: 'Update your account password',
                onTap: () => _showChangePasswordDialog(),
              ),
              _buildSettingsTile(
                icon: Icons.security_outlined,
                title: 'Privacy Settings',
                subtitle: 'Manage your privacy preferences',
                onTap: () => _showPrivacySettings(),
              ),
            ]),

            const SizedBox(height: 24),
            _buildSectionTitle('App Preferences'),
            _buildSettingsGroup([
              _buildSwitchTile(
                icon: Icons.notifications_outlined,
                title: 'Push Notifications',
                subtitle: 'Receive alerts and reminders',
                value: _notificationsEnabled,
                onChanged: (value) => setState(() => _notificationsEnabled = value),
              ),
              _buildSwitchTile(
                icon: Icons.dark_mode_outlined,
                title: 'Dark Mode',
                subtitle: 'Use dark theme',
                value: _darkModeEnabled,
                onChanged: (value) => setState(() => _darkModeEnabled = value),
              ),
              _buildSwitchTile(
                icon: Icons.fingerprint,
                title: 'Biometric Login',
                subtitle: 'Use fingerprint or face ID',
                value: _biometricEnabled,
                onChanged: (value) => setState(() => _biometricEnabled = value),
              ),
              _buildDropdownTile(
                icon: Icons.language_outlined,
                title: 'Language',
                subtitle: 'Choose your preferred language',
                value: _selectedLanguage,
                items: _languages,
                onChanged: (value) => setState(() => _selectedLanguage = value),
              ),
              _buildDropdownTile(
                icon: Icons.currency_exchange,
                title: 'Currency',
                subtitle: 'Default currency for transactions',
                value: _selectedCurrency,
                items: _currencies,
                onChanged: (value) => setState(() => _selectedCurrency = value),
              ),
            ]),

            const SizedBox(height: 24),
            _buildSectionTitle('Data & Storage'),
            _buildSettingsGroup([
              _buildSwitchTile(
                icon: Icons.backup_outlined,
                title: 'Auto Backup',
                subtitle: 'Automatically backup your data',
                value: _autoBackup,
                onChanged: (value) => setState(() => _autoBackup = value),
              ),
              _buildSettingsTile(
                icon: Icons.cloud_download_outlined,
                title: 'Export Data',
                subtitle: 'Download your cattle records',
                onTap: () => _exportData(),
              ),
              _buildSettingsTile(
                icon: Icons.storage_outlined,
                title: 'Storage Usage',
                subtitle: 'View app storage details',
                onTap: () => _showStorageUsage(),
              ),
              _buildSettingsTile(
                icon: Icons.sync_outlined,
                title: 'Sync Data',
                subtitle: 'Manually sync with cloud',
                onTap: () => _syncData(),
              ),
            ]),

            const SizedBox(height: 24),
            _buildSectionTitle('Farm Management'),
            _buildSettingsGroup([
              _buildSettingsTile(
                icon: FontAwesomeIcons.cow,
                title: 'Cattle Categories',
                subtitle: 'Manage cattle types and breeds',
                onTap: () => _manageCattleCategories(),
              ),
              _buildSettingsTile(
                icon: Icons.event_note_outlined,
                title: 'Event Types',
                subtitle: 'Customize event categories',
                onTap: () => _manageEventTypes(),
              ),
              _buildSettingsTile(
                icon: Icons.location_on_outlined,
                title: 'Farm Locations',
                subtitle: 'Set up farm areas and sections',
                onTap: () => _manageFarmLocations(),
              ),
              _buildSettingsTile(
                icon: Icons.schedule_outlined,
                title: 'Reminder Settings',
                subtitle: 'Configure automatic reminders',
                onTap: () => _configureReminders(),
              ),
            ]),

            const SizedBox(height: 24),
            _buildSectionTitle('Support & About'),
            _buildSettingsGroup([
              _buildSettingsTile(
                icon: Icons.help_outline,
                title: 'Help & Support',
                subtitle: 'Get help and contact support',
                onTap: () => _showHelpSupport(),
              ),
              _buildSettingsTile(
                icon: Icons.feedback_outlined,
                title: 'Send Feedback',
                subtitle: 'Share your thoughts with us',
                onTap: () => _sendFeedback(),
              ),
              _buildSettingsTile(
                icon: Icons.star_outline,
                title: 'Rate App',
                subtitle: 'Rate us on the app store',
                onTap: () => _rateApp(),
              ),
              _buildSettingsTile(
                icon: Icons.info_outline,
                title: 'About',
                subtitle: 'App version and information',
                onTap: () => _showAboutDialog(),
                trailing: const Text(
                  'v1.0.0',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ),
            ]),

            const SizedBox(height: 24),
            _buildSectionTitle('Advanced'),
            _buildSettingsGroup([
              _buildSettingsTile(
                icon: Icons.developer_mode,
                title: 'Developer Options',
                subtitle: 'Advanced settings for testing',
                onTap: () => _showDeveloperOptions(),
              ),
              _buildSettingsTile(
                icon: Icons.bug_report_outlined,
                title: 'Report Bug',
                subtitle: 'Report technical issues',
                onTap: () => _reportBug(),
              ),
              _buildSettingsTile(
                icon: Icons.refresh,
                title: 'Reset Settings',
                subtitle: 'Reset all settings to default',
                onTap: () => _showResetDialog(),
                textColor: Colors.red,
              ),
            ]),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildSettingsGroup(List<Widget> children) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Widget? trailing,
    Color? textColor,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: AppColors.primary, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: textColor ?? Colors.black87,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: Colors.grey.shade600,
          fontSize: 13,
        ),
      ),
      trailing: trailing ?? const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: AppColors.primary, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: Colors.grey.shade600,
          fontSize: 13,
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: AppColors.primary,
      ),
    );
  }

  Widget _buildDropdownTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required String value,
    required List<String> items,
    required ValueChanged<String> onChanged,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: AppColors.primary, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: Colors.grey.shade600,
          fontSize: 13,
        ),
      ),
      trailing: DropdownButton<String>(
        value: value,
        underline: const SizedBox(),
        items: items.map((item) {
          return DropdownMenuItem<String>(
            value: item,
            child: Text(item),
          );
        }).toList(),
        onChanged: (newValue) {
          if (newValue != null) onChanged(newValue);
        },
      ),
    );
  }

  // Navigation and action methods
  void _navigateToProfile() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Navigate to Edit Profile')),
    );
  }

  void _showChangePasswordDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Password'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Current Password',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'New Password',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Confirm New Password',
                border: OutlineInputBorder(),
              ),
            ),
          ],
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
                const SnackBar(content: Text('Password changed successfully')),
              );
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showPrivacySettings() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Navigate to Privacy Settings')),
    );
  }

  void _exportData() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Exporting data...')),
    );
  }

  void _showStorageUsage() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Storage Usage'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.image),
              title: Text('Photos'),
              trailing: Text('45.2 MB'),
            ),
            ListTile(
              leading: Icon(Icons.description),
              title: Text('Documents'),
              trailing: Text('12.8 MB'),
            ),
            ListTile(
              leading: Icon(Icons.storage),
              title: Text('Database'),
              trailing: Text('8.5 MB'),
            ),
            Divider(),
            ListTile(
              leading: Icon(Icons.folder),
              title: Text('Total Usage'),
              trailing: Text('66.5 MB'),
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

  void _syncData() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Syncing data with cloud...')),
    );
  }

  void _manageCattleCategories() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Navigate to Cattle Categories')),
    );
  }

  void _manageEventTypes() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Navigate to Event Types')),
    );
  }

  void _manageFarmLocations() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Navigate to Farm Locations')),
    );
  }

  void _configureReminders() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Navigate to Reminder Settings')),
    );
  }

  void _showHelpSupport() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Navigate to Help & Support')),
    );
  }

  void _sendFeedback() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Opening feedback form...')),
    );
  }

  void _rateApp() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Opening app store...')),
    );
  }

  void _showAboutDialog() {
    showAboutDialog(
      context: context,
      applicationName: 'Cattle Tracer',
      applicationVersion: '1.0.0',
      applicationLegalese: '© 2024 Cattle Tracer. All rights reserved.',
      children: [
        const SizedBox(height: 16),
        const Text('A comprehensive cattle management system for modern farmers.'),
      ],
    );
  }

  void _showDeveloperOptions() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Navigate to Developer Options')),
    );
  }

  void _reportBug() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Opening bug report form...')),
    );
  }

  void _showResetDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Settings'),
        content: const Text(
          'Are you sure you want to reset all settings to their default values? This action cannot be undone.',
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
                const SnackBar(
                  content: Text('Settings reset to default'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }
}