// import 'package:flutter/material.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:stockmanagementversion2/controller/utilisateurController.dart';
// import 'package:stockmanagementversion2/model/userModel.dart';
// import 'package:stockmanagementversion2/views/connexionPage.dart';
// import 'package:uuid/uuid.dart';

// class InscriptionPage extends StatelessWidget {
//   final UtilisateurController _controller = UtilisateurController();
//   final TextEditingController _nomController = TextEditingController();
//   final TextEditingController _numeroController = TextEditingController();
//   final TextEditingController _nomBoutiqueController = TextEditingController();
//   final TextEditingController _motDePasseController = TextEditingController();
//   final TextEditingController _confirmMotDePasseController =
//       TextEditingController();
//   final TextEditingController _codeSecretController = TextEditingController();

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Container(
//         decoration: BoxDecoration(
//           gradient: LinearGradient(
//             colors: [Colors.blue.shade800, Colors.blue.shade400],
//             begin: Alignment.topLeft,
//             end: Alignment.bottomRight,
//           ),
//         ),
//         child: Center(
//           child: Card(
//             elevation: 8,
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(16),
//             ),
//             margin: EdgeInsets.all(16),
//             child: Padding(
//               padding: const EdgeInsets.all(24.0),
//               child: SingleChildScrollView(
//                 child: Column(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     Text(
//                       'Inscription',
//                       style: TextStyle(
//                         fontSize: 28,
//                         fontWeight: FontWeight.bold,
//                         color: Colors.blue.shade800,
//                       ),
//                     ),
//                     SizedBox(height: 24),
//                     TextField(
//                       controller: _nomController,
//                       decoration: InputDecoration(
//                         labelText: 'Nom',
//                         prefixIcon: Icon(Icons.person),
//                         border: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(8),
//                         ),
//                       ),
//                     ),
//                     SizedBox(height: 16),
//                     TextField(
//                       controller: _numeroController,
//                       decoration: InputDecoration(
//                         labelText: 'Numéro de téléphone',
//                         prefixIcon: Icon(Icons.phone),
//                         border: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(8),
//                         ),
//                       ),
//                     ),
//                     SizedBox(height: 16),
//                     TextField(
//                       controller: _nomBoutiqueController,
//                       decoration: InputDecoration(
//                         labelText: 'Nom de la boutique',
//                         prefixIcon: Icon(Icons.store),
//                         border: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(8),
//                         ),
//                       ),
//                     ),
//                     SizedBox(height: 16),
//                     TextField(
//                       controller: _motDePasseController,
//                       obscureText: true,
//                       decoration: InputDecoration(
//                         labelText: 'Mot de passe',
//                         prefixIcon: Icon(Icons.lock),
//                         border: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(8),
//                         ),
//                       ),
//                     ),
//                     SizedBox(height: 16),
//                     TextField(
//                       controller: _confirmMotDePasseController,
//                       obscureText: true,
//                       decoration: InputDecoration(
//                         labelText: 'Confirm Mot de passe',
//                         prefixIcon: Icon(Icons.lock),
//                         border: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(8),
//                         ),
//                       ),
//                     ),
//                     SizedBox(height: 16),
//                     TextField(
//                       controller: _codeSecretController,
//                       obscureText: true,
//                       decoration: InputDecoration(
//                         labelText: 'Code secret',
//                         prefixIcon: Icon(Icons.vpn_key),
//                         border: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(8),
//                         ),
//                       ),
//                     ),
//                     SizedBox(height: 24),
//                     ElevatedButton(
//                       onPressed: () async {
//                         // Vérifier que les mots de passe correspondent
//                         if (_motDePasseController.text !=
//                             _confirmMotDePasseController.text) {
//                           ScaffoldMessenger.of(context).showSnackBar(
//                             SnackBar(
//                                 content: Text(
//                                     'Les mots de passe ne correspondent pas')),
//                           );
//                           return;
//                         }

//                         // Vérifier que le code secret est correct
//                         if (_codeSecretController.text != '@1111') {
//                           ScaffoldMessenger.of(context).showSnackBar(
//                             SnackBar(
//                                 content: Text(
//                                     'Code secret incorrect. Le code doit être @1111')),
//                           );
//                           return;
//                         }

//                         // Créer un nouvel utilisateur
//                         final utilisateur = Utilisateur(
//                           idUtilisateur:
//                               Uuid().v4(), // Génération d'un UUID unique
//                           nom: _nomController.text,
//                           numero: _numeroController.text,
//                           nomBoutique: _nomBoutiqueController.text,
//                           motDePasse: _motDePasseController.text,
//                           codeSecret: _codeSecretController.text,
//                         );

//                         // Enregistrer l'utilisateur dans la base de données
//                         await _controller.inscrireUtilisateur(utilisateur);

//                         // Enregistrer les informations de l'utilisateur dans SharedPreferences
//                         final prefs = await SharedPreferences.getInstance();
//                         await prefs.setString(
//                             'idUtilisateur', utilisateur.idUtilisateur!);
//                         await prefs.setString('nom', utilisateur.nom);
//                         await prefs.setString('numero', utilisateur.numero);
//                         await prefs.setString(
//                             'nomBoutique', utilisateur.nomBoutique);

//                         // Afficher un message de succès
//                         ScaffoldMessenger.of(context).showSnackBar(
//                           SnackBar(content: Text('Inscription réussie')),
//                         );

//                         // Rediriger vers l'écran de connexion
//                         Navigator.pushReplacement(
//                           context,
//                           MaterialPageRoute(
//                               builder: (context) => ConnexionPage()),
//                         );
//                       },
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: Colors.blue.shade800,
//                         padding:
//                             EdgeInsets.symmetric(horizontal: 32, vertical: 12),
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(8),
//                         ),
//                       ),
//                       child: Text(
//                         'S\'inscrire',
//                         style: TextStyle(fontSize: 16),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stockmanagementversion2/controller/utilisateurController.dart';
import 'package:stockmanagementversion2/model/userModel.dart';
import 'package:stockmanagementversion2/views/connexionPage.dart';
import 'package:uuid/uuid.dart';

class InscriptionPage extends StatefulWidget {
  @override
  _InscriptionPageState createState() => _InscriptionPageState();
}

class _InscriptionPageState extends State<InscriptionPage> {
  final UtilisateurController _controller = UtilisateurController();
  final TextEditingController _nomController = TextEditingController();
  final TextEditingController _numeroController = TextEditingController();
  final TextEditingController _nomBoutiqueController = TextEditingController();
  final TextEditingController _motDePasseController = TextEditingController();
  final TextEditingController _confirmMotDePasseController =
      TextEditingController();
  final TextEditingController _codeSecretController = TextEditingController();

  bool _isLoading = false; // État pour gérer le chargement

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
              child: SingleChildScrollView(
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
                      keyboardType: TextInputType.number, // Afficher un clavier numérique
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
                      onPressed: _isLoading ? null : _handleInscription, // Désactiver le bouton pendant le chargement
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade800,
                        padding:
                            EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isLoading
                          ? CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white), // Afficher un indicateur de chargement
                          )
                          : Text(
                              'S\'inscrire',
                              style: TextStyle(fontSize: 16,
                               color: Colors.white),
                              
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

  Future<void> _handleInscription() async {
  // Vérifier que tous les champs sont remplis
  if (_nomController.text.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Veuillez entrer votre nom')),
    );
    return;
  }

  if (_numeroController.text.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Veuillez entrer votre numéro de téléphone')),
    );
    return;
  }

  if (_nomBoutiqueController.text.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Veuillez entrer le nom de votre boutique')),
    );
    return;
  }

  // Vérifier que le mot de passe a au moins 4 caractères
  if (_motDePasseController.text.length < 4) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Le mot de passe doit contenir au moins 4 caractères')),
    );
    return;
  }

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
      SnackBar(content: Text('Code secret incorrect.')),
    );
    return;
  }

  setState(() {
    _isLoading = true; // Activer le chargement
  });

  try {
    // Créer un nouvel utilisateur
    final utilisateur = Utilisateur(
      idUtilisateur: Uuid().v4(), // Génération d'un UUID unique
      nom: _nomController.text,
      numero: _numeroController.text,
      nomBoutique: _nomBoutiqueController.text,
      motDePasse: _motDePasseController.text,
      codeSecret: _codeSecretController.text,
    );

    // Enregistrer l'utilisateur dans la base de données
    await _controller.inscrireUtilisateur(utilisateur);

    // Enregistrer les informations de l'utilisateur dans SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('idUtilisateur', utilisateur.idUtilisateur!);
    await prefs.setString('nom', utilisateur.nom);
    await prefs.setString('numero', utilisateur.numero);
    await prefs.setString('nomBoutique', utilisateur.nomBoutique);

    // Afficher un message de succès
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Inscription réussie')),
    );

    // Rediriger vers l'écran de connexion
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => ConnexionPage()),
    );
  } catch (e) {
    // Afficher un message d'erreur en cas d'échec
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Erreur lors de l\'inscription : $e')),
    );
  } finally {
    setState(() {
      _isLoading = false; // Désactiver le chargement
    });
  }
}
}