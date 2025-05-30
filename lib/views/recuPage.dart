import 'dart:async';
import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:stockmanagementversion2/model/recuModel.dart';
import 'package:flutter_esc_pos_utils/flutter_esc_pos_utils.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stockmanagementversion2/service/firestore_service.dart';

class RecuPage extends StatefulWidget {
  final Recu recu;

  RecuPage({required this.recu});

  @override
  _RecuPageState createState() => _RecuPageState();
}

class _RecuPageState extends State<RecuPage> {
  ScreenshotController screenshotController = ScreenshotController();
  bool _isPrinting = false;
  String? _selectedPrinterMac;

  @override
  void initState() {
    super.initState();
    _loadPrinterMacAddress();
  }

  // Charge l'adresse MAC de l'imprimante depuis les préférences locales
  Future<void> _loadPrinterMacAddress() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedPrinterMac = prefs.getString('printer_mac_address');
    });
  }

  String formatIdVente(String id) {
    if (id.length <= 12) return id; // Pas besoin de tronquer
    return '${id.substring(0, 6)}...${id.substring(id.length - 6)}';
  }

  // Imprime le reçu via Bluetooth
  Future<void> _printReceiptViaBluetooth() async {
    // Demander les permissions Bluetooth et de localisation
    await PermissionHandler.requestBluetoothPermissions();
    if (_selectedPrinterMac == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
              'Aucune imprimante configurée. Veuillez configurer l\'imprimante.'),
          action: SnackBarAction(
            label: 'Configurer',
            onPressed: () async {
              await _selectPrinter(
                  context); // Ouvrir la boîte de dialogue pour configurer l'imprimante
            },
          ),
        ),
      );
      return;
    }

    setState(() {
      _isPrinting = true;
    });

    try {
      // Vérifie l'état de la connexion
      bool isConnected = await PrintBluetoothThermal.connectionStatus;
      if (!isConnected) {
        // Si non connecté, tente de se connecter via l'adresse MAC
        isConnected = await PrintBluetoothThermal.connect(
                macPrinterAddress: _selectedPrinterMac!)
            .timeout(const Duration(seconds: 10), onTimeout: () {
          throw TimeoutException('La connexion a pris trop de temps.');
        });
      }

      if (!isConnected) {
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(
              content: const Text('Impossible de se connecter à l\'imprimante.'),
              backgroundColor: Colors.red.shade400,),
        );
        return;
      }

      // Génère le ticket d'impression en texte brut
      final profile = await CapabilityProfile.load();
      final generator = Generator(PaperSize.mm58, profile);
      List<int> bytes = [];

      // En-tête du reçu
      bytes += generator.text('Reçu de Vente',
          styles: const PosStyles(align: PosAlign.center, bold: true));
      bytes += generator.text('Boutique: ${widget.recu.nomBoutique}',
          styles: const PosStyles(align: PosAlign.left));
      bytes += generator.text(
          'ID de la vente: ${formatIdVente(widget.recu.idVente)}',
          styles: const PosStyles(align: PosAlign.left));
      bytes += generator.text('Date: ${DateTime.now()}',
          styles: const PosStyles(align: PosAlign.left));
      bytes += generator.feed(1);
      bytes += generator.hr();

      // Détails des produits
      final lines = widget.recu.contenu.split('\n');
      if (lines.length > 3) {
        for (var line in lines.sublist(3, lines.length - 1)) {
          bytes += generator.text(line,
              styles: const PosStyles(align: PosAlign.left));
          bytes += generator.feed(1);
        }
      }

      // Total
      if (lines.isNotEmpty && lines.last.contains(': ')) {
        bytes += generator.hr();
        bytes += generator.text('Montant total: ${lines.last.split(': ')[1]}',
            styles: const PosStyles(align: PosAlign.right, bold: true));
      }

      bytes += generator.feed(2);
      bytes += generator.cut();

      // Envoie le ticket à l'imprimante
      final bool result = await PrintBluetoothThermal.writeBytes(bytes);
      if (result) {
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: const Text('Reçu imprimé avec succès ! 🖨️'),
          backgroundColor: Colors.green.shade600,),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: const Text('Échec de l\'impression.'),
          backgroundColor: Colors.red.shade400,),
        );
      }
    } on TimeoutException catch (e) {
      print("Timeout lors de la connexion : $e");
      ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(
            content:
                const Text('La connexion a pris trop de temps. Veuillez réessayer.'),
                backgroundColor: Colors.red.shade400,),
      );
    } catch (e) {
      print("Erreur lors de l'impression : $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('Erreur lors de l\'impression.'),
        backgroundColor: Colors.red.shade400,),
      );
    } finally {
      setState(() {
        _isPrinting = false;
      });
    }
  }

  // Sauvegarde le reçu en tant qu'image dans la galerie

  Future<void> _saveReceiptAsImage() async {
    try {
      final Uint8List? image = await screenshotController.capture();
      if (image == null) return;

      final directory = await getApplicationDocumentsDirectory();
      final imagePath =
          '${directory.path}/receipt_${DateTime.now().millisecondsSinceEpoch}.png';
      final File imageFile = File(imagePath);
      await imageFile.writeAsBytes(image);

      // Sauvegarder l'image dans la galerie avec MediaStore
      final bool? result = await GallerySaver.saveImage(imageFile.path,
          albumName: "StockManagement");

      if (result == true) {
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: const Text('Reçu enregistré dans la galerie ! 📸'),
          backgroundColor: Colors.green.shade600,),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(
              content: const Text('Échec de l\'enregistrement dans la galerie.'),
              backgroundColor: Colors.red.shade400,),
        );
      }
    } catch (e) {
      print("Erreur lors de l'enregistrement du reçu : $e");
      ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(
            content: const Text('Erreur lors de l\'enregistrement du reçu.'),
            backgroundColor: Colors.red.shade400,),
      );
    }
  }

  Future<void> _selectPrinter(BuildContext context) async {
    final List<BluetoothInfo> devices =
        await PrintBluetoothThermal.pairedBluetooths;
    final String? selectedPrinterMac = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Sélectionnez une imprimante Bluetooth'),
          content: DropdownButton<String>(
            hint: const Text(
              'Choisissez une imprimante',
              style: TextStyle(fontSize: 14),
            ),
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
      // Afficher un loader pendant la tentative de connexion
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return const AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Connexion à l\'imprimante en cours...'),
              ],
            ),
          );
        },
      );

      try {
        // Tenter de se connecter à l'imprimante sélectionnée
        final bool isConnected = await PrintBluetoothThermal.connect(
                macPrinterAddress: selectedPrinterMac)
            .timeout(const Duration(seconds: 10), onTimeout: () {
          throw TimeoutException('La connexion a pris trop de temps.');
        });

        if (isConnected) {
          // Si la connexion réussit, stocker l'adresse MAC et afficher un message de succès
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('printer_mac_address', selectedPrinterMac);
          setState(() {
            _selectedPrinterMac = selectedPrinterMac;
          });
          ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(
                content: const Text('Imprimante configurée avec succès !',
                ),
                backgroundColor: Colors.green.shade600,),
          );
        } else {
          // Si la connexion échoue, afficher un message d'erreur
          ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(
                content: const Text('Échec de la connexion à l\'imprimante.'),
                backgroundColor: Colors.red.shade400,),
          );
        }
      } on TimeoutException catch (e) {
        // Gérer le timeout
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(
              content: const Text(
                  'La connexion a pris trop de temps. Veuillez réessayer.'),
                  backgroundColor: Colors.red.shade400,),
        );
      } catch (e) {
        // Gérer les autres erreurs
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(
              content: const Text('Erreur lors de la connexion à l\'imprimante.'),
              backgroundColor: Colors.red.shade400,),
        );
      } finally {
        // Fermer le loader
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final lines = widget.recu.contenu.split('\n');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reçu de Vente',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            )),
        backgroundColor: Colors.blueAccent,
        elevation: 8,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.print, color: Colors.white),
            onPressed: _isPrinting || _selectedPrinterMac == null
                ? null
                : _printReceiptViaBluetooth,
            tooltip: 'Imprimer via Bluetooth',
          ),
          IconButton(
            icon: const Icon(Icons.settings,
                color: Colors.white), // Bouton de configuration
            onPressed: () async {
              // Demander les permissions Bluetooth et de localisation
              await PermissionHandler.requestBluetoothPermissions();
              await _selectPrinter(
                  context); // Ouvrir la boîte de dialogue pour sélectionner l'imprimante
            },
            tooltip: 'Configurer l\'imprimante',
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Screenshot(
                  controller: screenshotController,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.3),
                          spreadRadius: 3,
                          blurRadius: 5,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(20),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Text(
                              'Reçu de Vente',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade800,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Boutique: ${widget.recu.nomBoutique}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'ID de la vente: ${formatIdVente(widget.recu.idVente)}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Divider(thickness: 1, color: Colors.black),
                          const SizedBox(height: 10),
                          Text(
                            'Date: ${DateTime.now()}',
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 10),
                          const Divider(thickness: 1, color: Colors.black),
                          const SizedBox(height: 10),
                          const Text(
                            'Produits vendus:',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (lines.length > 3)
                            ...lines.sublist(3, lines.length - 1).map((line) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    line,
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                  const SizedBox(height: 8),
                                ],
                              );
                            }).toList(),
                          const SizedBox(height: 10),
                          const Divider(thickness: 1, color: Colors.black),
                          const SizedBox(height: 10),
                          if (lines.isNotEmpty && lines.last.contains(': '))
                            Text(
                              'Montant total: ${lines.last.split(': ')[1]}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: _saveReceiptAsImage,
                  icon: const Icon(Icons.download),
                  label: const Text(
                    'Télécharger le reçu',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
