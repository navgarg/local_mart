import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> updateUserCategoryStats(String userId, List<dynamic> items) async {
  final userRef = FirebaseFirestore.instance.collection('users').doc(userId);

  // Step 1: Count categories first
  final Map<String, int> newCounts = {};

  for (var item in items) {
    String? productPath;

    if (item is Map && item['productPath'] is String) {
      productPath = item['productPath'];
    } else {
      try {
        final dynamic maybePath = item.productPath;
        if (maybePath is String) productPath = maybePath;
      } catch (_) {}
    }
    if (productPath == null || productPath.isEmpty) continue;

    final parts = productPath.split('/');
    if (parts.length <= 2) continue;

    final category = parts[2];

    newCounts[category] = (newCounts[category] ?? 0) + 1;
  }

  if (newCounts.isEmpty) return;

  // Step 2: Use a transaction to merge counts into the MAP
  await FirebaseFirestore.instance.runTransaction((transaction) async {
    final snapshot = await transaction.get(userRef);

    final Map<String, dynamic> existingStats = snapshot.exists
        ? Map<String, dynamic>.from(
        (snapshot.data() as Map<String, dynamic>)['categoryStats'] ?? {})
        : {};

    newCounts.forEach((category, count) {
      existingStats[category] = (existingStats[category] ?? 0) + count;
    });


    transaction.set(
      userRef,
      {'categoryStats': existingStats},
      SetOptions(merge: true),
    );
  });
}
