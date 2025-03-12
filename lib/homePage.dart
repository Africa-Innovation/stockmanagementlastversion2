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
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';

class HomePage extends StatelessWidget {
  Future<void> _connectToPrinter(String macAddress, BuildContext context) async {
  try {
    final bool isConnected = await PrintBluetoothThermal.connect(macPrinterAddress: macAddress);
    await Future.delayed(Duration(seconds: 2)); // Attendre 2 secondes

    final bool isStillConnected = await PrintBluetoothThermal.connectionStatus;
    if (isStillConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Connecté à l\'imprimante avec succès !')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Échec de la connexion à l\'imprimante.')),
      );
    }
  } catch (e) {
    print("Erreur lors de la connexion : $e");
    final bool isConnected = await PrintBluetoothThermal.connectionStatus;
    if (!isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la connexion à l\'imprimante.')),
      );
    }
  }
}

  Future<void> _selectPrinter(BuildContext context) async {
    final List<BluetoothInfo> devices = await PrintBluetoothThermal.pairedBluetooths;
    final String? selectedPrinterMac = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Sélectionnez une imprimante Bluetooth'),
          content: DropdownButton<String>(
            hint: Text('Choisissez une imprimante'),
            items: devices.map((BluetoothInfo device) {
              return DropdownMenuItem<String>(
                value: device.macAdress,
                child: Text(device.name),
              );
            }).toList(),
            onChanged: (String? value) {
              Navigator.of(context).pop(value);
            },
          ),
        );
      },
    );

    if (selectedPrinterMac != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('printer_mac_address', selectedPrinterMac);
      await _connectToPrinter(selectedPrinterMac, context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset(
              'assets/icon.png',
              width: 40,
              height: 40,
            ),
            SizedBox(width: 10),
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
        backgroundColor: Colors.blueAccent,
        elevation: 10,
        actions: [
          IconButton(
            icon: Icon(Icons.sync, color: Colors.white),
            onPressed: () async {
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

                Navigator.of(context).pop();

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text('Synchronisation terminée avec succès.')),
                );
              } catch (e) {
                Navigator.of(context).pop();

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
                          radius: 30,
                          backgroundColor: Colors.white,
                          child: Icon(
                            Icons.person,
                            size: 40,
                            color: Colors.blueAccent,
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
              leading: Icon(Icons.inventory, color: Colors.blueAccent),
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
              leading: Icon(Icons.shopping_cart, color: Colors.blueAccent),
              title: Text('Ventes Page'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => VentesPage()),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.history, color: Colors.blueAccent),
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
              leading: Icon(Icons.warning, color: Colors.blueAccent),
              title: const Text('Alertes Stock'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AlertesStockPage()),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.bar_chart, color: Colors.blueAccent),
              title: const Text('Statistique'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => StatisticPage()),
                );
                // Ajoutez ici la navigation vers la page des statistiques
              },
            ),
            ListTile(
              leading: Icon(Icons.sync, color: Colors.blueAccent),
              title: const Text('Synchro'),
              onTap: () async {
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

                  Navigator.of(context).pop();

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text('Synchronisation terminée avec succès.')),
                  );
                } catch (e) {
                  Navigator.of(context).pop();

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content:
                            Text('Erreur lors de la synchronisation : $e')),
                  );
                }
              },
            ),
            ListTile(
              leading: Icon(Icons.print, color: Colors.blueAccent),
              title: const Text('Configurer l\'imprimante'),
              onTap: () async {
                await _selectPrinter(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.logout, color: Colors.blueAccent),
              title: const Text('Déconnexion'),
              onTap: () async {
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
                              Navigator.of(context).pop(false),
                          child: Text('Non'),
                        ),
                        ElevatedButton(
                          onPressed: () =>
                              Navigator.of(context).pop(true),
                          child: Text('Oui'),
                        ),
                      ],
                    );
                  },
                );

                if (shouldSync == null) {
                  return;
                }

                if (shouldSync == true) {
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

                    Navigator.of(context).pop();

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content:
                              Text('Synchronisation terminée avec succès.')),
                    );
                  } catch (e) {
                    Navigator.of(context).pop();

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content:
                              Text('Erreur lors de la synchronisation : $e')),
                    );
                  }
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