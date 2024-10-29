import 'package:flutter/material.dart';
import 'package:travel/map_sample.dart';

class MyTravels extends StatefulWidget {
  const MyTravels({super.key});

  @override
  State<MyTravels> createState() => _MyTravelsState();
}

class _MyTravelsState extends State<MyTravels> {
  List<String> pontosTuristicos = [
    // América do Norte
    "Estátua da Liberdade - Nova York, EUA",
    "Grand Canyon - Arizona, EUA",
    "Disneyland - Anaheim, Califórnia, EUA",
    "Parque Nacional de Yellowstone - EUA",
    "CN Tower - Toronto, Canadá",

    // América do Sul
    "Cristo Redentor - Rio de Janeiro, Brasil",
    "Machu Picchu - Peru",
    "Cataratas do Iguaçu - Brasil/Argentina",
    "Deserto do Atacama - Chile",
    "Pão de Açúcar - Rio de Janeiro, Brasil",

    // Europa
    "Torre Eiffel - Paris, França",
    "Coliseu - Roma, Itália",
    "Sagrada Família - Barcelona, Espanha",
    "Big Ben - Londres, Reino Unido",
    "Palácio de Buckingham - Londres, Reino Unido",

    // Ásia
    "Grande Muralha da China - China",
    "Taj Mahal - Agra, Índia",
    "Templo de Angkor Wat - Camboja",
    "Torres Petronas - Kuala Lumpur, Malásia",
    "Monte Fuji - Japão",

    // Oceania
    "Ópera de Sydney - Sydney, Austrália",
    "Grande Barreira de Coral - Austrália",
    "Uluru (Ayers Rock) - Austrália",
    "Baía de Ha Long - Vietnã",
    "Ilha de Páscoa - Chile",

    // África
    "Pirâmides de Gizé - Egito",
    "Parque Nacional Kruger - África do Sul",
    "Cascatas Victoria - Zâmbia/Zimbábue",
    "Montanha da Mesa - Cidade do Cabo, África do Sul",
    "Sahara - Norte da África",
  ];

  void _openMap() {}
  void _deleteTravel(index) {
    setState(() {
      pontosTuristicos.removeAt(index);
    });
  }

  void _addLocation() {
    Navigator.push(
        context, MaterialPageRoute(builder: (_) => const MapSample()));
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
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
                itemCount: pontosTuristicos.length,
                itemBuilder: (context, index) {
                  String titulo = pontosTuristicos[index];
                  return GestureDetector(
                    onTap: () {
                      _openMap();
                    },
                    child: SizedBox(
                      child: ListTile(
                        title: Text(
                          titulo,
                        ),
                        trailing: IconButton(
                            onPressed: () {
                              _deleteTravel(index);
                            },
                            icon: const Icon(
                              Icons.delete,
                              color: Colors.red,
                            )),
                      ),
                    ),
                  );
                }),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _addLocation();
        },
        backgroundColor: Colors.blue,
        child: Icon(
          Icons.add,
          color: Colors.white,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
