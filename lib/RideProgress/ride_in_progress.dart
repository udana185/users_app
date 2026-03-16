import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class RideInProgressPage extends StatefulWidget {
  final LatLng pickupLatLng;
  final LatLng destinationLatLng;
  final String pickupText;
  final String destinationText;
  final String routeDistanceText;
  final String routeDurationText;
  final List<LatLng> routeCoords;

  const RideInProgressPage({
    super.key,
    required this.pickupLatLng,
    required this.destinationLatLng,
    required this.pickupText,
    required this.destinationText,
    required this.routeDistanceText,
    required this.routeDurationText,
    required this.routeCoords,
  });

  @override
  State<RideInProgressPage> createState() => _RideInProgressPageState();
}

class _RideInProgressPageState extends State<RideInProgressPage> {
  GoogleMapController? mapController;

  late final Set<Marker> markers;
  late final Set<Polyline> polylines;

  @override
  void initState() {
    super.initState();

    markers = {
      Marker(
        markerId: const MarkerId("pickup"),
        position: widget.pickupLatLng,
        infoWindow: const InfoWindow(title: "Pickup"),
      ),
      Marker(
        markerId: const MarkerId("destination"),
        position: widget.destinationLatLng,
        infoWindow: const InfoWindow(title: "Destination"),
      ),
    };

    polylines = {
      Polyline(
        polylineId: const PolylineId("ride_route"),
        points: widget.routeCoords,
        width: 6,
        color: Colors.black,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
        jointType: JointType.round,
      ),
    };
  }

  LatLngBounds _boundsFromLatLngList(List<LatLng> list) {
    double minLat = list.first.latitude;
    double maxLat = list.first.latitude;
    double minLng = list.first.longitude;
    double maxLng = list.first.longitude;

    for (final LatLng point in list) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }

    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }

  void _fitRoute() {
    final bounds = _boundsFromLatLngList([
      widget.pickupLatLng,
      widget.destinationLatLng,
      ...widget.routeCoords,
    ]);

    mapController?.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 70),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Ride in Progress"),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: widget.pickupLatLng,
              zoom: 14,
            ),
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            markers: markers,
            polylines: polylines,
            onMapCreated: (controller) {
              mapController = controller;
              Future.delayed(const Duration(milliseconds: 300), _fitRoute);
            },
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Pickup: ${widget.pickupText}",
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Destination: ${widget.destinationText}",
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(Icons.route, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                widget.routeDistanceText,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            Text(
                              widget.routeDurationText,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context, "ended");
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 17),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: const Text(
                        "End Ride",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}