import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stockmanagementversion2/controller/produitController.dart';
import 'package:stockmanagementversion2/firebase_options.dart';
import 'package:stockmanagementversion2/homePage.dart';
import 'package:stockmanagementversion2/model/produitModel.dart';
import 'package:stockmanagementversion2/service/notificationLocal.dart';
import 'package:stockmanagementversion2/views/connexionPage.dart';
// Importez le service de notifications

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('Firebase initialized successfully');
  } catch (e) {
    print('Error initializing Firebase: $e');
  }

  // Initialiser le service de notifications
  final notificationService = NotificationService();
  await notificationService.init();

  // Vérifier si l'utilisateur est connecté
  final prefs = await SharedPreferences.getInstance();
  final idUtilisateur = prefs.getString('idUtilisateur');

  if (idUtilisateur != null) {
    // Vérifier les stocks faibles au démarrage de l'application
    final produitController = ProduitController();
    final produits = await produitController.obtenirProduits(); // Pas d'argument
    for (final produit in produits) {
      if (produit.quantite <= produit.stockMinimum) {
        notificationService.showNotification(
          'Stock faible !',
          'Le stock de ${produit.nom} est faible. Veuillez réapprovisionner.',
        );
      }
    }
  }

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Menu Navigation',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: FutureBuilder(
        future: _checkIfUserIsLoggedIn(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Scaffold(body: Center(child: CircularProgressIndicator()));
          } else {
            return snapshot.data == true ? HomePage() : ConnexionPage();
          }
        },
      ),
    );
  }

  Future<bool> _checkIfUserIsLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isLoggedIn') ?? false; // Vérifier isLoggedIn
  }
}