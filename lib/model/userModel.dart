class Utilisateur {
  String? idUtilisateur;
  String nom;
  String numero;
  String nomBoutique;
  String motDePasse;
  String codeSecret;

  Utilisateur({
    this.idUtilisateur,
    required this.nom,
    required this.numero,
    required this.nomBoutique,
    required this.motDePasse,
    required this.codeSecret,
  });

  // Convertir un Utilisateur en Map pour SQFlite/Firebase
  Map<String, dynamic> toMap() {
    return {
      'idUtilisateur': idUtilisateur,
      'nom': nom,
      'numero': numero,
      'nomBoutique': nomBoutique,
      'motDePasse': motDePasse,
      'codeSecret': codeSecret,
    };
  }

  // Convertir une Map en Utilisateur
  factory Utilisateur.fromMap(Map<String, dynamic> map) {
    return Utilisateur(
      idUtilisateur: map['idUtilisateur'],
      nom: map['nom'],
      numero: map['numero'],
      nomBoutique: map['nomBoutique'],
      motDePasse: map['motDePasse'],
      codeSecret: map['codeSecret'],
    );
  }
}