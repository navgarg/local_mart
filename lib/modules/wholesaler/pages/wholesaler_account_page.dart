import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:local_mart/models/app_user.dart';
import 'package:local_mart/modules/wholesaler/pages/wholesaler_order_history_page.dart';

class WholesalerAccountPage extends StatefulWidget {
  const WholesalerAccountPage({super.key});

  @override
  State<WholesalerAccountPage> createState() => _WholesalerAccountPageState();
}

class _WholesalerAccountPageState extends State<WholesalerAccountPage> {
  String username = '';
  String mobile = '';
  Map<String, dynamic>? address;
  bool loading = true;

  final _nameCtrl = TextEditingController();
  final _mobileCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    final data = doc.data();
    if (doc.exists && data != null) {
      final appUser = AppUser.fromFirestore(doc);
      if (mounted) {
        setState(() {
          username = appUser.username ?? '';
          mobile = appUser.mobile ?? '';
          address = appUser.address;
          _nameCtrl.text = username;
          _mobileCtrl.text = mobile;
          loading = false;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  Future<void> _saveProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid);
    final doc = await userRef.get();

    if (doc.exists) {
      final appUser = AppUser.fromFirestore(doc);
      final updatedAppUser = AppUser(
        uid: appUser.uid,
        username: _nameCtrl.text.trim(),
        email: appUser.email,
        mobile: _mobileCtrl.text.trim(),
        photoURL: appUser.photoURL,
        provider: appUser.provider,
        createdAt: appUser.createdAt,
        lastLogin: appUser.lastLogin,
        address: appUser.address,
        categoryStats: appUser.categoryStats,
        role: appUser.role,
        retailerName: appUser.retailerName,
        retailerAddress: appUser.retailerAddress,
        wholesalerIds: appUser.wholesalerIds,
        wholesalerName: appUser.wholesalerName,
        wholesalerAddress: appUser.wholesalerAddress,
        retailerIds: appUser.retailerIds,
      );
      await userRef.set(updatedAppUser.toFirestore());
    } else {
      debugPrint("User document not found for update.");
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Profile updated')));
    if (mounted) {
      _loadProfile();
    }
  }

  void _showFeedbackDialog() {
    final feedbackCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Feedback'),
        content: TextField(
            controller: feedbackCtrl,
            maxLines: 4,
            decoration: const InputDecoration(hintText: 'Write feedback...'),
          ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
          feedbackCtrl.dispose();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Feedback submitted successfully, thank you!'),
              ),
            );
          }
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  void _showSupport() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Customer Support'),
        content: const Text(
          'For customer support and queries contact:\n\n'
          '📧 Email: localmart996@gmail.com\n'
          '📞 Phone: 93400XXXXX, 94400XXXXX',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showAddressSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        if (!mounted) return Container();
        final addr = address != null
            ? [
                    address?['flatNo'],
                    address?['building'],
                    address?['area'],
                    address?['city'],
                    address?['state'],
                    address?['pincode'],
                  ]
                  .where((e) => e != null && e.toString().trim().isNotEmpty)
                  .map((e) => e.toString().trim())
                  .join(', ')
            : 'No address available';

        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your Address',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  addr,
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.4,
                    color: Colors.black87,
                  ),
                  softWrap: true,
                ),
                const SizedBox(height: 25),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      Future.microtask(() {
                        if (context.mounted) {
                          Navigator.pushNamed(
                            context,
                            '/map-picker',
                            arguments: {'role': 'Wholesaler'},
                          ).then((_) {
                            _loadProfile();
                          });
                        }
                      });
                    },
                    icon: const Icon(
                      Icons.location_on_outlined,
                      color: Colors.white,
                    ),
                    label: const Text('Change Address on Map'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00A693),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAppSettingsSheet() {
    bool notifications = true;
    bool darkMode = false;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        if (!mounted) return Container();
        return StatefulBuilder(
          builder: (ctx, setModalState) => Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'App Settings',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 10),
                SwitchListTile(
                  title: const Text('Notifications'),
                  value: notifications,
                  onChanged: (v) => setModalState(() => notifications = v),
                ),
                SwitchListTile(
                  title: const Text('Dark Mode'),
                  value: darkMode,
                  onChanged: (v) => setModalState(() => darkMode = v),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );
  }

  void _logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Logged out')));
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    }
  }

  Widget _buildOptionTile(IconData icon, String title, VoidCallback onTap) {
    return Column(
      children: [
        ListTile(
          leading: Icon(icon, color: Colors.black87),
          title: Text(title, style: GoogleFonts.inter(fontSize: 15)),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: onTap,
        ),
        Divider(color: Colors.grey[200], height: 1),
      ],
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _mobileCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 32,
                child: Icon(Icons.person, size: 36),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            username,
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (ctx) {
                                return Dialog(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  insetPadding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 24,
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(20),
                                      color: Colors.white,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha:0.1),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Center(
                                          child: Text(
                                            'Edit Profile',
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w700,
                                                  color: const Color(
                                                    0xFF00A693,
                                                  ),
                                                ),
                                          ),
                                        ),
                                        const SizedBox(height: 20),
                                        TextField(
                                          controller: _nameCtrl,
                                          decoration: InputDecoration(
                                            labelText: 'Name',
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              borderSide: const BorderSide(
                                                color: Color(0xFF00A693),
                                                width: 1.5,
                                              ),
                                            ),
                                            prefixIcon: const Icon(
                                              Icons.person_outline,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        TextField(
                                          controller: _mobileCtrl,
                                          keyboardType: TextInputType.phone,
                                          decoration: InputDecoration(
                                            labelText: 'Phone',
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              borderSide: const BorderSide(
                                                color: Color(0xFF00A693),
                                                width: 1.5,
                                              ),
                                            ),
                                            prefixIcon: const Icon(
                                              Icons.phone_outlined,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 24),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(ctx),
                                              child: const Text(
                                                'Cancel',
                                                style: TextStyle(
                                                  color: Colors.black54,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                            ElevatedButton(
                                              onPressed: () {
                                                _saveProfile();
                                                Navigator.pop(ctx);
                                              },
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: const Color(
                                                  0xFF00A693,
                                                ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 24,
                                                      vertical: 10,
                                                    ),
                                              ),
                                              child: const Text(
                                                'Save',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                          icon: const Icon(Icons.edit),
                        ),
                      ],
                    ),
                    Text(mobile, style: const TextStyle(color: Colors.black54)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 25),

          // Options List
          _buildOptionTile(
            Icons.home_outlined,
            'Your Address',
            _showAddressSheet,
          ),
          _buildOptionTile(Icons.receipt_long_outlined, 'Your Orders', () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const WholesalerOrderHistoryPage()),
            );
          }),
          _buildOptionTile(
            Icons.settings_outlined,
            'App Settings',
            _showAppSettingsSheet,
          ),
          _buildOptionTile(Icons.info_outline, 'Legal & About', () {}),
          _buildOptionTile(
            Icons.feedback_outlined,
            'Feedback',
            _showFeedbackDialog,
          ),
          _buildOptionTile(
            Icons.support_agent_outlined,
            'Customer Support',
            _showSupport,
          ),

          const Spacer(),

          Center(
            child: ElevatedButton.icon(
              onPressed: _logout,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
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
}