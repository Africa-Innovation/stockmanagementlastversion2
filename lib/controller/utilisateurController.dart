import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stockmanagementversion2/homePage.dart';
import 'package:stockmanagementversion2/model/DatabaseHelper.dart';
import 'package:stockmanagementversion2/model/firebasesynch.dart';
import 'package:stockmanagementversion2/model/userModel.dart';

class UtilisateurController {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<void> inscrireUtilisateur(Utilisateur utilisateur) async {
  final dbHelper = DatabaseHelper();
  await dbHelper.insertUtilisateur(utilisateur.toMap());

  // Enregistrer l'utilisateur dans Firestore
  final firestore = FirebaseFirestore.instance;
  await firestore
      .collection('utilisateurs')
      .doc(utilisateur.idUtilisateur)
      .set(utilisateur.toMap());

  // Enregistrer les informations dans SharedPreferences
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('idUtilisateur', utilisateur.idUtilisateur!);
  await prefs.setString('nom', utilisateur.nom);
  await prefs.setString('numero', utilisateur.numero);
  await prefs.setString('nomBoutique', utilisateur.nomBoutique);
  await prefs.setString('motDePasse', utilisateur.motDePasse); // Ajouter le mot de passe
  await prefs.setString('codeSecret', utilisateur.codeSecret); // Ajouter le code secret

  print('Utilisateur enregistré dans Firestore avec l\'ID: ${utilisateur.idUtilisateur}');
}

 Future<Utilisateur?> connecterUtilisateur(String numero, String motDePasse) async {
  try {
    final firestore = FirebaseFirestore.instance;
    final querySnapshot = await firestore
        .collection('utilisateurs')
        .where('numero', isEqualTo: numero)
        .where('motDePasse', isEqualTo: motDePasse)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      final userDoc = querySnapshot.docs.first;
      final utilisateur = Utilisateur.fromMap(userDoc.data());

      // Insert local DB
      final dbHelper = DatabaseHelper();
      await dbHelper.insertUtilisateur(utilisateur.toMap());

      return utilisateur;
    }
    return null;
  } catch (e) {
    print('Erreur connexion: $e');
    return null;
  }
}

}