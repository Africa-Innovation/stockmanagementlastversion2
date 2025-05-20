import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Pour formater les dates
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stockmanagementversion2/controller/venteController.dart';
import 'package:stockmanagementversion2/model/venteModel.dart';
import 'package:stockmanagementversion2/service/pdf_util.dart';

class StatisticPage extends StatefulWidget {
  @override
  _StatisticPageState createState() => _StatisticPageState();
}

class _StatisticPageState extends State<StatisticPage>
    with SingleTickerProviderStateMixin {
  final VenteController _controller = VenteController();
  List<Vente> _ventes = [];
  DateTime? _selectedDate;
  String _selectedPeriod = 'Jour'; // Options : 'Jour', 'Mois', 'Année'
  List<Vente> _ventesFiltrees = [];
  double _totalVentes = 0.0;
  Map<String, int> _topProduits = {}; // Produits les plus vendus
  bool isLoading = true;

  late TabController _tabController;

  int _nombreTotalVentes = 0;
  int _nombreTotalProduitsVendus = 0;


  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
     _selectedDate = DateTime.now(); // 👈 Initialise avec la date du jour
    _chargerVentes();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
Future<void> _genererPDF() async {
  await PDFUtil.genererPDF(
    titre: "Statistiques des Ventes",
    totalVentes: _totalVentes,
    ventesFiltrees: _ventesFiltrees,
    topProduits: _topProduits,
    nombreTotalVentes: _nombreTotalVentes, // Nouveau paramètre
    nombreTotalProduitsVendus: _nombreTotalProduitsVendus, // Nouveau paramètre
    fileName: "statistiques_ventes",
  );
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
    setState(() {
      _ventes = ventes;
      isLoading = false;
      _filtrerVentes();
    });
  }

  void _filtrerVentes() {
    if (_selectedDate == null) return;

    setState(() {
      _ventesFiltrees = _ventes;

      if (_selectedPeriod == 'Jour') {
        _ventesFiltrees = _ventesFiltrees
            .where((vente) =>
                DateFormat('yyyy-MM-dd').format(vente.date) ==
                DateFormat('yyyy-MM-dd').format(_selectedDate!))
            .toList();
      } else if (_selectedPeriod == 'Mois') {
        _ventesFiltrees = _ventesFiltrees
            .where((vente) =>
                DateFormat('yyyy-MM').format(vente.date) ==
                DateFormat('yyyy-MM').format(_selectedDate!))
            .toList();
      } else if (_selectedPeriod == 'Année') {
        _ventesFiltrees = _ventesFiltrees
            .where((vente) =>
                DateFormat('yyyy').format(vente.date) ==
                DateFormat('yyyy').format(_selectedDate!))
            .toList();
      }

      // Calculer le total des ventes
      _totalVentes = _ventesFiltrees.fold(
          0.0, (total, vente) => total + vente.montantTotal);

      // Calculer le nombre total de ventes
      _nombreTotalVentes = _ventesFiltrees.length;

      // Calculer le nombre total de produits vendus
      _nombreTotalProduitsVendus = _ventesFiltrees.fold(
    0, (total, vente) {
      // Additionner les quantités vendues de chaque produit dans la vente
      return total + vente.produitsVendus.fold(
          0, (sum, produit) => sum + produit.quantiteVendue);
    });

      // Calculer les produits les plus vendus
      _topProduits = {};
      for (var vente in _ventesFiltrees) {
        for (var produit in vente.produitsVendus) {
          _topProduits[produit.nom] =
              (_topProduits[produit.nom] ?? 0) + produit.quantiteVendue;
        }
      }

      // Trier les produits par quantité vendue (du plus vendu au moins vendu)
      _topProduits = Map.fromEntries(
        _topProduits.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value)),
      );
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _filtrerVentes();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Statistiques des Ventes',
            style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blueAccent,
         elevation: 8,
         iconTheme: IconThemeData(color: Colors.white),
      actions: [
        IconButton(
          color: Colors.white,
          icon: Icon(Icons.download),
          onPressed: _genererPDF,
        ),
      ],
        bottom: TabBar(
          
            labelColor: const Color.fromARGB(255, 204, 215, 224), // Couleur du texte pour l'onglet sélectionné
            unselectedLabelColor: Colors.white, // Couleur du texte pour les onglets non sélectionnés
            labelStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            unselectedLabelStyle: TextStyle(fontSize: 16),
          controller: _tabController,
          tabs: [
            Tab(text: 'Ventes'),
            Tab(text: 'Produits les plus vendus'),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButton<String>(
                    value: _selectedPeriod,
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _selectedPeriod = newValue;
                          _filtrerVentes();
                        });
                      }
                    },
                    items: <String>['Jour', 'Mois', 'Année']
                        .map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.calendar_today),
                  onPressed: () => _selectDate(context),
                ),
              ],
            ),
          ),
          if (_selectedDate != null)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Période sélectionnée : ${DateFormat('dd/MM/yyyy').format(_selectedDate!)}',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total des ventes :',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Flexible(
                  child: Text(
                    '${_totalVentes.toStringAsFixed(2)} FCFA',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Nombre total de ventes :',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  '$_nombreTotalVentes',
                  style: TextStyle(fontSize: 16, color: Colors.blue),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Nombre total de produits vendus :',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  '$_nombreTotalProduitsVendus',
                  style: TextStyle(fontSize: 16, color: Colors.blue),
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Onglet "Ventes"
                isLoading
                    ? Center(child: CircularProgressIndicator())
                    : _ventesFiltrees.isEmpty
                        ? Center(child: Text('Aucune vente trouvée, sélectionnez une date'))
                        : ListView(
                            children: _ventesFiltrees.map((vente) {
                              String formattedDate =
                                  DateFormat('dd/MM/yyyy HH:mm').format(vente.date);
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
                                ),
                              );
                            }).toList(),
                          ),

                // Onglet "Produits les plus vendus"
                isLoading
                    ? Center(child: CircularProgressIndicator())
                    : _topProduits.isEmpty
                        ? Center(child: Text('Aucun produit vendu,sélectionnez une date'))
                        : ListView(
                            children: _topProduits.entries.take(5).map((entry) {
                              return ListTile(
                                title: Text(entry.key),
                                trailing: Text('${entry.value} unités vendues'),
                              );
                            }).toList(),
                          ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}