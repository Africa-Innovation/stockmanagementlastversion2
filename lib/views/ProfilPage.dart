import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stockmanagementversion2/model/DatabaseHelper.dart';
import 'package:stockmanagementversion2/model/firebasesynch.dart';
import 'package:stockmanagementversion2/views/connexionPage.dart';

class ProfilPage extends StatelessWidget {
  Future<void> _synchroniserDonnees(BuildContext context) async {
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
              Text('Synchronisation en cours... Ce processus utilise la connexion internet.'),
            ],
          ),
        );
      },
    );

    try {
      final synchronisationService = SynchronisationService();
      await synchronisationService.synchroniserDonnees(context);

      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Synchronisation terminée avec succès.')),
      );
    } catch (e) {
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la synchronisation : $e')),
      );
    }
  }

  Future<void> _deconnecterUtilisateur(BuildContext context) async {
    final shouldSync = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Synchronisation requise'),
          content: Text(
              'Voulez-vous synchroniser vos données avant de vous déconnecter ? Si vous refusez, vos données locales seront supprimées.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Non'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('Oui'),
            ),
          ],
        );
      },
    );
    // Si l'utilisateur ferme la boîte de dialogue sans choisir, on ne fait rien
  if (shouldSync == null) {
    return;
  }
    if (shouldSync == true) {
      await _synchroniserDonnees(context);
    }

    final prefs = await SharedPreferences.getInstance();
    final idUtilisateur = prefs.getString('idUtilisateur');

    if (idUtilisateur != null) {
      final dbHelper = DatabaseHelper();
      await dbHelper.deleteAllLocalData(idUtilisateur);

      await prefs.setBool('isLoggedIn', false);
      await prefs.remove('idUtilisateur');
      await prefs.remove('nom');
      await prefs.remove('numero');
      await prefs.remove('nomBoutique');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Déconnexion réussie.')),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => ConnexionPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profil', style: TextStyle(color: Colors.white),),
        backgroundColor: Colors.blueAccent,
        elevation: 10,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: FutureBuilder<SharedPreferences>(
        future: SharedPreferences.getInstance(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Erreur de chargement des données.'));
          } else {
            final prefs = snapshot.data!;
            final nom = prefs.getString('nom') ?? 'Nom inconnu';
            final numero = prefs.getString('numero') ?? 'Numéro inconnu';
            final nomBoutique = prefs.getString('nomBoutique') ?? 'Boutique inconnue';

            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.blueAccent,
                      child: Icon(
                        Icons.person,
                        size: 60,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Informations de l\'utilisateur',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  ListTile(
                    leading: Icon(Icons.person, color: Colors.blueAccent),
                    title: Text('Nom'),
                    subtitle: Text(nom),
                  ),
                  ListTile(
                    leading: Icon(Icons.phone, color: Colors.blueAccent),
                    title: Text('Numéro'),
                    subtitle: Text(numero),
                  ),
                  ListTile(
                    leading: Icon(Icons.store, color: Colors.blueAccent),
                    title: Text('Boutique'),
                    subtitle: Text(nomBoutique),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton.icon(
                    
                    onPressed: () => _synchroniserDonnees(context),
                    icon: Icon(Icons.sync),
                    label: Text('Synchroniser les données'),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                  SizedBox(height: 10),
                  ElevatedButton.icon(
                    onPressed: () => _deconnecterUtilisateur(context),
                    icon: Icon(Icons.logout),
                    label: Text('Déconnexion',style: TextStyle(color: Colors.white),),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.red,
                    ),
                  ),
                ],
              ),
            );
          }
        },
      ),
    );
  }
}