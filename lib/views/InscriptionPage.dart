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
  final TextEditingController _confirmMotDePasseController = TextEditingController();
  final TextEditingController _codeSecretController = TextEditingController();

  bool _isLoading = false;
  bool _isTestMode = true;
  String? _selectedMode;

  void _showModeInfoDialog(BuildContext context, {required String title, required String content}) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title, style: TextStyle(
          color: Colors.blue.shade800,
          fontWeight: FontWeight.w600,
        )),
        content: Text(content, style: const TextStyle(fontSize: 14)),
        actions: [
          TextButton(
            child: Text('Compris', style: TextStyle(color: Colors.blue.shade800)),
            onPressed: () => Navigator.pop(ctx),
          ),
        ],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 4,
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
        elevation: isSelected ? 4 : 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isSelected ? color.withOpacity(0.5) : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
        ),
        color: isSelected ? color.withOpacity(0.05) : Colors.white,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected ? color : Colors.grey.shade400,
                                width: 2,
                              ),
                            ),
                            child: isSelected
                                ? Center(
                                    child: Container(
                                      width: 12,
                                      height: 12,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: color,
                                      ),
                                    ),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              title,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.info_outline_rounded, size: 20),
                      color: Colors.grey.shade600,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => _showModeInfoDialog(
                        context,
                        title: infoTitle,
                        content: infoContent,
                      ),
                    ),
                  ],
                ),
                if (isSelected) ...[
                  const SizedBox(height: 8),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: color,
                      fontWeight: FontWeight.w500,
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
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Container(
         decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue.shade900,
              Colors.blue.shade700,
              Colors.blue.shade500,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Column(
                      children: [
                        Icon(Icons.account_circle_rounded, 
                            size: 60, 
                            color: Colors.white.withOpacity(0.9)),
                        const SizedBox(height: 16),
                        const Text(
                          'Créer un compte',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Gérez votre boutique en toute simplicité',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Form Card
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              _buildTextFormField(
                                controller: _nomController,
                                label: 'Votre nom complet',
                                icon: Icons.person_outline_rounded,
                                validator: (value) =>
                                    value!.isEmpty ? 'Entrez votre nom' : null,
                              ),
                              const SizedBox(height: 16),
                              _buildTextFormField(
                                controller: _numeroController,
                                label: 'Numéro de téléphone',
                                icon: Icons.phone_android_rounded,
                                inputType: TextInputType.phone,
                                validator: (value) => value!.length != 8
                                    ? 'Numéro invalide (8 chiffres requis)'
                                    : null,
                              ),
                              const SizedBox(height: 16),
                              _buildTextFormField(
                                controller: _nomBoutiqueController,
                                label: 'Nom de votre boutique',
                                icon: Icons.store_mall_directory_rounded,
                                validator: (value) => value!.isEmpty
                                    ? 'Entrez un nom de boutique'
                                    : null,
                              ),
                              const SizedBox(height: 16),
                              _buildTextFormField(
                                controller: _motDePasseController,
                                label: 'Créez un mot de passe',
                                icon: Icons.lock_outline_rounded,
                                obscureText: true,
                                validator: (value) => value!.length < 6
                                    ? 'Minimum 6 caractères'
                                    : null,
                              ),
                              const SizedBox(height: 16),
                              _buildTextFormField(
                                controller: _confirmMotDePasseController,
                                label: 'Confirmez le mot de passe',
                                icon: Icons.lock_reset_rounded,
                                obscureText: true,
                                validator: (value) =>
                                    value != _motDePasseController.text
                                        ? 'Les mots de passe ne correspondent pas'
                                        : null,
                              ),
                              const SizedBox(height: 24),

                              // Mode Selection
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Mode d\'utilisation',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey.shade800,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  LayoutBuilder(
                                    builder: (context, constraints) {
                                      double cardWidth = constraints.maxWidth;
                                      if (constraints.maxWidth > 500) {
                                        cardWidth = (constraints.maxWidth - 16) / 2;
                                      }

                                      return Wrap(
                                        spacing: 16,
                                        runSpacing: 16,
                                        children: [
                                          _buildModeCard(
                                            width: cardWidth,
                                            modeValue: 'test',
                                            title: 'Mode Test',
                                            isSelected: _selectedMode == 'test',
                                            color: Colors.blue,
                                            subtitle: 'Essai avec limitations',
                                            infoTitle: 'Mode Test',
                                            infoContent: '• Aucun code secret requis\n'
                                                '• Essai avec limitation de vente\n'
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
                                            title: 'Mode Réel',
                                            isSelected: _selectedMode == 'real',
                                            color: Colors.green,
                                            subtitle: 'Vente en illimité',
                                            infoTitle: 'Mode Réel',
                                            infoContent: '• Code secret requis\n'
                                                '• Vente en illimité\n'
                                                '• Contactez-nous pour le code',
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
                                const SizedBox(height: 16),
                                _buildTextFormField(
                                  controller: _codeSecretController,
                                  label: 'Code secret',
                                  icon: Icons.key_rounded,
                                  obscureText: true,
                                  validator: (value) {
                                    if (!_isTestMode && value != '@1111') {
                                      return 'Code secret incorrect';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                              const SizedBox(height: 32),

                              // Submit Button
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _handleInscription,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue.shade800,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: _isLoading
                                      ? const SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 3,
                                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                          ),
                                        )
                                      : const Text(
                                          'Créer mon compte',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Login Link
                    TextButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => ConnexionPage()),
                        );
                      },
                      child: RichText(
                        text: TextSpan(
                          text: 'Déjà un compte ? ',
                          style: TextStyle(color: Colors.white.withOpacity(0.8)),
                          children: [
                            const TextSpan(
                              text: 'Connectez-vous',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
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
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey.shade600),
        prefixIcon: Icon(icon, size: 20, color: Colors.grey.shade600),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.blue.shade800, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      ),
      validator: validator,
    );
  }

  Future<void> _handleInscription() async {
    if (_selectedMode == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Veuillez choisir un mode d\'utilisation'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final utilisateur = Utilisateur(
        idUtilisateur: const Uuid().v4(),
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
        SnackBar(
          content: Text('Erreur : $e'),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }
}