import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
            ListTile(
              title: const Text('Statistique'),
//               onTap: () {
//                 Navigator.of(context).push(
//   MaterialPageRoute(
//     builder: (context) => TendanceVentesPage(),
//   ),
// );
//               },
            ),
            ListTile(
              title: const Text('Synchro'),
              // onTap: () {
              //   Navigator.pushNamed(context, '/AlertesStockPage');
              // },
            ),
            ListTile(
              title: Text('Déconnexion'),
              onTap: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool('isLoggedIn', false); // Déconnecter l'utilisateur
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => ConnexionPage()),
                );
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