import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
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
  String _filtre = 'Toutes';
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
        SnackBar(
          content: const Text('Utilisateur non connecté'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final ventes = await _controller.obtenirHistoriqueVentes(idUtilisateur);
      ventes.sort((a, b) => b.date.compareTo(a.date));
      setState(() {
        _ventes = ventes;
        _ventesFiltrees = ventes;
        _calculerTotalVentes();
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur de chargement: $e'),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
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
        _ventesFiltrees = _ventesFiltrees
            .where((vente) =>
                DateFormat('yyyy-MM-dd').format(vente.date) ==
                DateFormat('yyyy-MM-dd').format(DateTime.now()))
            .toList();
      } else if (filtre == 'Mois') {
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
    _nombreTotalVentes = _ventesFiltrees.length;
    _nombreTotalProduitsVendus = _ventesFiltrees.fold(
          0, (total, vente) => total + vente.produitsVendus.fold(
              0, (sum, produit) => sum + produit.quantiteVendue));
  }

  Future<void> _genererPDF() async {
    await PDFUtil.genererPDF(
      titre: "Historique des Ventes",
      totalVentes: _totalVentes,
      ventesFiltrees: _ventesFiltrees,
      fileName: "historique_ventes",
      nombreTotalVentes: _nombreTotalVentes,
      nombreTotalProduitsVendus: _nombreTotalProduitsVendus,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Historique des Ventes',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blueAccent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_alt_rounded, color: Colors.white),
            onSelected: _appliquerFiltre,
            itemBuilder: (BuildContext context) {
              return ['Toutes', 'Jour', 'Mois'].map((String choice) {
                return PopupMenuItem<String>(
                  value: choice,
                  child: Row(
                    children: [
                      Icon(
                        _filtre == choice ? Icons.check_rounded : null,
                        color: Colors.blue.shade800,
                      ),
                      const SizedBox(width: 8),
                      Text(choice),
                    ],
                  ),
                );
              }).toList();
            },
          ),
          IconButton(
            icon: const Icon(Icons.download_rounded, size: 24),
            tooltip: 'Exporter en PDF',
            onPressed: _genererPDF,
          ),
        ],
      ),
      body: Column(
        children: [
          // Barre de recherche et statistiques
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    labelText: 'Rechercher par ID de vente',
                    labelStyle: TextStyle(color: Colors.grey.shade600),
                    prefixIcon:
                        Icon(Icons.search_rounded, color: Colors.grey.shade600),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          BorderSide(color: Colors.blue.shade800, width: 1.5),
                    ),
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                  ),
                  onChanged: _filtrerVentes,
                ),
                const SizedBox(height: 16),
                _buildStatCard(
                  icon: Icons.attach_money_rounded,
                  title: 'Total des ventes',
                  value: '${_totalVentes.toStringAsFixed(2)} FCFA',
                  color: Colors.green.shade600,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        icon: Icons.receipt_rounded,
                        title: 'Nombre de ventes',
                        value: '$_nombreTotalVentes',
                        color: Colors.blue.shade600,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        icon: Icons.shopping_bag_rounded,
                        title: 'Produits vendus',
                        value: '$_nombreTotalProduitsVendus',
                        color: Colors.orange.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Liste des ventes
          Expanded(
            child: isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Colors.blue.shade800),
                    ),
                  )
                : _ventesFiltrees.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.receipt_long_rounded,
                                size: 48, color: Colors.grey.shade400),
                            const SizedBox(height: 16),
                            Text(
                              'Aucune vente trouvée',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            Text(
                              _searchQuery.isEmpty
                                  ? 'Essayez avec un autre filtre'
                                  : 'Aucun résultat pour "${_searchQuery}"',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _ventesFiltrees.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final vente = _ventesFiltrees[index];
                          final formattedDate =
                              DateFormat('dd/MM/yyyy HH:mm').format(vente.date);
                          return InkWell(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) =>
                                      DetailsVentePage(vente: vente),
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 4,
                                      children: [
                                        Text(
                                          'Vente #${vente.idVente}',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.blue.shade800,
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.green.shade50,
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            '${vente.montantTotal.toStringAsFixed(2)} FCFA',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.green.shade800,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      formattedDate,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    ...vente.produitsVendus
                                        .take(2)
                                        .map((produit) => Padding(
                                              padding:
                                                  const EdgeInsets.only(bottom: 4),
                                              child: Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      '- ${produit.nom}',
                                                      style: const TextStyle(
                                                          fontSize: 14),
                                                    ),
                                                  ),
                                                  Text(
                                                    'x${produit.quantiteVendue}',
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      color:
                                                          Colors.grey.shade600,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 16),
                                                  Text(
                                                    '${(produit.prix * produit.quantiteVendue).toStringAsFixed(2)} FCFA',
                                                    style: const TextStyle(
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ))
                                        .toList(),
                                    if (vente.produitsVendus.length > 2) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        '+ ${vente.produitsVendus.length - 2} autres produits',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.blue.shade600,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 8),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: Icon(
                                        Icons.chevron_right_rounded,
                                        color: Colors.blue.shade800,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
