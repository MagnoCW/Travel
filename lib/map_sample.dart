import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:travel/map_controller.dart';

class MapSample extends StatefulWidget {
  final double? initialLatitude;
  final double? initialLongitude;

  const MapSample({
    super.key,
    this.initialLatitude,
    this.initialLongitude,
  });

  @override
  State<MapSample> createState() => MapSampleState();
}

class MapSampleState extends State<MapSample> {
  final Completer<GoogleMapController> _controller =
      Completer<GoogleMapController>();
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _initializeMarkers();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initializeLocation());
  }

  Future<void> _initializeMarkers() async {
    await _mapController.initializeMarkers();
    setState(() {});
  }

  Future<void> _initializeLocation() async {
    if (widget.initialLatitude != null && widget.initialLongitude != null) {
      LatLng initialPosition =
          LatLng(widget.initialLatitude!, widget.initialLongitude!);
      if (!_mapController.markerExists(initialPosition)) {
        _showMarker(initialPosition);
      }
      _moveCameraToPosition(initialPosition);
    } else {
      final Position? position = await _mapController.getCurrentLocation();
      if (position != null) {
        LatLng currentPosition = LatLng(position.latitude, position.longitude);
        if (!_mapController.markerExists(currentPosition)) {
          _showMarker(currentPosition);
        }
        _moveCameraToPosition(currentPosition);
      }
    }
  }

  void _showMarker(LatLng latLng) async {
    Marker? marker = await _mapController.createMarkerWithAddress(latLng);
    if (marker != null && mounted) {
      setState(() {
        _mapController.markers.add(marker);
      });
    }
  }

  void _moveCameraToPosition(LatLng position) async {
    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: position,
          zoom: 14.4746,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.white),
        title: const Text(
          "Mapa",
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: GoogleMap(
        markers: _mapController.markers,
        mapType: MapType.hybrid,
        initialCameraPosition: CameraPosition(
          target:
              widget.initialLatitude != null && widget.initialLongitude != null
                  ? LatLng(widget.initialLatitude!, widget.initialLongitude!)
                  : LatLng(37.42796133580664, -122.085749655962),
          zoom: 14.4746,
        ),
        onMapCreated: (GoogleMapController controller) {
          _controller.complete(controller);
        },
        onLongPress: _showMarker,
      ),
    );
  }
}
