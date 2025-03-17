// utils/permission_handler.dart
import 'package:permission_handler/permission_handler.dart';

class PermissionHandler {
  // Demande les permissions Bluetooth et de localisation
  static Future<void> requestBluetoothPermissions() async {
    // Demande la permission Bluetooth
    if (await Permission.bluetooth.isDenied) {
      await Permission.bluetooth.request();
    }

    // Demande la permission de localisation (nécessaire pour Bluetooth sur Android 10+)
    if (await Permission.location.isDenied) {
      await Permission.location.request();
    }

    // Vérifie si les permissions sont accordées
    if (await Permission.bluetooth.isGranted && await Permission.location.isGranted) {
      print("Permissions Bluetooth et localisation accordées.");
    } else {
      print("Permissions Bluetooth ou localisation refusées.");
    }
  }

  // Demande la permission de stockage (pour sauvegarder des fichiers)
  static Future<void> requestStoragePermission() async {
    if (await Permission.storage.isDenied) {
      await Permission.storage.request();
    }

    if (await Permission.storage.isGranted) {
      print("Permission de stockage accordée.");
    } else {
      print("Permission de stockage refusée.");
    }
  }
}