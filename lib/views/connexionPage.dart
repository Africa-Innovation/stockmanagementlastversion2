import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stockmanagementversion2/controller/utilisateurController.dart';
import 'package:stockmanagementversion2/homePage.dart';
import 'package:stockmanagementversion2/model/firebasesynch.dart';
import 'package:stockmanagementversion2/views/InscriptionPage.dart';

class ConnexionPage extends StatelessWidget {
  final UtilisateurController _controller = UtilisateurController();
  final TextEditingController _numeroController = TextEditingController();
  final TextEditingController _motDePasseController = TextEditingController();

  ConnexionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade900, Colors.blue.shade400],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Card(
              elevation: 12,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              margin: const EdgeInsets.symmetric(horizontal: 16),
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
                    const SizedBox(height: 24),
                    TextField(
                      controller: _numeroController,
                      decoration: InputDecoration(
                        labelText: 'Numéro de téléphone',
                        prefixIcon: const Icon(Icons.phone),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _motDePasseController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'Mot de passe',
                        prefixIcon: const Icon(Icons.lock),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () async {
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (_) => const AlertDialog(
                            content: SizedBox(
                              height: 80,
                              child: Center(child: CircularProgressIndicator()),
                            ),
                          ),
                        );

                        final utilisateur =
                            await _controller.connecterUtilisateur(
                          _numeroController.text.trim(),
                          _motDePasseController.text.trim(),
                        );

                        Navigator.of(context).pop(); // Ferme le loader

                        if (utilisateur != null) {
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.setString(
                              'idUtilisateur', utilisateur.idUtilisateur!);
                          await prefs.setString('nom', utilisateur.nom);
                          await prefs.setString('numero', utilisateur.numero);
                          await prefs.setString(
                              'nomBoutique', utilisateur.nomBoutique);
                          await prefs.setBool('isLoggedIn', true);

                          final sync = SynchronisationService();
                          await sync.restaurerDonnees(context);

                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (_) => HomePage()),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Identifiants incorrects'),
                              backgroundColor: Colors.redAccent,
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.login),
                      label: const Text('Se Connecter'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade800,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 32, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => InscriptionPage()),
                        );
                      },
                      child: Text(
                        'Créer un compte',
                        style: TextStyle(
                          color: Colors.blue.shade800,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
