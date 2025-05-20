import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stockmanagementversion2/controller/produitController.dart';
import 'package:stockmanagementversion2/controller/venteController.dart';
import 'package:stockmanagementversion2/model/DatabaseHelper.dart';
import 'package:stockmanagementversion2/model/firebasesynch.dart';
import 'package:stockmanagementversion2/service/firestore_service.dart';
import 'package:stockmanagementversion2/views/ProfilPage.dart';
import 'package:stockmanagementversion2/views/alertStockPage.dart';
import 'package:stockmanagementversion2/views/calculatrice.dart';
import 'package:stockmanagementversion2/views/connexionPage.dart';
import 'package:stockmanagementversion2/views/gestionProduitPage.dart';
import 'package:stockmanagementversion2/views/historiqueVentePage.dart';
import 'package:stockmanagementversion2/views/statisticPage.dart';
import 'package:stockmanagementversion2/views/ventePage.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';

class HomePage extends StatefulWidget {
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ProduitController _controller = ProduitController();

  final VenteController _venteController = VenteController(); 
 // Ajoute le VenteController
  int _nombreAlertes = 0;

  double _ventesDuJour = 0.0;

  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _chargerDonnees();

    // Rafraîchir toutes les 5 secondes (modifiable)
    _timer = Timer.periodic(Duration(seconds: 5), (timer) {
      _chargerDonnees();
    });
  }

  Future<void> _chargerDonnees() async {
    final nombreAlertes = await _controller.verifierAlertesStock().then((list) => list.length);
    final ventesDuJour = await _calculerVentesDuJour();

    setState(() {
      _nombreAlertes = nombreAlertes;
      _ventesDuJour = ventesDuJour;
    });
  }

  Future<double> _calculerVentesDuJour() async {
    final prefs = await SharedPreferences.getInstance();
    final idUtilisateur = prefs.getString('idUtilisateur');
    if (idUtilisateur == null) return 0.0;

    final ventes = await _venteController.obtenirHistoriqueVentes(idUtilisateur);
    final ventesDuJour = ventes.where((vente) {
      final dateVente = DateFormat('yyyy-MM-dd').format(vente.date);
      final dateAujourdhui = DateFormat('yyyy-MM-dd').format(DateTime.now());
      return dateVente == dateAujourdhui;
    }).toList();

    final total = ventesDuJour.fold(0.0, (sum, vente) => sum + vente.montantTotal);
    return total;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _connectToPrinter(String macAddress, BuildContext context) async {
    // Afficher un loader
    showDialog(
      context: context,
      barrierDismissible: false, // Empêche l'utilisateur de fermer le dialogue
      builder: (context) {
        return AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(), // Loader
              SizedBox(height: 16),
              Text('Connexion à l\'imprimante en cours...'),
            ],
          ),
        );
      },
    );

    try {
      // Ajouter un timeout de 10 secondes pour la connexion
      final bool isConnected = await PrintBluetoothThermal.connect(macPrinterAddress: macAddress)
          .timeout(Duration(seconds: 10), onTimeout: () {
        throw TimeoutException('La connexion a pris trop de temps.');
      });

      await Future.delayed(Duration(seconds: 2)); // Simuler un délai supplémentaire

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
    } on TimeoutException catch (e) {
      print("Timeout lors de la connexion : $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('La connexion a pris trop de temps. Veuillez réessayer.')),
      );
    } catch (e) {
      print("Erreur lors de la connexion : $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la connexion à l\'imprimante.')),
      );
    } finally {
      Navigator.of(context).pop(); // Fermer le loader
    }
  }

  Future<void> _selectPrinter(BuildContext context) async {
    final List<BluetoothInfo> devices =
        await PrintBluetoothThermal.pairedBluetooths;
    final String? selectedPrinterMac = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Sélectionnez une imprimante Bluetooth'),
          content: DropdownButton<String>(
            hint: Text('Choisissez une imprimante',style: TextStyle(fontSize: 14),),
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
          automaticallyImplyLeading: false, // Désactive la flèche de retour
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
              icon: Icon(Icons.person, color: Colors.white),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ProfilPage()),
                );
              },
            ),
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
                        content:
                            Text('Erreur lors de la synchronisation : $e')),
                  );
                }
              },
            ),
          ],
        ),
        body: SingleChildScrollView(
            child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tableau de bord',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20),
              Card(
              elevation: 4,
              child: ListTile(
                leading: Icon(Icons.warning, color: Colors.red),
                title: Text('Alertes de stock'),
                subtitle: Text('$_nombreAlertes produits en alerte'),
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => AlertesStockPage()));
                },
              ),
            ),
            SizedBox(height: 10),
            Card(
              elevation: 4,
              child: ListTile(
                leading: Icon(Icons.shopping_cart, color: Colors.green),
                title: Text('Ventes du jour'),
                subtitle: Text('${_ventesDuJour.toStringAsFixed(2)} FCFA'),
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => VentesPage()));
                },
              ),
            ),
              SizedBox(height: 20),
              Text(
                'Actions rapides',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => GestionProduitsPage()),
                        );
                      },
                      icon: Icon(Icons.inventory),
                      label: Text('Gérer les produits'),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => VentesPage()),
                        );
                      },
                      icon: Icon(Icons.shopping_cart),
                      label: Text('Nouvelle vente'),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              Text(
                'Autres fonctionnalités',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              GridView(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                children: [
                  _buildFeatureCard(
                    icon: Icons.history,
                    title: 'Historique des ventes',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => HistoriqueVentesPage()),
                      );
                    },
                  ),
                  _buildFeatureCard(
                    icon: Icons.bar_chart,
                    title: 'Statistiques',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => StatisticPage()),
                      );
                    },
                  ),
                  _buildFeatureCard(
                    icon: Icons.print,
                    title: 'Configurer l\'imprimante',
                    onTap: () async {
                      // Demander les permissions Bluetooth et de localisation
    await PermissionHandler.requestBluetoothPermissions();
                      await _selectPrinter(context);
                    },
                  ),
                  _buildFeatureCard(
                    icon: Icons.calculate,
                    title: 'Calculatrice',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => Calculatrice()),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        )));
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: Colors.blueAccent),
              SizedBox(height: 10),
              Text(
                title,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}