import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Pour formater les dates
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stockmanagementversion2/controller/venteController.dart';
import 'package:stockmanagementversion2/model/venteModel.dart';
import 'package:stockmanagementversion2/service/pdf_util.dart';
import 'package:stockmanagementversion2/views/detailVentePage.dart';

class HistoriqueVentesPage extends StatefulWidget {
  @override
  _HistoriqueVentesPageState createState() => _HistoriqueVentesPageState();
}

class _HistoriqueVentesPageState extends State<HistoriqueVentesPage> {
  final VenteController _controller = VenteController();
  List<Vente> _ventes = [];
  List<Vente> _ventesFiltrees = [];
  String _searchQuery = '';
  double _totalVentes = 0.0;
  bool isLoading = true;

  // Nouveau : État pour gérer le filtre
  String _filtre = 'Toutes'; // Options : 'Toutes', 'Jour', 'Mois'
  // Nouveaux paramètres
  int _nombreTotalVentes = 0;
  int _nombreTotalProduitsVendus = 0;


  @override
  void initState() {
    super.initState();
    _chargerVentes();
  }

  Future<void> _chargerVentes() async {
    final prefs = await SharedPreferences.getInstance();
    final idUtilisateur = prefs.getString('idUtilisateur');

    if (idUtilisateur == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Utilisateur non connecté')),
      );
      return;
    }

    final ventes = await _controller.obtenirHistoriqueVentes(idUtilisateur);
    ventes.sort((a, b) => b.date.compareTo(a.date)); // Trier par date (du plus récent au plus ancien)
    setState(() {
      _ventes = ventes;
      _ventesFiltrees = ventes;
      _calculerTotalVentes();
      isLoading = false;
    });
  }

  void _filtrerVentes(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _ventesFiltrees = _ventes;
      } else {
        _ventesFiltrees = _ventes
            .where((vente) =>
                vente.idVente.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
      _calculerTotalVentes();
    });
  }

  void _appliquerFiltre(String filtre) {
    setState(() {
      _filtre = filtre;
      _ventesFiltrees = _ventes;

      if (filtre == 'Jour') {
        // Filtrer les ventes du jour actuel
        _ventesFiltrees = _ventesFiltrees
            .where((vente) =>
                DateFormat('yyyy-MM-dd').format(vente.date) ==
                DateFormat('yyyy-MM-dd').format(DateTime.now()))
            .toList();
      } else if (filtre == 'Mois') {
        // Filtrer les ventes du mois actuel
        _ventesFiltrees = _ventesFiltrees
            .where((vente) =>
                DateFormat('yyyy-MM').format(vente.date) ==
                DateFormat('yyyy-MM').format(DateTime.now()))
            .toList();
      }

      _calculerTotalVentes();
    });
  }

 void _calculerTotalVentes() {
  _totalVentes =
      _ventesFiltrees.fold(0.0, (total, vente) => total + vente.montantTotal);

  // Calculer le nombre total de ventes
  _nombreTotalVentes = _ventesFiltrees.length;

  // Calculer le nombre total de produits vendus
  _nombreTotalProduitsVendus = _ventesFiltrees.fold(
      0, (total, vente) => total + vente.produitsVendus.length);
}

  Future<void> _genererPDF() async {
  await PDFUtil.genererPDF(
    titre: "Historique des Ventes",
    totalVentes: _totalVentes,
    ventesFiltrees: _ventesFiltrees,
    fileName: "historique_ventes",
     nombreTotalVentes: _nombreTotalVentes, // Nouveau paramètre
    nombreTotalProduitsVendus: _nombreTotalProduitsVendus, // Nouveau paramètre
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Historique des Ventes',
        style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue.shade800,
        elevation: 8,
        iconTheme: IconThemeData(color: Colors.white),
        actions: [
          // Menu déroulant pour choisir le filtre
          DropdownButton<String>(
            dropdownColor: Colors.black,
            value: _filtre,
            onChanged: (String? newValue) {
              if (newValue != null) {
                _appliquerFiltre(newValue);
              }
            },
            items: <String>['Toutes', 'Jour', 'Mois']
                .map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(
                  value,
                  style: TextStyle(color: Colors.white),
                ),
              );
            }).toList(),
            icon: Icon(Icons.filter_list, color: Colors.white),
            underline: Container(), // Supprimer la ligne sous le menu déroulant
          ),
          IconButton(
            color: Colors.white,
            icon: Icon(Icons.download),
            onPressed: _genererPDF,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                labelText: 'Rechercher par ID de vente',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: _filtrerVentes,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total des ventes:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  '${_totalVentes.toStringAsFixed(2)} FCFA',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: isLoading
                ? Center(child: CircularProgressIndicator())
                : _ventesFiltrees.isEmpty
                    ? Center(child: Text('Aucune vente trouvée'))
                    : ListView.builder(
                        itemCount: _ventesFiltrees.length,
                        itemBuilder: (context, index) {
                          final vente = _ventesFiltrees[index];
                          String formattedDate = DateFormat('dd/MM/yyyy HH:mm')
                              .format(vente.date);

                          return Card(
                            elevation: 4,
                            margin: EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              title: Text('Vente du $formattedDate'),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('ID de la vente: ${vente.idVente}'),
                                  Text('Montant: ${vente.montantTotal} FCFA'),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: vente.produitsVendus.map((produit) {
                                      return Text(
                                          '- ${produit.nom} x${produit.quantiteVendue} : ${(produit.prix * produit.quantiteVendue).toStringAsFixed(2)} FCFA');
                                    }).toList(),
                                  ),
                                ],
                              ),
                              trailing: Icon(Icons.arrow_forward,
                                  color: Colors.blue.shade800),
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        DetailsVentePage(vente: vente),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}