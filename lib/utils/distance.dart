// lib/utils/distance.dart
import 'dart:math';

/// Returns distance in kilometers between two lat/lng points using Haversine.
double distanceKm({
  required double lat1,
  required double lng1,
  required double lat2,
  required double lng2,
}) {
  const R = 6371.0; // Earth radius in km
  double toRad(double deg) => deg * pi / 180.0;
  final dLat = toRad(lat2 - lat1);
  final dLon = toRad(lng2 - lng1);
  final a = sin(dLat / 2) * sin(dLat / 2) +
      cos(toRad(lat1)) * cos(toRad(lat2)) * sin(dLon / 2) * sin(dLon / 2);
  final c = 2 * atan2(sqrt(a), sqrt(1 - a));
  return R * c;
}

/// Return number of delivery days according to your table:
/// <=5km:1, <=200:2, <=800:3, <=1000:4, <=2000:5, otherwise 7 days
int deliveryDaysForDistanceKm(double km) {
  if (km <= 5) {
    return 1;
  } else if (km <= 200) {
    return 2;
  } else if (km <= 800) {
    return 3;
  } else if (km <= 1000) {
    return 4;
  } else if (km <= 2000) {
    return 5;
  } else {
    return 7;
  }
}

/// Returns a formatted 'Deliver by DD MMM YYYY' string using current date + days
String deliverByStringFromDistance(double km) {
  final days = deliveryDaysForDistanceKm(km);
  final deliverDate = DateTime.now().add(Duration(days: days));
  // e.g., "Deliver by 12 Nov 2025"
  final monthNames = [
    'Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'
  ];
  final dateStr = '${deliverDate.day} ${monthNames[deliverDate.month - 1]} ${deliverDate.year}';
  return 'Deliver by $dateStr';
}
