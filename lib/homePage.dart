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
  int _nombreAlertes = 0;
  double _ventesDuJour = 0.0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _chargerDonnees();
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
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
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade800)),
                  const SizedBox(height: 16),
                  Text(
                    'Connexion à l\'imprimante...',
                    style: TextStyle(
                      color: Colors.grey.shade800,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    try {
      final bool isConnected = await PrintBluetoothThermal.connect(macPrinterAddress: macAddress)
          .timeout(const Duration(seconds: 10), onTimeout: () {
        throw TimeoutException('La connexion a pris trop de temps.');
      });

      await Future.delayed(const Duration(seconds: 2));
      final bool isStillConnected = await PrintBluetoothThermal.connectionStatus;
      
      Navigator.of(context).pop();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isStillConnected 
              ? 'Connecté à l\'imprimante avec succès !' 
              : 'Échec de la connexion'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          backgroundColor: isStillConnected ? Colors.green.shade600 : Colors.red.shade400,
        ),
      );
    } on TimeoutException catch (e) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('La connexion a pris trop de temps'),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Erreur lors de la connexion'),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _selectPrinter(BuildContext context) async {
    final List<BluetoothInfo> devices = await PrintBluetoothThermal.pairedBluetooths;
    final String? selectedPrinterMac = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Sélectionnez une imprimante',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          content: Container(
            width: double.maxFinite,
            child: DropdownButton<String>(
              isExpanded: true,
              hint: const Text('Choisissez une imprimante'),
              items: devices.map((BluetoothInfo device) {
                return DropdownMenuItem<String>(
                  value: device.macAdress,
                  child: Text(
                    device.name,
                    style: const TextStyle(fontSize: 14),
                  ),
                );
              }).toList(),
              onChanged: (String? value) {
                Navigator.of(context).pop(value);
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Annuler'),
            ),
          ],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
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
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.store_rounded, size: 28),
            ),
            const SizedBox(width: 12),
            const Text(
              'YA FASSI',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
                color: Colors.white
              ),
            ),
          ],
        ),
        backgroundColor: Colors.blueAccent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.sync_rounded, size: 24),
            onPressed: () async {
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) {
                  return Dialog(
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade800),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Synchronisation en cours...',
                              style: TextStyle(
                                color: Colors.grey.shade800,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );

              try {
                final synchronisationService = SynchronisationService();
                await synchronisationService.synchroniserDonnees(context);
                Navigator.of(context).pop();
                // ScaffoldMessenger.of(context).showSnackBar(
                //   SnackBar(
                //     content: Text('Synchronisation réussie'),
                //     behavior: SnackBarBehavior.floating,
                //     shape: RoundedRectangleBorder(
                //       borderRadius: BorderRadius.circular(8),
                //     ),
                //     backgroundColor: Colors.green.shade600,
                //   ),
                // );
              } catch (e) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Erreur lors de la synchronisation'),
                    backgroundColor: Colors.red.shade400,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.person_rounded, size: 24),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ProfilPage()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tableau de bord',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 16),

            // Cartes de statut
            Row(
              children: [
                Expanded(
                  child: _buildStatusCard(
                    icon: Icons.warning_amber_rounded,
                    title: 'Alertes Stock',
                    value: '$_nombreAlertes',
                    color: Colors.red.shade400,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => AlertesStockPage()),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatusCard(
                    icon: Icons.attach_money_rounded,
                    title: 'Ventes du jour',
                    value: '${_ventesDuJour.toStringAsFixed(2)} FCFA',
                    color: Colors.green.shade600,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => VentesPage()),
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Actions rapides
            Text(
              'Actions rapides',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.inventory_rounded,
                    label: 'Gérer produits',
                    color: Colors.blue.shade700,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => GestionProduitsPage()),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.shopping_cart_rounded,
                    label: 'Nouvelle vente',
                    color: Colors.green.shade700,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => VentesPage()),
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Fonctionnalités
            Text(
              'Fonctionnalités',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 12),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.2,
              children: [
                _buildFeatureTile(
                  icon: Icons.history_rounded,
                  title: 'Historique',
                  color: Colors.purple.shade600,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => HistoriqueVentesPage()),
                    );
                  },
                ),
                _buildFeatureTile(
                  icon: Icons.bar_chart_rounded,
                  title: 'Statistiques',
                  color: Colors.orange.shade600,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => StatisticPage()),
                    );
                  },
                ),
                _buildFeatureTile(
                  icon: Icons.print_rounded,
                  title: 'Imprimante',
                  color: Colors.blueGrey.shade600,
                  onTap: () async {
                    // Demander les permissions Bluetooth et de localisation
                    await PermissionHandler.requestBluetoothPermissions();
                    await _selectPrinter(context);
                  },
                ),
                _buildFeatureTile(
                  icon: Icons.calculate_rounded,
                  title: 'Calculatrice',
                  color: Colors.teal.shade600,
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
      ),
    );
  }

  Widget _buildStatusCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 20, color: color),
                ),
                const Spacer(),
                Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 0,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 22),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureTile({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 28, color: color),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}