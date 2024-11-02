import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:travel/map_sample.dart';

class MyTravels extends StatefulWidget {
  const MyTravels({super.key});

  @override
  State<MyTravels> createState() => _MyTravelsState();
}

class _MyTravelsState extends State<MyTravels> {
  final _streamController = StreamController<QuerySnapshot>.broadcast();
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  void _openMap(double latitude, double longitude) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MapSample(
          initialLatitude: latitude,
          initialLongitude: longitude,
        ),
      ),
    );
  }

  void _deleteTravel(idTravel) {
    setState(() {
      _db.collection("viagens").doc(idTravel).delete();
    });
  }

  void _addLocation() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const MapSample(),
      ),
    );
  }

  void _addListTravel() async {
    final stream = _db.collection("viagens").snapshots();

    stream.listen((data) {
      _streamController.add(data);
    });
  }

  @override
  void initState() {
    super.initState();
    _addListTravel();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Viagens',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _streamController.stream,
        builder: (context, snapshot) {
          switch (snapshot.connectionState) {
            case ConnectionState.none:
            case ConnectionState.waiting:
              return const Center(child: CircularProgressIndicator());
            case ConnectionState.active:
            case ConnectionState.done:
              if (snapshot.hasError) {
                return const Center(child: Text('Erro ao carregar dados'));
              }
              if (!snapshot.hasData || snapshot.data == null) {
                return const Center(child: Text('Nenhuma viagem encontrada'));
              }
              QuerySnapshot querySnapshot = snapshot.data!;
              List<DocumentSnapshot> travels = querySnapshot.docs.toList();
              return Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      itemCount: travels.length,
                      itemBuilder: (context, index) {
                        DocumentSnapshot item = travels[index];
                        String title = item['titulo'];
                        String idTravel = item.id;
                        double latitude = item['latitude'];
                        double longitude = item['longitude'];
                        return GestureDetector(
                          onTap: () {
                            _openMap(latitude, longitude);
                          },
                          child: SizedBox(
                            child: ListTile(
                              title: Text(title),
                              trailing: IconButton(
                                onPressed: () {
                                  _deleteTravel(idTravel);
                                },
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addLocation,
        backgroundColor: Colors.blue,
        child: const Icon(
          Icons.add,
          color: Colors.white,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
