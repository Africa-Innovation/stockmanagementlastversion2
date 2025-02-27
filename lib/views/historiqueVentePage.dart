import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Importation du package intl
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:stockmanagementversion2/controller/venteController.dart';
import 'package:stockmanagementversion2/model/venteModel.dart';
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

  @override
  void initState() {
    super.initState();
    _chargerVentes();
  }

  Future<void> _chargerVentes() async {
    final ventes = await _controller.obtenirHistoriqueVentes('idUtilisateur');
    // Trier les ventes par date (du plus récent au plus ancien)
    ventes.sort((a, b) => b.date.compareTo(a.date));
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

  void _calculerTotalVentes() {
    _totalVentes =
        _ventesFiltrees.fold(0.0, (total, vente) => total + vente.montantTotal);
  }

  Future<void> _genererPDF() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text("Historique des Ventes",
                  style: pw.TextStyle(
                      fontSize: 20, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              pw.Text(
                "Total des ventes: ${_totalVentes.toStringAsFixed(2)} FCFA",
                style:
                    pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 10),
              ..._ventesFiltrees.map((vente) {
  return pw.Container(
    margin: pw.EdgeInsets.only(bottom: 10),
    padding: pw.EdgeInsets.all(8),
    decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey)),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text("ID de la vente: ${vente.idVente}",
            style: pw.TextStyle(
                fontSize: 14, fontWeight: pw.FontWeight.bold)),
        pw.Text("Date: ${vente.date}"),
        pw.SizedBox(height: 5),
        pw.Text("Produits vendus :",
            style: pw.TextStyle(
                fontWeight: pw.FontWeight.bold, fontSize: 12)),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: vente.produitsVendus.map((produit) { // Utilisez produitsVendus
            return pw.Text(
                "- ${produit.nom} x${produit.quantiteVendue} : ${(produit.prix * produit.quantiteVendue).toStringAsFixed(2)} FCFA",
                style: pw.TextStyle(fontSize: 12));
          }).toList(),
        ),
        pw.Divider(),
        pw.Text("Total: ${vente.montantTotal.toStringAsFixed(2)} FCFA",
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
      ],
    ),
  );
}).toList(),
            ],
          );
        },
      ),
    );

    // Enregistrer le PDF dans un fichier
    final output = await getExternalStorageDirectory();
    final file = File("${output!.path}/historique_ventes.pdf");
    await file.writeAsBytes(await pdf.save());

    // Partager le PDF
    await Printing.sharePdf(
        bytes: await pdf.save(), filename: "historique_ventes.pdf");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Historique des Ventes'),
        backgroundColor: Colors.blue.shade800,
        elevation: 8,
        actions: [
          IconButton(
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
                              .format(vente.date); // Utilisation de DateFormat

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
                                // Naviguer vers les détails de la vente
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
