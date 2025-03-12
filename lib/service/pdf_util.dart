// utils/pdf_util.dart

import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:stockmanagementversion2/model/venteModel.dart';

// utils/pdf_util.dart

class PDFUtil {
  static Future<void> genererPDF({
    required String titre,
    required double totalVentes,
    required List<Vente> ventesFiltrees,
    Map<String, int>? topProduits,
    required int nombreTotalVentes, // Nouveau paramètre
    required int nombreTotalProduitsVendus, // Nouveau paramètre
    required String fileName,
  }) async {
    final pdf = pw.Document();

    // Fonction pour créer une liste de widgets pour les ventes
    List<pw.Widget> buildVenteWidgets(List<Vente> ventes) {
      return ventes.map((vente) {
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
                children: vente.produitsVendus.map((produit) {
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
      }).toList();
    }

    // Fonction pour créer une liste de widgets pour les produits les plus vendus
    List<pw.Widget> buildTopProduitsWidgets(Map<String, int> topProduits) {
      return topProduits.entries.map((entry) {
        return pw.Container(
          margin: pw.EdgeInsets.only(bottom: 10),
          padding: pw.EdgeInsets.all(8),
          decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey)),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(entry.key,
                  style: pw.TextStyle(
                      fontSize: 14, fontWeight: pw.FontWeight.bold)),
              pw.Text("${entry.value} unités vendues",
                  style: pw.TextStyle(fontSize: 14)),
            ],
          ),
        );
      }).toList();
    }

    // Ajouter les pages au PDF
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Text(titre,
                  style: pw.TextStyle(
                      fontSize: 20, fontWeight: pw.FontWeight.bold)),
            ),
            pw.Text(
              "Total des ventes: ${totalVentes.toStringAsFixed(2)} FCFA",
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 10),
            pw.Text("Nombre total de ventes : $nombreTotalVentes",
                style: pw.TextStyle(fontSize: 14)),
            pw.Text("Nombre total de produits vendus : $nombreTotalProduitsVendus",
                style: pw.TextStyle(fontSize: 14)),
            pw.SizedBox(height: 10),
            pw.Text("Détails des ventes :",
                style: pw.TextStyle(
                    fontSize: 18, fontWeight: pw.FontWeight.bold)),
            ...buildVenteWidgets(ventesFiltrees),
          ];
        },
      ),
    );

    // Ajouter une page pour les produits les plus vendus (si topProduits est fourni)
    if (topProduits != null && topProduits.isNotEmpty) {
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return [
              pw.Header(
                level: 0,
                child: pw.Text("Produits les plus vendus",
                    style: pw.TextStyle(
                        fontSize: 20, fontWeight: pw.FontWeight.bold)),
              ),
              pw.SizedBox(height: 10),
              ...buildTopProduitsWidgets(topProduits),
            ];
          },
        ),
      );
    }

    // Enregistrer le PDF dans un fichier
    final output = await getExternalStorageDirectory();
    final file = File("${output!.path}/$fileName.pdf");
    await file.writeAsBytes(await pdf.save());

    // Partager le PDF
    await Printing.sharePdf(
        bytes: await pdf.save(), filename: "$fileName.pdf");
  }
}