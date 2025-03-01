import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stockmanagementversion2/model/DatabaseHelper.dart';
import 'package:stockmanagementversion2/model/firebasesynch.dart';
import 'package:stockmanagementversion2/views/alertStockPage.dart';
import 'package:stockmanagementversion2/views/calculatrice.dart';
import 'package:stockmanagementversion2/views/connexionPage.dart';
import 'package:stockmanagementversion2/views/gestionProduitPage.dart';
import 'package:stockmanagementversion2/views/historiqueVentePage.dart';
import 'package:stockmanagementversion2/views/statisticPage.dart';
import 'package:stockmanagementversion2/views/ventePage.dart';

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home Page'),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Text(
                'Menu',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              title: Text('Gestion Produits'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => GestionProduitsPage()),
                );
              },
            ),
            ListTile(
              title: Text('Ventes Page'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => VentesPage()),
                );
              },
            ),
            ListTile(
              title: const Text('Historique Ventes'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => HistoriqueVentesPage()),
                );
              },
            ),
            ListTile(
              title: const Text('Alertes Stock'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AlertesStockPage()),
                );
              },
            ),
            const ListTile(
              title: Text('Statistique'),

            ),
            ListTile(
  title: const Text('Synchro'),
  onTap: () async {
    // Afficher une boîte de dialogue pour indiquer que la synchronisation est en cours
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
              Text('Synchronisation en cours...Ce processus utilise la connexion internet'),
            ],
          ),
        );
      },
    );

    try {
      final synchronisationService = SynchronisationService();
      await synchronisationService.synchroniserDonnees(context);

      // Fermer la boîte de dialogue
      Navigator.of(context).pop();

      // Afficher un message de succès
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Synchronisation terminée avec succès.')),
      );
    } catch (e) {
      // Fermer la boîte de dialogue en cas d'erreur
      Navigator.of(context).pop();

      // Afficher un message d'erreur
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la synchronisation : $e')),
      );
    }
  },
),
            ListTile(
  title: const Text('Déconnexion'),
  onTap: () async {
    // Afficher une boîte de dialogue pour demander la synchronisation avant la déconnexion
    final shouldSync = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Synchronisation requise, Si oui activez votre connexion internet'),
          content: Text(
              'Voulez-vous synchroniser vos données avant de vous déconnecter ? Si vous refusez, vos données locales seront supprimées.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false), // Refuser
              child: Text('Non'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true), // Accepter
              child: Text('Oui'),
            ),
          ],
        );
      },
    );

    if (shouldSync == true) {
      // Afficher une boîte de dialogue pour indiquer que la synchronisation est en cours
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
                Text('Synchronisation en cours...Ce processus utilise la connexion internet'),
              ],
            ),
          );
        },
      );

      try {
        final synchronisationService = SynchronisationService();
        await synchronisationService.synchroniserDonnees(context);

        // Fermer la boîte de dialogue
        Navigator.of(context).pop();

        // Afficher un message de succès
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Synchronisation terminée avec succès.')),
        );
      } catch (e) {
        // Fermer la boîte de dialogue en cas d'erreur
        Navigator.of(context).pop();

        // Afficher un message d'erreur
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la synchronisation : $e')),
        );
      }
    }

    // Supprimer les données locales
    final prefs = await SharedPreferences.getInstance();
    final idUtilisateur = prefs.getString('idUtilisateur');

    if (idUtilisateur != null) {
      final dbHelper = DatabaseHelper();
      await dbHelper.deleteAllLocalData(idUtilisateur);

      // Déconnecter l'utilisateur
      await prefs.setBool('isLoggedIn', false);
      await prefs.remove('idUtilisateur');
      await prefs.remove('nom');
      await prefs.remove('numero');
      await prefs.remove('nomBoutique');

      // Afficher un message de succès
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Déconnexion réussie.')),
      );

      // Rediriger vers la page de connexion
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => ConnexionPage()),
      );
    }
  },
),
          ],
        ),
      ),
      body: Center(
        child: Calculatrice()
      ),
    );
  }
}