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

 Future<Utilisateur?> connecterUtilisateur(
  String numero, 
  String motDePasse, 
  BuildContext context,
) async {
  // Afficher un indicateur de chargement
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Connexion en cours...'),
          ],
        ),
      );
    },
  );

  try {
    final firestore = FirebaseFirestore.instance;

    // Rechercher l'utilisateur dans Firestore
    final querySnapshot = await firestore
        .collection('utilisateurs')
        .where('numero', isEqualTo: numero)
        .where('motDePasse', isEqualTo: motDePasse)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      final userDoc = querySnapshot.docs.first;
      final utilisateur = Utilisateur.fromMap(userDoc.data());

      // Enregistrer les informations de l'utilisateur dans SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('idUtilisateur', utilisateur.idUtilisateur!);
      await prefs.setString('nom', utilisateur.nom);
      await prefs.setString('numero', utilisateur.numero);
      await prefs.setString('nomBoutique', utilisateur.nomBoutique);
      await prefs.setString('motDePasse', utilisateur.motDePasse);
      await prefs.setString('codeSecret', utilisateur.codeSecret);

      print('Utilisateur trouvé dans Firestore: ${utilisateur.idUtilisateur}');

      // Récupérer les données de Firestore et les stocker localement
      final dbHelper = DatabaseHelper();
      await dbHelper.insertUtilisateur(utilisateur.toMap());

      // Synchroniser les données après la connexion
      final synchronisationService = SynchronisationService();
      await synchronisationService.synchroniserDonnees(context);

      // Fermer l'indicateur de chargement
      Navigator.of(context).pop();

      // Rediriger vers la page d'accueil
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomePage()),
      );

      return utilisateur;
    } else {
      // Fermer l'indicateur de chargement
      Navigator.of(context).pop();

      print('Aucun utilisateur trouvé avec le numéro: $numero');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Identifiants incorrects')),
      );
      return null;
    }
  } catch (e) {
    // Fermer l'indicateur de chargement en cas d'erreur
    Navigator.of(context).pop();

    print('Erreur lors de la connexion: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Erreur lors de la connexion. Veuillez réessayer.')),
    );
    return null;
  }
}
}