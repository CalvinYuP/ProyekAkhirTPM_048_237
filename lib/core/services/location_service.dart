// lib/core/services/location_service.dart
import 'package:geolocator/geolocator.dart';

class LocationService {
  Future<bool> checkPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return false;
    }
    return permission == LocationPermission.whileInUse || permission == LocationPermission.always;
  }

  Future<Position> getCurrentLocation() async {
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  double calculateDistance(double userLat, double userLng, double destLat, double destLng) {
    return Geolocator.distanceBetween(userLat, userLng, destLat, destLng) / 1000; // km
  }

  String formatDistance(double distanceKm) {
    if (distanceKm < 1) return '${(distanceKm * 1000).toStringAsFixed(0)} m';
    return '${distanceKm.toStringAsFixed(1)} km';
  }
}