import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapSample extends StatefulWidget {
  const MapSample({super.key});

  @override
  State<MapSample> createState() => MapSampleState();
}

class MapSampleState extends State<MapSample> {
  final Completer<GoogleMapController> _controller =
      Completer<GoogleMapController>();

  static const CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(37.42796133580664, -122.085749655962),
    zoom: 14.4746,
  );

  static const CameraPosition _kLake = CameraPosition(
    bearing: 192.8334901395799,
    target: LatLng(37.43296265331129, -122.08832357078792),
    tilt: 59.440717697143555,
    zoom: 19.151926040649414,
  );

  final Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    // Aguarda a construção completa para pedir permissão de localização.
    WidgetsBinding.instance.addPostFrameCallback((_) => _initializeLocation());
  }

  Future<void> _initializeLocation() async {
    final Position? position = await getCurrentLocation();
    if (position != null) {
      _showMarker(LatLng(position.latitude, position.longitude));
      _moveCameraToPosition(position);
    }
  }

  Future<Position?> getCurrentLocation() async {
    // Verifica e solicita permissão, se necessário
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
    try {
      // Obtém a lista de endereços com base nas coordenadas
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
          // Verifica se o widget ainda está montado
          setState(() {
            _markers.add(marker);
          });
        } else {
          print("Widget não está mais montado.");
        }
      }
    } catch (e) {
      print("Erro ao obter o endereço: $e");
    }
  }

  void _moveCameraToPosition(Position position) async {
    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(position.latitude, position.longitude),
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
        title: Text(
          "Mapa",
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: GoogleMap(
        markers: _markers,
        mapType: MapType.hybrid,
        initialCameraPosition: _kGooglePlex,
        onMapCreated: (GoogleMapController controller) {
          _controller.complete(controller);
        },
        onLongPress: _showMarker,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _goToTheLake,
        label: const Text('To the lake!'),
        icon: const Icon(Icons.directions_boat),
      ),
    );
  }

  Future<void> _goToTheLake() async {
    final GoogleMapController controller = await _controller.future;
    await controller.animateCamera(
      CameraUpdate.newCameraPosition(_kLake),
    );
  }
}
