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

  // Méthode pour synchroniser les données locales vers Firebase
  Future<void> synchroniserDonnees(BuildContext context) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final idUtilisateur = prefs.getString('idUtilisateur');

      if (idUtilisateur == null) {
        throw Exception('Utilisateur non connecté');
      }

      print('ID utilisateur récupéré: $idUtilisateur');

      // Vérifier si l'utilisateur existe dans Firestore
      final userDoc = await _firestore
          .collection('utilisateurs')
          .doc(idUtilisateur)
          .get();

      if (!userDoc.exists) {
        throw Exception('Utilisateur non trouvé dans Firestore');
      }

      print('Utilisateur trouvé dans Firestore: $idUtilisateur');

      // Synchroniser les données locales vers Firebase
      await _synchroniserUtilisateur(idUtilisateur);
      await _synchroniserProduits(idUtilisateur);
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

  // Méthode pour restaurer les données depuis Firebase
  Future<void> restaurerDonnees(BuildContext context) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final idUtilisateur = prefs.getString('idUtilisateur');

      if (idUtilisateur == null) {
        throw Exception('Utilisateur non connecté');
      }

      print('Restauration des données pour l\'utilisateur: $idUtilisateur');

      // Récupérer les produits depuis Firebase
      final produitsFirestore = await _firestore
          .collection('utilisateurs')
          .doc(idUtilisateur)
          .collection('produits')
          .get();

      for (final doc in produitsFirestore.docs) {
        final produit = Produit.fromMap(doc.data());
        await _dbHelper.insertProduit(produit.toMap());
      }

      // Récupérer les ventes depuis Firebase
      final ventesFirestore = await _firestore
          .collection('utilisateurs')
          .doc(idUtilisateur)
          .collection('ventes')
          .get();

      for (final doc in ventesFirestore.docs) {
        final vente = Vente(
          idVente: doc.id,
          date: DateTime.parse(doc['date']), // Convertir String en DateTime
          produitsVendus: (doc['produitsVendus'] as List)
              .map((p) => ProduitVendu.fromMap(p))
              .toList(),
          montantTotal: doc['montantTotal'],
          idUtilisateur: doc['idUtilisateur'],
        );
        await _dbHelper.insertVente(vente.toMap());
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Restauration des données terminée avec succès.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la restauration des données : $e')),
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
  }

  Future<void> _synchroniserVentes(String idUtilisateur) async {
    try {
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
              'date': vente.date.toIso8601String(), // Convertir DateTime en String
              'produitsVendus': produitsVendusJson,
              'montantTotal': vente.montantTotal,
              'idUtilisateur': vente.idUtilisateur,
            });

        print('Marquage de la vente ${vente.idVente} comme synchronisée...');
        await _dbHelper.marquerVenteCommeSynchronisee(vente.idVente);
      }
    } catch (e) {
      print('Erreur lors de la synchronisation des ventes: $e');
    }
  }

  Future<void> _synchroniserUtilisateur(String idUtilisateur) async {
    final prefs = await SharedPreferences.getInstance();
    final nom = prefs.getString('nom');
    final numero = prefs.getString('numero');
    final nomBoutique = prefs.getString('nomBoutique');
    final motDePasse = prefs.getString('motDePasse'); // Récupérer le mot de passe
    final codeSecret = prefs.getString('codeSecret'); // Récupérer le code secret

    if (nom == null || numero == null || nomBoutique == null || motDePasse == null || codeSecret == null) {
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
          'motDePasse': motDePasse, // Ajouter le mot de passe
          'codeSecret': codeSecret, // Ajouter le code secret
        });
  }
}