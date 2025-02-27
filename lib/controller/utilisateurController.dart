import 'package:stockmanagementversion2/model/DatabaseHelper.dart';
import 'package:stockmanagementversion2/model/userModel.dart';

class UtilisateurController {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<void> inscrireUtilisateur(Utilisateur utilisateur) async {
    await _dbHelper.insertUtilisateur(utilisateur.toMap());
  }

  Future<Utilisateur?> connecterUtilisateur(String numero, String motDePasse) async {
    final utilisateurs = await _dbHelper.getUtilisateurs();
    for (var user in utilisateurs) {
      if (user['numero'] == numero && user['motDePasse'] == motDePasse) {
        return Utilisateur.fromMap(user);
      }
    }
    return null;
  }
}