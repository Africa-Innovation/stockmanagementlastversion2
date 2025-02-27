 

import 'package:stockmanagementversion2/model/DatabaseHelper.dart';
import 'package:stockmanagementversion2/model/produitModel.dart';

class ProduitController {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<void> ajouterProduit(Produit produit) async {
    await _dbHelper.insertProduit(produit.toMap());
  }

  Future<List<Produit>> obtenirProduits(String idUtilisateur) async {
    final produits = await _dbHelper.getProduits(idUtilisateur);
    return produits.map((p) => Produit.fromMap(p)).toList();
  }

  Future<void> supprimerProduit(String idProduit) async {
    await _dbHelper.deleteProduit(idProduit);
  }

  Future<void> modifierProduit(Produit produit) async {
    await _dbHelper.updateProduit(produit);
  }

  // Corriger le type de retour ici
  Future<List<Produit>> verifierAlertesStock(String idUtilisateur) async {
    final produits = await obtenirProduits(idUtilisateur);
    final produitsEnAlerte = produits.where((p) => p.quantite < p.stockMinimum).toList();
    return produitsEnAlerte; // Retourne la liste des produits en alerte
  }
}