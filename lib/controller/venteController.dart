import 'dart:convert';

import 'package:stockmanagementversion2/model/DatabaseHelper.dart';
import 'package:stockmanagementversion2/model/produitvenduModel.dart';
import 'package:stockmanagementversion2/model/venteModel.dart';

class VenteController {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<void> enregistrerVente(Vente vente) async {
  final db = await _dbHelper.database;

  // Sérialiser les produits vendus en JSON
  final produitsVendusJson = jsonEncode(vente.produitsVendus.map((p) => p.toMap()).toList());

  // Enregistrer la vente
  await db.insert('ventes', {
    'idVente': vente.idVente,
    'date': vente.date.toIso8601String(),
    'produitsVendus': produitsVendusJson, // Utiliser la chaîne JSON
    'montantTotal': vente.montantTotal,
    'idUtilisateur': vente.idUtilisateur,
  });

  // Enregistrer les produits vendus dans la table produits_vendus
  for (final produit in vente.produitsVendus) {
    await db.insert('produits_vendus', {
      'idVente': vente.idVente,
      'idProduit': produit.idProduit,
      'quantiteVendue': produit.quantiteVendue,
    });
  }
}

 Future<List<Vente>> obtenirHistoriqueVentes(String idUtilisateur) async {
  final db = await _dbHelper.database;

  // Récupérer les ventes
  final List<Map<String, dynamic>> ventesMap = await db.query(
    'ventes',
    where: 'idUtilisateur = ?',
    whereArgs: [idUtilisateur],
  );

  // Récupérer les produits vendus pour chaque vente
  final List<Vente> ventes = [];
  for (final venteMap in ventesMap) {
    // Désérialiser les produits vendus depuis JSON
    final List<dynamic> produitsVendusJson = jsonDecode(venteMap['produitsVendus'] ?? '[]');
    final List<ProduitVendu> produitsVendus = produitsVendusJson.map((p) {
      return ProduitVendu.fromMap(p);
    }).toList();

    ventes.add(Vente(
      idVente: venteMap['idVente'] ?? '',
      date: DateTime.parse(venteMap['date'] ?? DateTime.now().toIso8601String()),
      produitsVendus: produitsVendus,
      montantTotal: venteMap['montantTotal'] ?? 0.0,
      idUtilisateur: venteMap['idUtilisateur'] ?? '',
    ));
  }

  return ventes;
}
}