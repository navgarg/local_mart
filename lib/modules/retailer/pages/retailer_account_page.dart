import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class RetailerAccountPage extends StatefulWidget {
  const RetailerAccountPage({super.key});

  @override
  State<RetailerAccountPage> createState() => _RetailerAccountPageState();
}

class _RetailerAccountPageState extends State<RetailerAccountPage> {
  void _logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Logged out')));
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildOptionTile(
            icon: Icons.person,
            title: 'Edit Profile',
            onTap: () {},
          ),
          _buildOptionTile(
            icon: Icons.location_on,
            title: 'Manage Addresses',
            onTap: () {},
          ),
          _buildOptionTile(
            icon: Icons.settings,
            title: 'App Settings',
            onTap: () {},
          ),
          _buildOptionTile(icon: Icons.help, title: 'Support', onTap: () {}),
          _buildOptionTile(
            icon: Icons.feedback,
            title: 'Feedback',
            onTap: () {},
          ),
          const Spacer(),

          Center(
            child: ElevatedButton.icon(
              onPressed: _logout,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 30,
                  vertical: 12,
                ),
                minimumSize: const Size(double.infinity, 0),
              ),
              icon: const Icon(Icons.logout, color: Colors.white),
              label: Text(
                'Logout',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).primaryColor),
        title: Text(title),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: onTap,
      ),
    );
  }
}
