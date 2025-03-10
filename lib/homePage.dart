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
        title: Row(
          children: [
            // Ajouter un logo ou une icône personnalisée
            Image.asset(
              'assets/icon.png', // Remplacez par le chemin de votre logo
              width: 40,
              height: 40,
            ),
            SizedBox(width: 10), // Espace entre le logo et le titre
            Text(
              'YA FASSI',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.blueAccent, // Couleur de fond personnalisée
        elevation: 10, // Ajouter une ombre
        actions: [
          // Ajouter des icônes d'action
          IconButton(
            icon: Icon(Icons.sync, color: Colors.white),
            onPressed: () async {
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
                        Text(
                            'Synchronisation en cours...Ce processus utilise la connexion internet'),
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
                  SnackBar(
                      content: Text('Synchronisation terminée avec succès.')),
                );
              } catch (e) {
                // Fermer la boîte de dialogue en cas d'erreur
                Navigator.of(context).pop();

                // Afficher un message d'erreur
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text('Erreur lors de la synchronisation : $e')),
                );
              }
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            FutureBuilder<SharedPreferences>(
              future: SharedPreferences.getInstance(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return DrawerHeader(
                    decoration: BoxDecoration(
                      color: Colors.blueAccent,
                    ),
                    child: Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  );
                } else if (snapshot.hasError) {
                  return DrawerHeader(
                    decoration: BoxDecoration(
                      color: Colors.blueAccent,
                    ),
                    child: Center(
                      child: Text(
                        'Erreur de chargement',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                  );
                } else {
                  final prefs = snapshot.data!;
                  final nom = prefs.getString('nom') ?? 'Nom inconnu';
                  final numero = prefs.getString('numero') ?? 'Numéro inconnu';
                  final nomBoutique =
                      prefs.getString('nomBoutique') ?? 'Boutique inconnue';

                  return DrawerHeader(
                    decoration: BoxDecoration(
                      color: Colors.blueAccent,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        CircleAvatar(
                          radius: 30, // Taille du cercle
                          backgroundColor:
                              Colors.white, // Couleur de fond du cercle
                          child: Icon(
                            Icons.person, // Icône de profil
                            size: 40, // Taille de l'icône
                            color: Colors.blueAccent, // Couleur de l'icône
                          ),
                        ),
                        SizedBox(height: 5),
                        Text(
                          'Bienvenue, $nom !',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Numéro: $numero',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          'Boutique: $nomBoutique',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  );
                }
              },
            ),
            
            ListTile(
              leading: Icon(Icons.inventory,
                  color: Colors.blueAccent), // Icône pour Gestion Produits
              title: Text('Gestion Produits'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => GestionProduitsPage()),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.shopping_cart,
                  color: Colors.blueAccent), // Icône pour Ventes Page
              title: Text('Ventes Page'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => VentesPage()),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.history,
                  color: Colors.blueAccent), // Icône pour Historique Ventes
              title: const Text('Historique Ventes'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => HistoriqueVentesPage()),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.warning,
                  color: Colors.blueAccent), // Icône pour Alertes Stock
              title: const Text('Alertes Stock'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AlertesStockPage()),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.bar_chart,
                  color: Colors.blueAccent), // Icône pour Statistique
              title: const Text('Statistique'),
              onTap: () {
                // Ajoutez ici la navigation vers la page des statistiques
              },
            ),
            ListTile(
              leading: Icon(Icons.sync,
                  color: Colors.blueAccent), // Icône pour Synchro
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
                          Text(
                              'Synchronisation en cours...Ce processus utilise la connexion internet'),
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
                    SnackBar(
                        content: Text('Synchronisation terminée avec succès.')),
                  );
                } catch (e) {
                  // Fermer la boîte de dialogue en cas d'erreur
                  Navigator.of(context).pop();

                  // Afficher un message d'erreur
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content:
                            Text('Erreur lors de la synchronisation : $e')),
                  );
                }
              },
            ),
            ListTile(
              leading: Icon(Icons.logout,
                  color: Colors.blueAccent), // Icône pour Déconnexion
              title: const Text('Déconnexion'),
              onTap: () async {
                // Afficher une boîte de dialogue pour demander la synchronisation avant la déconnexion
                final shouldSync = await showDialog<bool>(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: Text(
                          'Synchronisation requise, Si oui activez votre connexion internet'),
                      content: Text(
                          'Voulez-vous synchroniser vos données avant de vous déconnecter ? Si vous refusez, vos données locales seront supprimées.'),
                      actions: [
                        TextButton(
                          onPressed: () =>
                              Navigator.of(context).pop(false), // Refuser
                          child: Text('Non'),
                        ),
                        ElevatedButton(
                          onPressed: () =>
                              Navigator.of(context).pop(true), // Accepter
                          child: Text('Oui'),
                        ),
                      ],
                    );
                  },
                );

                // Si l'utilisateur ferme la boîte de dialogue sans choisir "Oui" ou "Non", on ne fait rien
                if (shouldSync == null) {
                  return; // On quitte la fonction sans rien faire
                }

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
                            Text(
                                'Synchronisation en cours...Ce processus utilise la connexion internet'),
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
                      SnackBar(
                          content:
                              Text('Synchronisation terminée avec succès.')),
                    );
                  } catch (e) {
                    // Fermer la boîte de dialogue en cas d'erreur
                    Navigator.of(context).pop();

                    // Afficher un message d'erreur
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content:
                              Text('Erreur lors de la synchronisation : $e')),
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
        child: Calculatrice(),
      ),
    );
  }
}
