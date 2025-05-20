class Utilisateur {
  String? idUtilisateur;
  String nom;
  String numero;
  String nomBoutique;
  String motDePasse;
  String codeSecret;
  bool isTestMode;
  int produitsCrees;
  int ventesEffectuees;

  Utilisateur({
    this.idUtilisateur,
    required this.nom,
    required this.numero,
    required this.nomBoutique,
    required this.motDePasse,
    required this.codeSecret,
    required this.isTestMode,
    required this.produitsCrees,
    required this.ventesEffectuees,
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
    'isTestMode': isTestMode ? 1 : 0,
    'produitsCrees': produitsCrees,
    'ventesEffectuees': ventesEffectuees,
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
    codeSecret: map['codeSecret'] ?? '', // Valeur par défaut si null
    isTestMode: map['isTestMode'] == 1, // Par défaut en mode test
    produitsCrees: map['produitsCrees'] ?? 0, // Par défaut 0
    ventesEffectuees: map['ventesEffectuees'] ?? 0, // Par défaut 0
  );
}
}