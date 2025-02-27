// import 'package:stockmanagementversion2/model/venteModel.dart';

// class HistoriqueVentes {
//   String? idHistorique;
//   String idUtilisateur;
//   List<Vente> ventes;

//   HistoriqueVentes({
//     this.idHistorique,
//     required this.idUtilisateur,
//     required this.ventes,
//   });

//   // Convertir HistoriqueVentes en Map pour SQFlite/Firebase
//   Map<String, dynamic> toMap() {
//     return {
//       'idHistorique': idHistorique,
//       'idUtilisateur': idUtilisateur,
//       'ventes': ventes.map((vente) => vente.toMap()).toList(),
//     };
//   }

//   // Convertir une Map en HistoriqueVentes
//   factory HistoriqueVentes.fromMap(Map<String, dynamic> map) {
//     return HistoriqueVentes(
//       idHistorique: map['idHistorique'],
//       idUtilisateur: map['idUtilisateur'],
//       ventes: List<Vente>.from(map['ventes'].map((v) => Vente.fromMap(v))),
//     );
//   }
// }