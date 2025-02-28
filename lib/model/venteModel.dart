import 'dart:convert';

import 'package:stockmanagementversion2/model/produitvenduModel.dart';
import 'package:stockmanagementversion2/model/produitModel.dart'; // Ajoute cette importation

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
      'date': date is DateTime ? date.toIso8601String() : date.toString(), // Convertir DateTime en String si nécessaire
      'produitsVendus': produitsVendus.map((p) => p.toMap()).toList(),
      'montantTotal': montantTotal,
      'idUtilisateur': idUtilisateur,
    };
  }

  factory Vente.fromMap(Map<String, dynamic> map) {
    // Gérer la date
    final dynamic dateValue = map['date'];
    final DateTime date;
    if (dateValue is DateTime) {
      date = dateValue; // Utiliser directement si c'est déjà un DateTime
    } else if (dateValue is String) {
      date = DateTime.parse(dateValue); // Convertir String en DateTime
    } else {
      date = DateTime.now(); // Valeur par défaut si la date est null ou invalide
    }

    return Vente(
      idVente: map['idVente'] ?? '', // Gérer les valeurs null
      date: date,
      produitsVendus: List<ProduitVendu>.from(
        (map['produitsVendus'] ?? []).map((p) => ProduitVendu.fromMap(p)),
      ),
      montantTotal: map['montantTotal'] ?? 0.0, // Gérer les valeurs null
      idUtilisateur: map['idUtilisateur'] ?? '', // Gérer les valeurs null
    );
  }
}