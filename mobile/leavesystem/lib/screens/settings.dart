import 'package:flutter/material.dart';
import 'package:leavesystem/screens/login.dart';
import 'package:shared_preferences/shared_preferences.dart';


const Color primaryColor = Color(0xFF006400);
const Color secondaryColor = Color(0xFF388E3C);
const Color errorColor = Color(0xFFD32F2F);
const double defaultPadding = 16.0;

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isDarkMode = false;

  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Clear saved user data
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Logged out successfully')),
    );

    // Go back to login screen
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  void _toggleDarkMode(bool value) {
    setState(() {
      _isDarkMode = value;
    });

    final theme = Theme.of(context);
    final newThemeMode = _isDarkMode ? ThemeMode.dark : ThemeMode.light;

    // Apply theme globally (for demonstration)
    runApp(MaterialApp(
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: newThemeMode,
      home: const SettingsScreen(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _isDarkMode ? Colors.black : const Color(0xFFF6F8FA),
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 3,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(defaultPadding),
        children: [
          // --- Account Section ---
          const Text(
            'Account Settings',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          _buildSettingsCard(
            items: [
              _settingsTile(
                icon: Icons.person,
                title: 'Profile Information',
                subtitle: 'View and update your profile',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ProfileScreen()),
                  );
                },
              ),
              _divider(),
              _settingsTile(
                icon: Icons.lock,
                title: 'Change Password',
                subtitle: 'Update your login password',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ChangePasswordScreen()),
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 16),

          // --- App Section ---
          const Text(
            'App Settings',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          _buildSettingsCard(
            items: [
              SwitchListTile(
                secondary: const Icon(Icons.dark_mode, color: primaryColor),
                title: const Text('Dark Mode'),
                subtitle: const Text('Switch between light and dark theme'),
                activeTrackColor: secondaryColor,
                value: _isDarkMode,
                onChanged: _toggleDarkMode,
              ),
            ],
          ),

          const SizedBox(height: 16),

          // --- About Section ---
          const Text(
            'About',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          _buildSettingsCard(
            items: [
              _settingsTile(
                icon: Icons.info_outline,
                title: 'About EVS',
                subtitle: 'Version 1.0.0',
                onTap: () {
                  showAboutDialog(
                    context: context,
                    applicationName: 'Employee Verification System',
                    applicationVersion: '1.0.0',
                    children: const [
                      Text(
                          'EVS helps verify employees securely to eliminate ghost workers.'),
                    ],
                  );
                },
              ),
              _divider(),
              _settingsTile(
                icon: Icons.help_outline,
                title: 'Help & Support',
                subtitle: 'Contact support team',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Support: support@evs.gov.za')),
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 24),

          // --- Logout Button ---
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.logout),
              label: const Text(
                'Logout',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: errorColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 3,
              ),
              onPressed: () => _logout(context),
            ),
          ),
        ],
      ),
    );
  }

  // === Helper Widgets ===
  Widget _buildSettingsCard({required List<Widget> items}) {
    return Card(
      elevation: 3,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(children: items),
    );
  }

  static Widget _settingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: primaryColor),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }

  static Widget _divider() => const Divider(
        height: 1,
        color: Colors.black12,
        indent: 16,
        endIndent: 16,
      );
}

// --- Dummy Pages ---
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Profile"), backgroundColor: primaryColor),
      body: const Center(child: Text("Profile Information Page")),
    );
  }
}

class ChangePasswordScreen extends StatelessWidget {
  const ChangePasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
          AppBar(title: const Text("Change Password"), backgroundColor: primaryColor),
      body: const Center(child: Text("Change Password Page")),
    );
  }
}
