import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stockmanagementversion2/controller/produitController.dart';
import 'package:stockmanagementversion2/homePage.dart';
import 'package:stockmanagementversion2/model/produitModel.dart';
import 'package:stockmanagementversion2/service/notificationLocal.dart';
import 'package:stockmanagementversion2/views/connexionPage.dart';
// Importez le service de notifications

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Assurez-vous que Flutter est initialisé
  final notificationService = NotificationService();
  await notificationService.init(); // Initialiser le service de notifications

  // Vérifier les stocks faibles au démarrage de l'application
  final produitController = ProduitController();
  final produits = await produitController.obtenirProduits('idUtilisateur');
  for (final produit in produits) {
    if (produit.quantite <= produit.stockMinimum) {
      notificationService.showNotification(
        'Stock faible !',
        'Le stock de ${produit.nom} est faible. Veuillez réapprovisionner.',
      );
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
    return prefs.getBool('isLoggedIn') ?? false;
  }
}