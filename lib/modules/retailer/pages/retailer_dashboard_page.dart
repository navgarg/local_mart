import 'package:flutter/material.dart';
import 'package:local_mart/modules/address/widgets/custom_button.dart';

class RetailerDashboardPage extends StatelessWidget {
  const RetailerDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Retailer Dashboard'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Welcome to the Retailer Dashboard!'),
            const SizedBox(height: 20),
            CustomButton(
              text: "Manage My Products",
              onPressed: () {
                        Navigator.pushNamed(context, '/retailer-inventory');
                      },
            ),
          ],
        ),
      ),
    );
  }
}