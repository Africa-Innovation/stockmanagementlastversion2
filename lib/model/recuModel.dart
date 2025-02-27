class Recu {
  String? idRecu;
  String idVente;
  String contenu;
  String nomBoutique; // Ajoutez cette propriété

  Recu({
    this.idRecu,
    required this.idVente,
    required this.contenu,
    required this.nomBoutique, // Ajoutez cette propriété
  });

  Map<String, dynamic> toMap() {
    return {
      'idRecu': idRecu,
      'idVente': idVente,
      'contenu': contenu,
      'nomBoutique': nomBoutique, // Ajoutez cette propriété
    };
  }

  factory Recu.fromMap(Map<String, dynamic> map) {
    return Recu(
      idRecu: map['idRecu'],
      idVente: map['idVente'],
      contenu: map['contenu'],
      nomBoutique: map['nomBoutique'] ?? 'Boutique inconnue', // Ajoutez cette propriété
    );
  }
}