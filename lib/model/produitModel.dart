class Produit {
  String idProduit;
  String nom;
  String reference;
  double prix;
  int quantite;
  int stockMinimum;
  DateTime dateAjout;
  String categorie;
  String idUtilisateur;

  Produit({
    required this.idProduit,
    required this.nom,
    required this.reference,
    required this.prix,
    required this.quantite,
    required this.stockMinimum,
    required this.dateAjout,
    required this.categorie,
    required this.idUtilisateur,
  });

  Map<String, dynamic> toMap() {
    return {
      'idProduit': idProduit,
      'nom': nom,
      'reference': reference,
      'prix': prix,
      'quantite': quantite,
      'stockMinimum': stockMinimum,
      'dateAjout': dateAjout.toIso8601String(),
      'categorie': categorie,
      'idUtilisateur': idUtilisateur,
    };
  }

  factory Produit.fromMap(Map<String, dynamic> map) {
    return Produit(
      idProduit: map['idProduit'],
      nom: map['nom'],
      reference: map['reference'],
      prix: map['prix'],
      quantite: map['quantite'],
      stockMinimum: map['stockMinimum'],
      dateAjout: DateTime.parse(map['dateAjout']),
      categorie: map['categorie'],
      idUtilisateur: map['idUtilisateur'],
    );
  }
}