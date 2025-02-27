import 'dart:convert';

import 'package:stockmanagementversion2/model/produitvenduModel.dart';

import 'produitModel.dart'; // Ajoute cette importation

class Vente {
  String idVente;
  DateTime date;
  List<ProduitVendu> produitsVendus;
  double montantTotal;
  String idUtilisateur;

  Vente({
    required this.idVente,
    required this.date,
    required this.produitsVendus,
    required this.montantTotal,
    required this.idUtilisateur,
  });

  Map<String, dynamic> toMap() {
    return {
      'idVente': idVente,
      'date': date.toIso8601String(),
      'produitsVendus': produitsVendus.map((p) => p.toMap()).toList(),
      'montantTotal': montantTotal,
      'idUtilisateur': idUtilisateur,
    };
  }

  factory Vente.fromMap(Map<String, dynamic> map) {
    return Vente(
      idVente: map['idVente'] ?? '', // Gérer les valeurs null
      date: DateTime.parse(map['date'] ?? DateTime.now().toIso8601String()), // Gérer les valeurs null
      produitsVendus: List<ProduitVendu>.from(
        (map['produitsVendus'] ?? []).map((p) => ProduitVendu.fromMap(p)),
      ),
      montantTotal: map['montantTotal'] ?? 0.0, // Gérer les valeurs null
      idUtilisateur: map['idUtilisateur'] ?? '', // Gérer les valeurs null
    );
  }
}