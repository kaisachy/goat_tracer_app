import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../constants/app_colors.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  
  // Default center coordinates for Province of Isabela, Philippines
  static const LatLng _defaultCenter = LatLng(16.9754, 122.0107); // Isabela coordinates (moved slightly east)
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: _defaultCenter,
          initialZoom: 8.5, // Reduced zoom level to show broader view of Isabela province
          minZoom: 3.0,
          maxZoom: 18.0,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.cattle_tracer_app',
            maxZoom: 19,
          ),
          // You can add markers, polylines, polygons here later
          // For example:
          // MarkerLayer(
          //   markers: [
          //     Marker(
          //       point: LatLng(51.509364, -0.128928),
          //       width: 80,
          //       height: 80,
          //       child: Icon(Icons.location_on, color: Colors.red),
          //     ),
          //   ],
          // ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: "zoomIn",
            onPressed: () {
              _mapController.move(
                _mapController.camera.center,
                _mapController.camera.zoom + 1,
              );
            },
            backgroundColor: AppColors.darkGreen,
            child: const Icon(Icons.add, color: Colors.white),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            heroTag: "zoomOut",
            onPressed: () {
              _mapController.move(
                _mapController.camera.center,
                _mapController.camera.zoom - 1,
              );
            },
            backgroundColor: AppColors.darkGreen,
            child: const Icon(Icons.remove, color: Colors.white),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            heroTag: "center",
            onPressed: () {
              _mapController.move(_defaultCenter, 10.0);
            },
            backgroundColor: AppColors.darkGreen,
            child: const Icon(Icons.my_location, color: Colors.white),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }
}
