// lib/features/detail/widgets/location_map.dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../../data/models/destination_model.dart';
import '../../../../core/constants/app_colors.dart';

class LocationMap extends StatelessWidget {
  final Destination destination;
  
  const LocationMap({super.key, required this.destination});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 250,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: FlutterMap(
          options: MapOptions(
            initialCenter: LatLng(destination.latitude, destination.longitude),
            initialZoom: 14.0,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.jogja_ethno_trip',
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: LatLng(destination.latitude, destination.longitude),
                  width: 60,
                  height: 60,
                  child: const Icon(
                    Icons.location_pin,
                    color: AppColors.primary,
                    size: 40,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}