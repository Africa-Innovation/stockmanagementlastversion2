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
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _nomController = TextEditingController();
  final TextEditingController _numeroController = TextEditingController();
  final TextEditingController _nomBoutiqueController = TextEditingController();
  final TextEditingController _motDePasseController = TextEditingController();
  final TextEditingController _confirmMotDePasseController =
      TextEditingController();
  final TextEditingController _codeSecretController = TextEditingController();

  bool _isLoading = false;
  bool _isTestMode = true;
  String? _selectedMode;
  void _showModeInfoDialog(BuildContext context,
      {required String title, required String content}) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title, style: TextStyle(color: Colors.blue.shade800)),
        content: Text(content),
        actions: [
          TextButton(
            child:
                Text('Compris', style: TextStyle(color: Colors.blue.shade800)),
            onPressed: () => Navigator.pop(ctx),
          ),
        ],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  Widget _buildModeCard({
    required double width,
    required String modeValue,
    required String title,
    required bool isSelected,
    required Color color,
    required String subtitle,
    required String infoTitle,
    required String infoContent,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: width,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isSelected ? Colors.green.shade300 : Colors.grey.shade200,
            width: 2,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Radio<String>(
                          value: modeValue,
                          groupValue: _selectedMode,
                          onChanged: (value) => onTap(),
                        ),
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: Icon(Icons.info_outline, size: 20),
                      color: Colors.red.shade300,
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints(),
                      onPressed: () => _showModeInfoDialog(
                        context,
                        title: infoTitle,
                        content: infoContent,
                      ),
                    ),
                  ],
                ),
                if (isSelected) ...[
                  SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.green.shade700,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

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
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            margin: EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Inscription',
                          style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade800)),
                      SizedBox(height: 24),
                      _buildTextFormField(
                          controller: _nomController,
                          label: 'Nom',
                          icon: Icons.person,
                          validator: (value) =>
                              value!.isEmpty ? 'Entrez votre nom' : null),
                      SizedBox(height: 16),
                      _buildTextFormField(
                          controller: _numeroController,
                          label: 'Numéro de téléphone',
                          icon: Icons.phone,
                          inputType: TextInputType.phone,
                          validator: (value) => value!.length != 8
                              ? 'Entrez un numéro valide à 8 chiffres'
                              : null),
                      SizedBox(height: 16),
                      _buildTextFormField(
                          controller: _nomBoutiqueController,
                          label: 'Nom de la boutique',
                          icon: Icons.store,
                          validator: (value) => value!.isEmpty
                              ? 'Entrez le nom de votre boutique'
                              : null),
                      SizedBox(height: 16),
                      _buildTextFormField(
                          controller: _motDePasseController,
                          label: 'Mot de passe',
                          icon: Icons.lock,
                          obscureText: true,
                          validator: (value) => value!.length < 6
                              ? 'Mot de passe trop court'
                              : null),
                      SizedBox(height: 16),
                      _buildTextFormField(
                          controller: _confirmMotDePasseController,
                          label: 'Confirmation mot de passe',
                          icon: Icons.lock,
                          obscureText: true,
                          validator: (value) =>
                              value != _motDePasseController.text
                                  ? 'Les mots de passe ne correspondent pas'
                                  : null),
                      SizedBox(height: 16),

                      // Choix du mode
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                            child: Text(
                              'Choisissez votre mode d\'utilisation :',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ),
                          SizedBox(height: 12),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              double cardWidth = (constraints.maxWidth - 16) /
                                  2; // deux cartes par ligne avec un petit espace
                              if (constraints.maxWidth < 360) {
                                cardWidth = constraints
                                    .maxWidth; // une seule carte par ligne si l'écran est trop petit
                              }

                              return Wrap(
                                spacing: 16,
                                runSpacing: 16,
                                children: [
                                  _buildModeCard(
                                    width: cardWidth,
                                    modeValue: 'test',
                                    title: '🔓 Mode Test',
                                    isSelected: _selectedMode == 'test',
                                    color: Colors.blue,
                                    subtitle: 'Essai avec limitation de vente',
                                    infoTitle: 'Mode Test',
                                    infoContent: '• Aucun code secret requis\n'
                                        '• Essai avec limitation de vente\n'
                                        '• Possibilité de continuer après en mode réel\n'
                                        '• Idéal pour découvrir l\'application',
                                    onTap: () {
                                      setState(() {
                                        _selectedMode = 'test';
                                        _isTestMode = true;
                                      });
                                    },
                                  ),
                                  _buildModeCard(
                                    width: cardWidth,
                                    modeValue: 'real',
                                    title: '✅ Mode Réel',
                                    isSelected: _selectedMode == 'real',
                                    color: Colors.green,
                                    subtitle: 'Vente en illimité',
                                    infoTitle: 'Mode Réel',
                                    infoContent:
                                        '• Utilisation avec code secret\n'
                                        '• Vente en illimité\n'
                                        '• Pour le code secret contactez ouedraogoalex038@gmail.com\n',
                                    onTap: () {
                                      setState(() {
                                        _selectedMode = 'real';
                                        _isTestMode = false;
                                      });
                                    },
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),

                      if (!_isTestMode) ...[
                        SizedBox(height: 16),
                        _buildTextFormField(
                            controller: _codeSecretController,
                            label: 'Code secret',
                            icon: Icons.vpn_key,
                            obscureText: true,
                            validator: (value) {
                              if (!_isTestMode && value != '@1111') {
                                return 'Code secret incorrect.';
                              }
                              return null;
                            }),
                      ],
                      SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _handleInscription,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade800,
                          padding: EdgeInsets.symmetric(
                              horizontal: 32, vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                        child: _isLoading
                            ? CircularProgressIndicator(
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white))
                            : Text('S\'inscrire',
                                style: TextStyle(
                                    fontSize: 16, color: Colors.white)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    TextInputType inputType = TextInputType.text,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: inputType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      validator: validator,
    );
  }

  Future<void> _handleInscription() async {
    if (_selectedMode == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Veuillez choisir un mode d\'utilisation')));
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final utilisateur = Utilisateur(
        idUtilisateur: Uuid().v4(),
        nom: _nomController.text.trim(),
        numero: _numeroController.text.trim(),
        nomBoutique: _nomBoutiqueController.text.trim(),
        motDePasse: _motDePasseController.text.trim(),
        codeSecret: _codeSecretController.text.trim(),
        isTestMode: _isTestMode,
        produitsCrees: 0,
        ventesEffectuees: 0,
      );

      await _controller.inscrireUtilisateur(utilisateur);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isTestMode', _isTestMode);
      await prefs.setInt('produitsCrees', 0);
      await prefs.setInt('ventesEffectuees', 0);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => ConnexionPage()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Une erreur est survenue : $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }
}
