import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stockmanagementversion2/model/DatabaseHelper.dart';
import 'package:stockmanagementversion2/model/produitModel.dart';
import 'package:stockmanagementversion2/model/produitvenduModel.dart';
import 'package:stockmanagementversion2/model/venteModel.dart';

class SynchronisationService {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> synchroniserDonnees(BuildContext context) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final idUtilisateur = prefs.getString('idUtilisateur');

    if (idUtilisateur == null) {
      throw Exception('Utilisateur non connecté');
    }

    // Synchroniser les informations de l'utilisateur
    await _synchroniserUtilisateur(idUtilisateur);

    // Synchroniser les produits
    await _synchroniserProduits(idUtilisateur);

    // Synchroniser les ventes
    await _synchroniserVentes(idUtilisateur);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Synchronisation terminée avec succès.')),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Erreur lors de la synchronisation : $e')),
    );
  }
}

  Future<void> _synchroniserProduits(String idUtilisateur) async {
  // Récupérer les produits locaux non synchronisés
  final produitsLocaux = await _dbHelper.getProduitsNonSynchronises(idUtilisateur);

  // Synchroniser chaque produit avec Firestore
  for (final produit in produitsLocaux) {
    await _firestore
        .collection('utilisateurs')
        .doc(idUtilisateur)
        .collection('produits')
        .doc(produit.idProduit)
        .set(produit.toMap());

    // Marquer le produit comme synchronisé
    await _dbHelper.marquerProduitCommeSynchronise(produit.idProduit);
  }

  // Récupérer les produits de Firestore et mettre à jour la base locale
  final produitsFirestore = await _firestore
      .collection('utilisateurs')
      .doc(idUtilisateur)
      .collection('produits')
      .get();

  for (final doc in produitsFirestore.docs) {
    final produit = Produit.fromMap(doc.data());
    await _dbHelper.insertProduit(produit.toMap());
  }
}

  Future<void> _synchroniserVentes(String idUtilisateur) async {
  print('Récupération des ventes non synchronisées...');
  final ventesLocales = await _dbHelper.getVentesNonSynchronisees(idUtilisateur);
  print('${ventesLocales.length} ventes à synchroniser.');

  for (final vente in ventesLocales) {
    print('Synchronisation de la vente ${vente.idVente}...');
    final produitsVendusJson = vente.produitsVendus.map((p) => p.toMap()).toList();

    await _firestore
        .collection('utilisateurs')
        .doc(idUtilisateur)
        .collection('ventes')
        .doc(vente.idVente)
        .set({
          'idVente': vente.idVente,
          'date': vente.date.toIso8601String(),
          'produitsVendus': produitsVendusJson,
          'montantTotal': vente.montantTotal,
          'idUtilisateur': vente.idUtilisateur,
        });

    print('Marquage de la vente ${vente.idVente} comme synchronisée...');
    await _dbHelper.marquerVenteCommeSynchronisee(vente.idVente);
  }

  print('Récupération des ventes de Firestore...');
  final ventesFirestore = await _firestore
      .collection('utilisateurs')
      .doc(idUtilisateur)
      .collection('ventes')
      .get();

  print('Mise à jour de la base locale avec ${ventesFirestore.docs.length} ventes...');
  for (final doc in ventesFirestore.docs) {
    final vente = Vente(
      idVente: doc.id,
      date: DateTime.parse(doc['date']),
      produitsVendus: (doc['produitsVendus'] as List)
          .map((p) => ProduitVendu.fromMap(p))
          .toList(),
      montantTotal: doc['montantTotal'],
      idUtilisateur: doc['idUtilisateur'],
    );
    await _dbHelper.insertVente(vente.toMap());
  }
}

Future<void> _synchroniserUtilisateur(String idUtilisateur) async {
  final prefs = await SharedPreferences.getInstance();
  final nom = prefs.getString('nom');
  final numero = prefs.getString('numero');
  final nomBoutique = prefs.getString('nomBoutique');

  if (nom == null || numero == null || nomBoutique == null) {
    throw Exception('Informations utilisateur manquantes');
  }

  // Envoyer les informations de l'utilisateur à Firestore
  await _firestore
      .collection('utilisateurs')
      .doc(idUtilisateur)
      .set({
        'idUtilisateur': idUtilisateur,
        'nom': nom,
        'numero': numero,
        'nomBoutique': nomBoutique,
      });
}
}