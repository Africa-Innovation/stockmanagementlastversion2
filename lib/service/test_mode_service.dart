import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

class TestModeService {
  static const String _testModeKey = 'isTestMode';
   
  static const String _ventesKey = 'ventesEffectuees';
  
  static Future<bool> isTestMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_testModeKey) ?? true; // Par défaut en mode test
  }

  static Future<void> resetCounters() async {
  final prefs = await SharedPreferences.getInstance();
   
  await prefs.setInt(_ventesKey, 0);
}

static Future<Map<String, dynamic>> getCurrentState() async {
  return {
    'isTestMode': await isTestMode(),
     
    'ventesEffectuees': await getVentesEffectuees(),
  };
}
  
  
  
  static Future<int> getVentesEffectuees() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_ventesKey) ?? 0;
  }
  
   
  
  static Future<void> incrementVentesEffectuees() async {
    final prefs = await SharedPreferences.getInstance();
    final current = await getVentesEffectuees();
    await prefs.setInt(_ventesKey, current + 1);
  }
  
  static Future<void> switchToRealMode() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_testModeKey, false);
  }
  
  static Future<bool> checkLimits(BuildContext context) async {
  if (await isTestMode()) {
    final ventes = await getVentesEffectuees();
    //limite nombre de vente à 15 pour les modes testeurs
    if (ventes >= 15) {
      _showLimitReachedDialog(context);
      return true;
    }
  }
  return false;
}

  
  static void _showLimitReachedDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('Mode test terminé'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Vous avez atteint la limite du mode test.'),
            SizedBox(height: 20),
            Text('Contactez-nous au: +226 54 80 53 81 ou ouedraogoalex038@gmail.com pour obtenir le code secret'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
          TextButton(
            onPressed: () => _showCodeInputDialog(context),
            child: Text('Entrer le code'),
          ),
        ],
      ),
    );
  }
  
  static void _showCodeInputDialog(BuildContext context) {
    final codeController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Code secret'),
        content: TextField(
          controller: codeController,
          obscureText: true,
          decoration: InputDecoration(
            labelText: 'Entrez le code secret',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              if (codeController.text == '@1111') {
                await switchToRealMode();
                Navigator.pop(context); // Fermer la boîte de code
                Navigator.pop(context); // Fermer la boîte d'alerte
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Mode réel activé!')),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Code incorrect')),
                );
              }
            },
            child: Text('Valider'),
          ),
        ],
      ),
    );
  }
}