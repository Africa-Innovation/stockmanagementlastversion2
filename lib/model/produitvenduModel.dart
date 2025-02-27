class ProduitVendu {
  String idProduit;
  String nom;
  double prix;
  int quantiteVendue;

  ProduitVendu({
    required this.idProduit,
    required this.nom,
    required this.prix,
    required this.quantiteVendue,
  });

  Map<String, dynamic> toMap() {
    return {
      'idProduit': idProduit,
      'nom': nom,
      'prix': prix,
      'quantiteVendue': quantiteVendue,
    };
  }

  factory ProduitVendu.fromMap(Map<String, dynamic> map) {
    return ProduitVendu(
      idProduit: map['idProduit'] ?? '', // Gérer les valeurs null
      nom: map['nom'] ?? '', // Gérer les valeurs null
      prix: map['prix'] ?? 0.0, // Gérer les valeurs null
      quantiteVendue: map['quantiteVendue'] ?? 0, // Gérer les valeurs null
    );
  }
}