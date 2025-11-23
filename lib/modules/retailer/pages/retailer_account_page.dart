import 'package:flutter/material.dart';

class RetailerAccountPage extends StatefulWidget {
  const RetailerAccountPage({super.key});

  @override
  State<RetailerAccountPage> createState() => _RetailerAccountPageState();
}

class _RetailerAccountPageState extends State<RetailerAccountPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(

      body: ListView(
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
          _buildOptionTile(
            icon: Icons.help,
            title: 'Support',
            onTap: () {},
          ),
          _buildOptionTile(
            icon: Icons.feedback,
            title: 'Feedback',
            onTap: () {},
          ),
          _buildOptionTile(
            icon: Icons.logout,
            title: 'Logout',
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildOptionTile({required IconData icon, required String title, required VoidCallback onTap}) {
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
