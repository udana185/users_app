import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_polyline_points/flutter_polyline_points.dart';

import 'package:users_app/RideProgress/ride_in_progress.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class HomeTabPage extends StatefulWidget {
  const HomeTabPage({super.key});

  @override
  State<HomeTabPage> createState() => _HomeTabPageState();
}

class _HomeTabPageState extends State<HomeTabPage> {
  GoogleMapController? newGoogleMapController;
  final Completer<GoogleMapController> _controllerGoogleMap =
  Completer<GoogleMapController>();

  String? currentRideRequestId;
  StreamSubscription? rideSubscription;


  final TextEditingController pickupController = TextEditingController();
  final TextEditingController destinationController = TextEditingController();

  final FocusNode pickupFocusNode = FocusNode();
  final FocusNode destinationFocusNode = FocusNode();

  final String googleMapKey = "AIzaSyDYZRQPiJi7mk3ss6KwtHcmvI8jHmc7kGo";
  final String routesApiKey = "AIzaSyB-XuBNS7hIvk9vgRu4rEfo0uRkWnxio3o";

  static const CameraPosition _initialCameraPosition = CameraPosition(
    target: LatLng(7.8731, 80.7718),
    zoom: 7,
  );

  LatLng? currentMapCenter;
  LatLng? pickupLatLng;
  LatLng? destinationLatLng;

  bool isMapMoving = false;
  bool selectingPickup = true;
  bool selectingDestination = false;
  bool suppressTextListener = false;
  bool isLoadingSuggestions = false;
  bool isFetchingRoute = false;

  Timer? _debounce;

  List<PlaceSuggestion> suggestions = [];

  Set<Polyline> polylines = {};
  Set<Marker> markers = {};

  String? routeDistanceText;
  String? routeDurationText;

  bool hasOngoingRide = false;
  List<LatLng> ongoingRouteCoords = [];
  String? ongoingRouteDistanceText;
  String? ongoingRouteDurationText;
  String? ongoingPickupText;
  String? ongoingDestinationText;
  LatLng? ongoingPickupLatLng;
  LatLng? ongoingDestinationLatLng;

  @override
  void initState() {
    super.initState();
    checkIfLocationPermissionAllowed();

    pickupFocusNode.addListener(() {
      if (pickupFocusNode.hasFocus) {
        setState(() {
          selectingPickup = true;
          selectingDestination = false;
        });

        if (pickupController.text.trim().isNotEmpty) {
          _searchPlaces(pickupController.text.trim());
        }
      }
    });

    destinationFocusNode.addListener(() {
      if (destinationFocusNode.hasFocus) {
        setState(() {
          selectingPickup = false;
          selectingDestination = true;
        });

        if (destinationController.text.trim().isNotEmpty) {
          _searchPlaces(destinationController.text.trim());
        }
      }
    });

    pickupController.addListener(() {
      if (suppressTextListener) return;
      if (pickupFocusNode.hasFocus) {
        setState(() {
          selectingPickup = true;
          selectingDestination = false;
        });
        _onSearchTextChanged(pickupController.text);
      }
    });

    destinationController.addListener(() {
      if (suppressTextListener) return;
      if (destinationFocusNode.hasFocus) {
        setState(() {
          selectingPickup = false;
          selectingDestination = true;
        });
        _onSearchTextChanged(destinationController.text);
      }
    });
  }

