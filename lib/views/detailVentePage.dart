import 'package:flutter/material.dart';
import 'package:stockmanagementversion2/model/venteModel.dart';

class DetailsVentePage extends StatelessWidget {
  final Vente vente;

  DetailsVentePage({required this.vente});

  @override
  Widget build(BuildContext context) {
    final quantites = <String, int>{};
    for (final produit in vente.produitsVendus) { // Utilisez produitsVendus
      quantites[produit.idProduit] = (quantites[produit.idProduit] ?? 0) + 1;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Détails de la Vente',
        style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue.shade800,
        elevation: 8,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ID de la vente: ${vente.idVente}',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'Date: ${vente.date.toLocal()}',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 10),
            Text(
              'Montant total: ${vente.montantTotal} FCFA',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            Text(
              'Produits vendus:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            ...vente.produitsVendus.toSet().map((produit) { // Utilisez produitsVendus
              final quantite = quantites[produit.idProduit] ?? 0;
              return ListTile(
                title: Text(produit.nom),
                subtitle: Text('Quantité: ${produit.quantiteVendue} | Prix: ${produit.prix} FCFA'),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}