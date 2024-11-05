import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final StreamController<QuerySnapshot> streamController =
      StreamController.broadcast();
  final Set<Marker> markers = {};

  MapController() {
    _initializeTravelStream();
  }

  void _initializeTravelStream() {
    final stream = _db.collection("viagens").snapshots();
    stream.listen((data) {
      streamController.add(data);
    });
  }

  Stream<QuerySnapshot> get travelStream => streamController.stream;

  Future<void> deleteTravel(String idTravel) async {
    await _db.collection("viagens").doc(idTravel).delete();
  }

  void dispose() {
    streamController.close();
  }

  bool markerExists(LatLng position, {double tolerance = 0.0001}) {
    return markers.any((marker) =>
        (marker.position.latitude - position.latitude).abs() < tolerance &&
        (marker.position.longitude - position.longitude).abs() < tolerance);
  }

  Future<void> initializeMarkers() async {
    final snapshots = await _db.collection("viagens").get();
    for (var doc in snapshots.docs) {
      var data = doc.data();
      LatLng position = LatLng(data["latitude"], data["longitude"]);
      markers.add(
        Marker(
          markerId: MarkerId(doc.id),
          position: position,
          infoWindow: InfoWindow(title: data["titulo"] ?? "Local"),
        ),
      );
    }
  }

  Future<void> saveMarkerToFirestore(String? title, LatLng latLng) async {
    await _db.collection("viagens").add({
      "titulo": title,
      "latitude": latLng.latitude,
      "longitude": latLng.longitude,
    });
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

  Future<Marker?> createMarkerWithAddress(LatLng latLng) async {
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

        if (!markerExists(latLng)) {
          markers.add(marker);
          await saveMarkerToFirestore(street, latLng);
        }
        return marker;
      }
    } catch (e) {
      print("Erro ao obter o endereço: $e");
    }
    return null;
  }
}