  void _onSearchTextChanged(String value) {
    _debounce?.cancel();

    if (value.trim().isEmpty) {
      setState(() {
        suggestions = [];
        isLoadingSuggestions = false;
      });
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 450), () {
      _searchPlaces(value.trim());
    });
  }

  Future<void> _searchPlaces(String input) async {
    final String encodedInput = Uri.encodeComponent(input);

    final String url =
        "https://maps.googleapis.com/maps/api/place/autocomplete/json"
        "?input=$encodedInput"
        "&components=country:lk"
        "&key=$googleMapKey";

    setState(() {
      isLoadingSuggestions = true;
    });

    try {
      final response = await http.get(Uri.parse(url));
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data["status"] == "OK") {
        final List predictions = data["predictions"] ?? [];

        setState(() {
          suggestions = predictions.map((item) {
            return PlaceSuggestion(
              description: item["description"] ?? "",
              placeId: item["place_id"] ?? "",
              mainText: item["structured_formatting"]?["main_text"] ??
                  item["description"] ??
                  "",
              secondaryText:
              item["structured_formatting"]?["secondary_text"] ?? "",
            );
          }).toList();
        });
      } else if (response.statusCode == 200 &&
          data["status"] == "ZERO_RESULTS") {
        setState(() {
          suggestions = [];
        });
      } else {
        debugPrint("Autocomplete error: ${response.body}");
        setState(() {
          suggestions = [];
        });
      }
    } catch (e) {
      debugPrint("Autocomplete request failed: $e");
      setState(() {
        suggestions = [];
      });
    } finally {
      if (mounted) {
        setState(() {
          isLoadingSuggestions = false;
        });
      }
    }
  }

  Future<void> _selectSuggestion(PlaceSuggestion suggestion) async {
    FocusScope.of(context).unfocus();

    final String url =
        "https://maps.googleapis.com/maps/api/place/details/json"
        "?place_id=${suggestion.placeId}"
        "&fields=name,formatted_address,geometry"
        "&key=$googleMapKey";

    try {
      final response = await http.get(Uri.parse(url));
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data["result"] != null) {
        final result = data["result"];
        final String address =
            result["formatted_address"] ?? suggestion.description;

        final double lat = result["geometry"]["location"]["lat"].toDouble();
        final double lng = result["geometry"]["location"]["lng"].toDouble();

        final LatLng selectedLatLng = LatLng(lat, lng);

        suppressTextListener = true;

        if (selectingPickup) {
          pickupController.text = address;
          pickupController.selection = TextSelection.fromPosition(
            TextPosition(offset: pickupController.text.length),
          );
          pickupLatLng = selectedLatLng;
        } else {
          destinationController.text = address;
          destinationController.selection = TextSelection.fromPosition(
            TextPosition(offset: destinationController.text.length),
          );
          destinationLatLng = selectedLatLng;
        }

        suppressTextListener = false;

        _clearPreviewRouteState();
        _updateMarkers();

        setState(() {
          currentMapCenter = selectedLatLng;
          suggestions = [];
        });

        await newGoogleMapController?.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: selectedLatLng,
              zoom: 16,
            ),
          ),
        );
      } else {
        debugPrint("Place details error: ${response.body}");
      }
    } catch (e) {
      debugPrint("Place details request failed: $e");
    }
  }

  void _clearPreviewRouteState() {
    setState(() {
      polylines.clear();
      routeDistanceText = null;
      routeDurationText = null;
    });
  }

  void _endOngoingRide() {
    setState(() {
      polylines.clear();
      routeDistanceText = null;
      routeDurationText = null;

      hasOngoingRide = false;
      ongoingRouteCoords = [];
      ongoingRouteDistanceText = null;
      ongoingRouteDurationText = null;
      ongoingPickupText = null;
      ongoingDestinationText = null;
      ongoingPickupLatLng = null;
      ongoingDestinationLatLng = null;
    });
  }

  void _updateMarkers() {
    final Set<Marker> updatedMarkers = {};

    if (pickupLatLng != null) {
      updatedMarkers.add(
        Marker(
          markerId: const MarkerId("pickup"),
          position: pickupLatLng!,
          infoWindow: const InfoWindow(title: "Pickup"),
        ),
      );
    }

    if (destinationLatLng != null) {
      updatedMarkers.add(
        Marker(
          markerId: const MarkerId("destination"),
          position: destinationLatLng!,
          infoWindow: const InfoWindow(title: "Destination"),
        ),
      );
    }

    setState(() {
      markers = updatedMarkers;
    });
  }

  Future<void> checkIfLocationPermissionAllowed() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint("Location services are disabled.");
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      debugPrint("Location permission permanently denied");
      return;
    }
  }

  Future<void> locatePosition() async {
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    final LatLng latLngPosition = LatLng(position.latitude, position.longitude);

    currentMapCenter = latLngPosition;
    pickupLatLng = latLngPosition;

    await updatePickupAddressFromCoordinates(latLngPosition);
    _updateMarkers();

    newGoogleMapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: latLngPosition,
          zoom: 14,
        ),
      ),
    );
  }

  Future<void> updatePickupAddressFromCoordinates(LatLng center) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        center.latitude,
        center.longitude,
      );

      if (placemarks.isNotEmpty) {
        final Placemark place = placemarks.first;

        final String address = [
          place.name,
          place.locality,
          place.administrativeArea,
          place.country,
        ].where((part) => part != null && part.trim().isNotEmpty).join(", ");

        suppressTextListener = true;
        setState(() {
          pickupController.text = address;
        });
        suppressTextListener = false;
      }
    } catch (e) {
      debugPrint("Error updating pickup address: $e");
    }
  }

  Future<void> updateDestinationAddressFromCoordinates(LatLng center) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        center.latitude,
        center.longitude,
      );

      if (placemarks.isNotEmpty) {
        final Placemark place = placemarks.first;

        final String address = [
          place.name,
          place.locality,
          place.administrativeArea,
          place.country,
        ].where((part) => part != null && part.trim().isNotEmpty).join(", ");

        suppressTextListener = true;
        setState(() {
          destinationController.text = address;
        });
        suppressTextListener = false;
      }
    } catch (e) {
      debugPrint("Error updating destination address: $e");
    }
  }

  void selectPickupMode() {
    FocusScope.of(context).requestFocus(pickupFocusNode);

    setState(() {
      selectingPickup = true;
      selectingDestination = false;
    });

    if (pickupLatLng != null) {
      newGoogleMapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: pickupLatLng!,
            zoom: 16,
          ),
        ),
      );
    }
  }

  void selectDestinationMode() {
    FocusScope.of(context).requestFocus(destinationFocusNode);

    setState(() {
      selectingPickup = false;
      selectingDestination = true;
    });

    if (destinationLatLng != null) {
      newGoogleMapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: destinationLatLng!,
            zoom: 16,
          ),
        ),
      );
    }
  }

  Future<void> openOngoingRidePage() async {
    if (!hasOngoingRide ||
        ongoingPickupLatLng == null ||
        ongoingDestinationLatLng == null ||
        ongoingRouteDistanceText == null ||
        ongoingRouteDurationText == null) {
      return;
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RideInProgressPage(
          pickupLatLng: ongoingPickupLatLng!,
          destinationLatLng: ongoingDestinationLatLng!,
          pickupText: ongoingPickupText ?? "",
          destinationText: ongoingDestinationText ?? "",
          routeDistanceText: ongoingRouteDistanceText!,
          routeDurationText: ongoingRouteDurationText!,
          routeCoords: ongoingRouteCoords,
        ),
      ),
    );

    if (result == "ended") {
      _endOngoingRide();
    }
  }

  Future<void> bookRideAndDrawRoute() async {
    if (pickupLatLng == null || destinationLatLng == null) return;

    FocusScope.of(context).unfocus();
    setState(() {
      suggestions = [];
      isFetchingRoute = true;
    });

    final Uri url = Uri.parse(
      "https://routes.googleapis.com/directions/v2:computeRoutes",
    );

    final Map<String, dynamic> body = {
      "origin": {
        "location": {
          "latLng": {
            "latitude": pickupLatLng!.latitude,
            "longitude": pickupLatLng!.longitude,
          }
        }
      },
      "destination": {
        "location": {
          "latLng": {
            "latitude": destinationLatLng!.latitude,
            "longitude": destinationLatLng!.longitude,
          }
        }
      },
      "travelMode": "DRIVE",
      "routingPreference": "TRAFFIC_AWARE",
      "polylineQuality": "HIGH_QUALITY",
    };

    try {
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "X-Goog-Api-Key": routesApiKey,
          "X-Goog-FieldMask":
          "routes.distanceMeters,routes.duration,routes.polyline.encodedPolyline",
        },
        body: jsonEncode(body),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 &&
          data["routes"] != null &&
          data["routes"].isNotEmpty) {
        final route = data["routes"][0];

        final String encoded = route["polyline"]["encodedPolyline"];
        final int distanceMeters = route["distanceMeters"] ?? 0;
        final String durationRaw = route["duration"] ?? "0s";

        final List<PointLatLng> decodedPoints =
        PolylinePoints.decodePolyline(encoded);

        final List<LatLng> routeCoords = decodedPoints
            .map((point) => LatLng(point.latitude, point.longitude))
            .toList();

        final double km = distanceMeters / 1000.0;
        final int totalSeconds = _parseDurationToSeconds(durationRaw);

        final String distanceText = "${km.toStringAsFixed(1)} km";
        final String durationText = _formatDuration(totalSeconds);


        final rideRequestId = await RideRequestService().createRideRequest(
          userId: "user1",
          pickupText: pickupController.text,
          destinationText: destinationController.text,
          pickupLatLng: pickupLatLng!,
          destinationLatLng: destinationLatLng!,
          distanceText: distanceText,
          durationText: durationText,
          routeCoords: routeCoords,
        );

        startListeningToRide(rideRequestId);

        setState(() {
          currentRideRequestId = rideRequestId;
          ongoingRouteCoords = routeCoords;
          ongoingRouteDistanceText = distanceText;
          ongoingRouteDurationText = durationText;
          ongoingPickupText = pickupController.text;
          ongoingDestinationText = destinationController.text;
          ongoingPickupLatLng = pickupLatLng;
          ongoingDestinationLatLng = destinationLatLng;
          hasOngoingRide = true;
        });

        await openOngoingRidePage();
      } else {
        debugPrint("Route error: ${response.body}");
      }
    } catch (e) {
      debugPrint("Failed to fetch route: $e");
    } finally {
      if (mounted) {
        setState(() {
          isFetchingRoute = false;
        });
      }
    }
  }







  int _parseDurationToSeconds(String durationRaw) {
    final String cleaned = durationRaw.replaceAll("s", "");
    return int.tryParse(cleaned) ?? 0;
  }

  String _formatDuration(int totalSeconds) {
    final int totalMinutes = (totalSeconds / 60).ceil();

    if (totalMinutes < 60) {
      return "$totalMinutes min";
    }

    final int hours = totalMinutes ~/ 60;
    final int minutes = totalMinutes % 60;

    if (minutes == 0) {
      return "$hours hr";
    }

    return "$hours hr $minutes min";
  }


  void startListeningToRide(String rideId) {

    rideSubscription?.cancel();

    rideSubscription = FirebaseFirestore.instance
        .collection('ride_requests')
        .doc(rideId)
        .snapshots()
        .listen((snapshot) {

      if (!snapshot.exists) return;

      final data = snapshot.data() as Map<String, dynamic>;
      final status = data['status'];

      if (status == 'accepted') {

        debugPrint("Driver accepted the ride");

        // ⭐ HERE you can move UI to driver arriving page later

      }
      else if (status == 'in_progress') {

        debugPrint("Ride started");

      }
      else if (status == 'completed') {

        debugPrint("Ride completed");

        _endOngoingRide();   // this already exists in your code
      }

    });
  }


  Widget buildLocationField({
    required String hintText,
    required IconData icon,
    required Color activeIconColor,
    required bool isSelected,
    required VoidCallback onTap,
    required TextEditingController controller,
    required FocusNode focusNode,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? Colors.black87 : Colors.grey.shade200,
            width: isSelected ? 1.4 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 16,
              spreadRadius: 1,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: isSelected
                    ? activeIconColor.withOpacity(0.12)
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isSelected ? activeIconColor : Colors.grey.shade700,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: hintText,
                  hintStyle: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                  border: InputBorder.none,
                  suffixIcon: controller.text.isNotEmpty
                      ? IconButton(
                    icon: Icon(
                      Icons.close_rounded,
                      color: Colors.grey.shade500,
                      size: 20,
                    ),
                    onPressed: () {
                      controller.clear();

                      if (controller == pickupController) {
                        pickupLatLng = null;
                      } else {
                        destinationLatLng = null;
                      }

                      _clearPreviewRouteState();
                      _updateMarkers();

                      setState(() {
                        suggestions = [];
                      });
                    },
                  )
                      : null,
                ),
                style: const TextStyle(
                  fontSize: 15,
                  color: Colors.black87,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildSuggestionsOverlay() {
    if (!pickupFocusNode.hasFocus &&
        !destinationFocusNode.hasFocus &&
        suggestions.isEmpty) {
      return const SizedBox.shrink();
    }

    final bool showCard = suggestions.isNotEmpty || isLoadingSuggestions;
    if (!showCard) return const SizedBox.shrink();

    final double topPosition = pickupFocusNode.hasFocus ? 120 : 190;

    return Positioned(
      top: topPosition,
      left: 16,
      right: 16,
      child: Material(
        elevation: 12,
        borderRadius: BorderRadius.circular(20),
        color: Colors.white,
        child: Container(
          constraints: const BoxConstraints(maxHeight: 280),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: isLoadingSuggestions
              ? const Padding(
            padding: EdgeInsets.all(18),
            child: Center(
              child: CircularProgressIndicator(strokeWidth: 2.4),
            ),
          )
              : ListView.separated(
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: suggestions.length,
            separatorBuilder: (_, __) => Divider(
              height: 1,
              color: Colors.grey.shade200,
              indent: 56,
              endIndent: 12,
            ),
            itemBuilder: (context, index) {
              final item = suggestions[index];
              return InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => _selectSuggestion(item),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.location_on_outlined,
                          size: 18,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.mainText,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                                color: Colors.black87,
                              ),
                            ),
                            if (item.secondaryText.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                item.secondaryText,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget buildBottomActionArea() {
    if (!hasOngoingRide &&
        (pickupLatLng == null || destinationLatLng == null)) {
      return const SizedBox.shrink();
    }

    return Positioned(
      left: 16,
      right: 16,
      bottom: 24,
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hasOngoingRide)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
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
                child: Row(
                  children: [
                    const Icon(Icons.directions_car, size: 20),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        "Ride in progress",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: openOngoingRidePage,
                      child: const Text("Go"),
                    ),
                  ],
                ),
              ),

            if (!hasOngoingRide)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isFetchingRoute ? null : bookRideAndDrawRoute,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    elevation: 8,
                    padding: const EdgeInsets.symmetric(vertical: 17),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: isFetchingRoute
                      ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                      : const Text(
                    "Book Ride",
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
    );
  }

  @override
  void dispose() {
    rideSubscription?.cancel();
    _debounce?.cancel();
    pickupController.dispose();
    destinationController.dispose();
    pickupFocusNode.dispose();
    destinationFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool typing =
        pickupFocusNode.hasFocus || destinationFocusNode.hasFocus;

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        setState(() {
          suggestions = [];
        });
      },
      child: Scaffold(
        body: Stack(
          alignment: Alignment.center,
          children: [
            GoogleMap(
              mapType: MapType.normal,
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              initialCameraPosition: _initialCameraPosition,
              polylines: polylines,
              markers: markers,
              onMapCreated: (GoogleMapController controller) {
                if (!_controllerGoogleMap.isCompleted) {
                  _controllerGoogleMap.complete(controller);
                }
                newGoogleMapController = controller;
                locatePosition();
              },
              onTap: (_) {
                FocusScope.of(context).unfocus();
                setState(() {
                  suggestions = [];
                });
              },
              onCameraMove: (CameraPosition position) {
                currentMapCenter = position.target;

                if (!isMapMoving) {
                  setState(() {
                    isMapMoving = true;
                  });
                }
              },
              onCameraIdle: () async {
                if (currentMapCenter != null && !typing) {
                  if (selectingPickup) {
                    pickupLatLng = currentMapCenter;
                    await updatePickupAddressFromCoordinates(currentMapCenter!);
                  } else if (selectingDestination) {
                    destinationLatLng = currentMapCenter;
                    await updateDestinationAddressFromCoordinates(
                      currentMapCenter!,
                    );
                  }

                  _clearPreviewRouteState();
                  _updateMarkers();
                }

                setState(() {
                  isMapMoving = false;
                });
              },
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(top: 12, left: 16, right: 16),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      buildLocationField(
                        hintText: "Enter pickup location",
                        icon: Icons.my_location,
                        activeIconColor: Colors.blue,
                        isSelected: selectingPickup,
                        onTap: selectPickupMode,
                        controller: pickupController,
                        focusNode: pickupFocusNode,
                      ),
                      buildLocationField(
                        hintText: "Where to?",
                        icon: Icons.location_on,
                        activeIconColor: Colors.red,
                        isSelected: selectingDestination,
                        onTap: selectDestinationMode,
                        controller: destinationController,
                        focusNode: destinationFocusNode,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            buildSuggestionsOverlay(),
            IgnorePointer(
              ignoring: typing,
              child: !typing
                  ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.location_pin,
                    size: 50,
                    color: selectingPickup ? Colors.blue : Colors.red,
                  ),
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Colors.black,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              )
                  : const SizedBox.shrink(),
            ),
            if (isMapMoving && !typing)
              Positioned(
                bottom: 110,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    selectingPickup
                        ? "Move map to adjust pickup"
                        : "Move map to adjust destination",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            buildBottomActionArea(),
          ],
        ),
      ),
    );
  }
}

class PlaceSuggestion {
  final String description;
  final String placeId;
  final String mainText;
  final String secondaryText;

  PlaceSuggestion({
    required this.description,
    required this.placeId,
    required this.mainText,
    required this.secondaryText,
  });
}

class RideRequestService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String> createRideRequest({
    required String userId,
    required String pickupText,
    required String destinationText,
    required LatLng pickupLatLng,
    required LatLng destinationLatLng,
    required String distanceText,
    required String durationText,
    required List<LatLng> routeCoords,
  }) async {
    final doc = await _firestore.collection('ride_requests').add({
      'userId': userId,
      'pickupText': pickupText,
      'destinationText': destinationText,
      'pickup': {
        'lat': pickupLatLng.latitude,
        'lng': pickupLatLng.longitude,
      },
      'destination': {
        'lat': destinationLatLng.latitude,
        'lng': destinationLatLng.longitude,
      },
      'distanceText': distanceText,
      'durationText': durationText,
      'routeCoords': routeCoords
          .map((e) => {
        'lat': e.latitude,
        'lng': e.longitude,
      })
          .toList(),
      'status': 'searching',
      'acceptedBy': null,
      'requestedAt': FieldValue.serverTimestamp(),
    });

    return doc.id;
  }
}