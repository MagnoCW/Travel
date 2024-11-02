import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

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
  final Set<Marker> _markers = {};
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _initializeMarkers();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initializeLocation());
  }

  Future<void> _initializeMarkers() async {
    final snapshots = await _db.collection("viagens").get();
    setState(() {
      for (var doc in snapshots.docs) {
        var data = doc.data();
        LatLng position = LatLng(data["latitude"], data["longitude"]);
        _markers.add(
          Marker(
            markerId: MarkerId(doc.id),
            position: position,
            infoWindow: InfoWindow(title: data["titulo"] ?? "Local"),
          ),
        );
      }
    });
  }

  Future<void> _initializeLocation() async {
    if (widget.initialLatitude != null && widget.initialLongitude != null) {
      LatLng initialPosition =
          LatLng(widget.initialLatitude!, widget.initialLongitude!);
      if (!_markerExists(initialPosition)) {
        _showMarker(initialPosition);
      }
      _moveCameraToPosition(initialPosition);
    } else {
      final Position? position = await getCurrentLocation();
      if (position != null) {
        LatLng currentPosition = LatLng(position.latitude, position.longitude);
        if (!_markerExists(currentPosition)) {
          _showMarker(currentPosition);
        }
        _moveCameraToPosition(currentPosition);
      }
    }
  }

  bool _markerExists(LatLng position) {
    return _markers.any((marker) => marker.position == position);
  }

  Future<Position?> getCurrentLocation() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        print('Permissão negada');
        return null;
      }
    }

    if (!await Geolocator.isLocationServiceEnabled()) {
      print('Serviço de localização está desativado.');
      return null;
    }

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    print('Latitude: ${position.latitude}, Longitude: ${position.longitude}');
    return position;
  }

  void _showMarker(LatLng latLng) async {
    if (_markerExists(latLng)) return;
    try {
      List<Placemark> addressList = await placemarkFromCoordinates(
        latLng.latitude,
        latLng.longitude,
      );

      if (addressList.isNotEmpty) {
        Placemark address = addressList[0];
        String? street = address.thoroughfare;

        Marker marker = Marker(
          markerId: MarkerId("marker-${latLng.latitude}-${latLng.longitude}"),
          position: latLng,
          infoWindow: InfoWindow(
            title: street ?? "Local Desconhecido",
          ),
        );

        if (mounted) {
          setState(() {
            _markers.add(marker);
            _saveMarkerToFirestore(street, latLng);
          });
        }
      }
    } catch (e) {
      print("Erro ao obter o endereço: $e");
    }
  }

  Future<void> _saveMarkerToFirestore(String? title, LatLng latLng) async {
    await _db.collection("viagens").add({
      "titulo": title,
      "latitude": latLng.latitude,
      "longitude": latLng.longitude,
    });
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
        markers: _markers,
        mapType: MapType.hybrid,
        initialCameraPosition: CameraPosition(
          target: widget.initialLatitude != null &&
                  widget.initialLongitude != null
              ? LatLng(widget.initialLatitude!, widget.initialLongitude!)
              : LatLng(37.42796133580664, -122.085749655962), // posição padrão
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
