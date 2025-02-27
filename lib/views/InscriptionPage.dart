import 'package:flutter/material.dart';
import 'package:stockmanagementversion2/controller/utilisateurController.dart';
import 'package:stockmanagementversion2/model/userModel.dart';
import 'package:stockmanagementversion2/views/connexionPage.dart';

class InscriptionPage extends StatelessWidget {
  final UtilisateurController _controller = UtilisateurController();
  final TextEditingController _nomController = TextEditingController();
  final TextEditingController _numeroController = TextEditingController();
  final TextEditingController _nomBoutiqueController = TextEditingController();
  final TextEditingController _motDePasseController = TextEditingController();
  final TextEditingController _confirmMotDePasseController = TextEditingController();
  final TextEditingController _codeSecretController = TextEditingController();

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
                    'Inscription',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade800,
                    ),
                  ),
                  SizedBox(height: 24),
                  TextField(
                    controller: _nomController,
                    decoration: InputDecoration(
                      labelText: 'Nom',
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
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
                    controller: _nomBoutiqueController,
                    decoration: InputDecoration(
                      labelText: 'Nom de la boutique',
                      prefixIcon: Icon(Icons.store),
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
                  SizedBox(height: 16),
                  TextField(
                    controller: _confirmMotDePasseController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Confirm Mot de passe',
                      prefixIcon: Icon(Icons.lock),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  TextField(
                    controller: _codeSecretController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Code secret',
                      prefixIcon: Icon(Icons.vpn_key),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () async {
                      // Vérifier que les mots de passe correspondent
                      if (_motDePasseController.text != _confirmMotDePasseController.text) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Les mots de passe ne correspondent pas')),
                        );
                        return;
                      }

                      // Vérifier que le code secret est correct
                      if (_codeSecretController.text != '@1111') {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Code secret incorrect. Le code doit être @1111')),
                        );
                        return;
                      }

                      // Créer un nouvel utilisateur
                      final utilisateur = Utilisateur(
                        idUtilisateur: DateTime.now().toString(),
                        nom: _nomController.text,
                        numero: _numeroController.text,
                        nomBoutique: _nomBoutiqueController.text,
                        motDePasse: _motDePasseController.text,
                        codeSecret: _codeSecretController.text,
                      );

                      // Enregistrer l'utilisateur dans la base de données
                      await _controller.inscrireUtilisateur(utilisateur);

                      // Afficher un message de succès
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Inscription réussie')),
                      );

                      // Rediriger vers l'écran de connexion
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => ConnexionPage()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade800,
                      padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'S\'inscrire',
                      style: TextStyle(fontSize: 16),
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