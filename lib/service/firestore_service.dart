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

    // Pour Android 12 et supérieur, demander BLUETOOTH_SCAN et BLUETOOTH_CONNECT
    if (await Permission.bluetoothScan.isDenied) {
      await Permission.bluetoothScan.request();
    }
    if (await Permission.bluetoothConnect.isDenied) {
      await Permission.bluetoothConnect.request();
    }

    // Vérifier si les permissions sont accordées
    if (await Permission.bluetooth.isGranted &&
        await Permission.location.isGranted &&
        await Permission.bluetoothScan.isGranted &&
        await Permission.bluetoothConnect.isGranted) {
      print("Toutes les permissions Bluetooth et de localisation sont accordées.");
    } else {
      print("Certaines permissions Bluetooth ou de localisation sont refusées.");
    }
  }
}