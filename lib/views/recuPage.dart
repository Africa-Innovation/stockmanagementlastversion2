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
  String? _selectedPrinterMac; // Utilisez `String?` pour autoriser une valeur nulle

  @override
  void initState() {
    super.initState();
    _getBluetoothDevices();
  }

  Future<void> _getBluetoothDevices() async {
    final List<BluetoothInfo> devices = await PrintBluetoothThermal.pairedBluetooths;
    setState(() {
      _bluetoothDevices = devices;
    });
  }

  Future<void> _printReceiptViaBluetooth() async {
    if (_selectedPrinterMac == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Veuillez sélectionner une imprimante Bluetooth.')),
      );
      return;
    }

    setState(() {
      _isPrinting = true;
    });

    try {
      // Connect to the selected printer
      final bool isConnected = await PrintBluetoothThermal.connect(macPrinterAddress: _selectedPrinterMac!);
      if (!isConnected) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Échec de la connexion à l\'imprimante.')),
        );
        return;
      }

      // Capture the receipt as an image
      final Uint8List? imageBytes = await screenshotController.capture();
      if (imageBytes == null) return;

      // Convert the image to a printable format
      img.Image? image = img.decodeImage(imageBytes);
      if (image == null) return;

      // Resize the image to fit the printer's width
      final resizedImage = img.copyResize(image, width: 380); // Adjust width for 58mm printer

      // Generate the print ticket
      final profile = await CapabilityProfile.load();
      final generator = Generator(PaperSize.mm58, profile);
      List<int> bytes = [];
      bytes += generator.reset();
      bytes += generator.image(resizedImage);
      bytes += generator.feed(2);
      bytes += generator.cut();

      // Send the ticket to the printer
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
      setState(() {
        _isPrinting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final lines = widget.recu.contenu.split('\n');

    return Scaffold(
      appBar: AppBar(
        title: Text('Reçu de Vente'),
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

        await GallerySaver.saveImage(imageFile.path,
            albumName: "StockManagement");

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Reçu enregistré dans la galerie ! 📸')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('Permission refusée, activez l’accès au stockage.')),
        );
      }
    } catch (e) {
      print("Erreur lors de l'enregistrement du reçu : $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de l\'enregistrement du reçu.')),
      );
    }
  }
}