import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stockmanagementversion2/controller/utilisateurController.dart';
import 'package:stockmanagementversion2/homePage.dart';
import 'package:stockmanagementversion2/views/InscriptionPage.dart';

class ConnexionPage extends StatelessWidget {
  final UtilisateurController _controller = UtilisateurController();
  final TextEditingController _numeroController = TextEditingController();
  final TextEditingController _motDePasseController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade800, Colors.blue.shade400],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Card(
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            margin: EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Connexion',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade800,
                    ),
                  ),
                  SizedBox(height: 24),
                  TextField(
                    controller: _numeroController,
                    decoration: InputDecoration(
                      labelText: 'Numéro de téléphone',
                      prefixIcon: Icon(Icons.phone),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  TextField(
                    controller: _motDePasseController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Mot de passe',
                      prefixIcon: Icon(Icons.lock),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () async {
  final utilisateur = await _controller.connecterUtilisateur(
    _numeroController.text,
    _motDePasseController.text,
  );

  if (utilisateur != null) {
    // Enregistrer l'état de connexion et le nom de la boutique
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', true);
    await prefs.setString('nomBoutique', utilisateur.nomBoutique); // Enregistrer le nom de la boutique

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => HomePage()),
    );
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Identifiants incorrects')),
    );
  }
},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade800,
                      padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Se Connecter',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                  SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => InscriptionPage()),
                      );
                    },
                    child: Text(
                      'Créer un compte',
                      style: TextStyle(color: Colors.blue.shade800),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}