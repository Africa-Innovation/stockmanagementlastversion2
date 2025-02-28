import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:stockmanagementversion2/model/recuModel.dart';

class RecuPage extends StatefulWidget {
  final Recu recu;

  RecuPage({required this.recu});

  @override
  _RecuPageState createState() => _RecuPageState();
}

class _RecuPageState extends State<RecuPage> {
  ScreenshotController screenshotController = ScreenshotController();

  Future<void> _saveReceiptAsImage() async {
    try {
      // Vérifier et demander l'autorisation de stockage
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
                          'Boutique: ${widget.recu.nomBoutique}', // Afficher le nom de la boutique
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
                          if (lines.length > 1 && lines[1].contains(': '))
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
