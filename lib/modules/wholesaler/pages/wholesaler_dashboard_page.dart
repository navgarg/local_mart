import 'package:flutter/material.dart';
import 'package:local_mart/modules/address/widgets/custom_button.dart';

class WholesalerDashboardPage extends StatelessWidget {
  const WholesalerDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wholesaler Dashboard'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Welcome to the Wholesaler Dashboard!'),
            const SizedBox(height: 20),
            CustomButton(
              text: "View My Orders",
              onPressed: () {
                        Navigator.pushNamed(context, '/wholesaler-retailer-history');
                      },
            ),
          ],
        ),
      ),
    );
  }
}