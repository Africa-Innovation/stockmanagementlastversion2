import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:stockmanagementversion2/model/recuModel.dart';
import 'package:flutter_esc_pos_utils/flutter_esc_pos_utils.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:image/image.dart' as img;
import 'package:shared_preferences/shared_preferences.dart'; // Pour stocker l'adresse MAC

class RecuPage extends StatefulWidget {
  final Recu recu;

  RecuPage({required this.recu});

  @override
  _RecuPageState createState() => _RecuPageState();
}

class _RecuPageState extends State<RecuPage> {
  ScreenshotController screenshotController = ScreenshotController();
  bool _isPrinting = false;
  List<BluetoothInfo> _bluetoothDevices = [];
  String? _selectedPrinterMac; // Adresse MAC de l'imprimante sélectionnée
  bool _isConnected = false; // État de la connexion Bluetooth

  @override
  void initState() {
    super.initState();
    _loadPrinterMacAddress(); // Charge l'adresse MAC de l'imprimante au démarrage
    _getBluetoothDevices(); // Récupère les appareils Bluetooth appairés
  }

  // Charge l'adresse MAC de l'imprimante depuis les préférences locales
  Future<void> _loadPrinterMacAddress() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedPrinterMac = prefs.getString('printer_mac_address');
    });

    // Si une adresse MAC est trouvée, tentez de vous reconnecter
    if (_selectedPrinterMac != null) {
      await _connectToPrinter(_selectedPrinterMac!);
    }
  }

  // Enregistre l'adresse MAC de l'imprimante dans les préférences locales
  Future<void> _savePrinterMacAddress(String macAddress) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('printer_mac_address', macAddress);
  }

  // Récupère les appareils Bluetooth appairés
  Future<void> _getBluetoothDevices() async {
    final List<BluetoothInfo> devices = await PrintBluetoothThermal.pairedBluetooths;
    setState(() {
      _bluetoothDevices = devices;
    });
  }

  // Connecte à l'imprimante Bluetooth
  Future<void> _connectToPrinter(String macAddress) async {
    setState(() {
      _isPrinting = true;
    });

    try {
      final bool isConnected = await PrintBluetoothThermal.connect(macPrinterAddress: macAddress);
      setState(() {
        _isConnected = isConnected;
      });

      if (isConnected) {
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la connexion à l\'imprimante.')),
      );
    } finally {
      setState(() {
        _isPrinting = false;
      });
    }
  }

  // Imprime le reçu via Bluetooth
  Future<void> _printReceiptViaBluetooth() async {
  if (_selectedPrinterMac == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Veuillez sélectionner une imprimante Bluetooth.')),
    );
    return;
  }

  // Vérifie l'état de la connexion
  final bool isConnected = await PrintBluetoothThermal.connectionStatus;
  if (!isConnected) {
    await _connectToPrinter(_selectedPrinterMac!); // Reconnecte si nécessaire
  }

  setState(() {
    _isPrinting = true;
  });

  try {
    // Capture le reçu en tant qu'image
    final Uint8List? imageBytes = await screenshotController.capture();
    if (imageBytes == null) return;

    // Convertit l'image en format imprimable
    img.Image? image = img.decodeImage(imageBytes);
    if (image == null) return;

    // Redimensionne l'image pour l'imprimante
    final resizedImage = img.copyResize(image, width: 380); // Ajustez la largeur pour une imprimante 58mm

    // Génère le ticket d'impression
    final profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm58, profile);
    List<int> bytes = [];
    bytes += generator.reset(); // Réinitialise l'imprimante
    bytes += generator.feed(2); // Ajoute un espace pour vider le buffer
    bytes += generator.image(resizedImage);
    bytes += generator.feed(2);
    bytes += generator.cut();

    // Envoie le ticket à l'imprimante
    final bool result = await PrintBluetoothThermal.writeBytes(bytes);
    if (result) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Reçu imprimé avec succès ! 🖨️')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Échec de l\'impression.')),
      );
    }
  } catch (e) {
    print("Erreur lors de l'impression : $e");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Erreur lors de l\'impression.')),
    );
  } finally {
    // Ferme la connexion Bluetooth après l'impression
    await PrintBluetoothThermal.disconnect;
    setState(() {
      _isPrinting = false;
      _isConnected = false; // Réinitialise l'état de la connexion
    });
  }
}

  // Sauvegarde le reçu en tant qu'image dans la galerie
  Future<void> _saveReceiptAsImage() async {
    try {
      if (await Permission.storage.request().isGranted) {
        final Uint8List? image = await screenshotController.capture();
        if (image == null) return;

        final directory = await getApplicationDocumentsDirectory();
        final imagePath =
            '${directory.path}/receipt_${DateTime.now().millisecondsSinceEpoch}.png';
        final File imageFile = File(imagePath);
        await imageFile.writeAsBytes(image);

        await GallerySaver.saveImage(imageFile.path, albumName: "StockManagement");

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Reçu enregistré dans la galerie ! 📸')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Permission refusée, activez l’accès au stockage.')),
        );
      }
    } catch (e) {
      print("Erreur lors de l'enregistrement du reçu : $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de l\'enregistrement du reçu.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final lines = widget.recu.contenu.split('\n');

    return Scaffold(
      appBar: AppBar(
        title: Text('Reçu de Vente',
        style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue.shade800,
        elevation: 8,
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
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    padding: EdgeInsets.all(20),
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
                          SizedBox(height: 10),
                          Text(
                            'Boutique: ${widget.recu.nomBoutique}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 10),
                          Text(
                            'ID de la vente: ${widget.recu.idVente}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 10),
                          Divider(thickness: 1, color: Colors.black),
                          SizedBox(height: 10),
                          Text(
                            'Date: ${DateTime.now()}',
                            style: TextStyle(fontSize: 16),
                          ),
                          SizedBox(height: 10),
                          Divider(thickness: 1, color: Colors.black),
                          SizedBox(height: 10),
                          Text(
                            'Produits vendus:',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          if (lines.length > 3)
                            ...lines.sublist(3, lines.length - 1).map((line) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    line,
                                    style: TextStyle(fontSize: 16),
                                  ),
                                  SizedBox(height: 8),
                                ],
                              );
                            }).toList(),
                          SizedBox(height: 10),
                          Divider(thickness: 1, color: Colors.black),
                          SizedBox(height: 10),
                          if (lines.isNotEmpty && lines.last.contains(': '))
                            Text(
                              'Montant total: ${lines.last.split(': ')[1]}',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: _saveReceiptAsImage,
                  icon: Icon(Icons.download),
                  label: Text(
                    'Télécharger le reçu',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
                SizedBox(height: 20),
                if (_bluetoothDevices.isEmpty)
                  Text(
                    'Aucune imprimante Bluetooth appairée trouvée.',
                    style: TextStyle(color: Colors.red),
                  )
                else
                  DropdownButton<String>(
                    value: _selectedPrinterMac,
                    hint: Text('Sélectionnez une imprimante Bluetooth'),
                    items: _bluetoothDevices.map((BluetoothInfo device) {
                      return DropdownMenuItem<String>(
                        value: device.macAdress,
                        child: Text(device.name),
                      );
                    }).toList(),
                    onChanged: (String? value) {
                      setState(() {
                        _selectedPrinterMac = value;
                      });
                      if (value != null) {
                        _savePrinterMacAddress(value); // Enregistre l'adresse MAC
                        _connectToPrinter(value); // Connecte à l'imprimante
                      }
                    },
                  ),
                SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: _isPrinting || _selectedPrinterMac == null
                      ? null
                      : _printReceiptViaBluetooth,
                  icon: Icon(Icons.print),
                  label: Text(
                    _isPrinting ? 'Impression en cours...' : 'Imprimer via Bluetooth',
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