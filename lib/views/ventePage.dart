import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stockmanagementversion2/controller/produitController.dart';
import 'package:stockmanagementversion2/controller/venteController.dart';
import 'package:stockmanagementversion2/model/produitModel.dart';
import 'package:stockmanagementversion2/model/produitvenduModel.dart';
import 'package:stockmanagementversion2/model/recuModel.dart';
import 'package:stockmanagementversion2/model/venteModel.dart';
import 'package:stockmanagementversion2/service/test_mode_service.dart';
import 'package:uuid/uuid.dart';
import 'package:stockmanagementversion2/views/recuPage.dart'; // Importez la nouvelle page

class VentesPage extends StatefulWidget {
  @override
  _VentesPageState createState() => _VentesPageState();
}

class _VentesPageState extends State<VentesPage> {
  final VenteController _venteController = VenteController();
  final ProduitController _produitController = ProduitController();
  List<Produit> _produitsDisponibles = [];
  List<Produit> _produitsFiltres = []; // Liste des produits filtrés
  List<Map<Produit, int>> _produitsSelectionnes = []; // Produit + Quantité
  double _montantTotal = 0.0;
  TextEditingController _searchController = TextEditingController(); // Contrôleur pour la recherche
  bool _isLoading = true; // État pour gérer le chargement des données
  String? _errorMessage; // Variable pour stocker l'erreur

  @override
  void initState() {
    super.initState();
    _chargerProduitsDisponibles();
    _searchController.addListener(_filtrerProduits); // Écouter les changements dans la recherche
  }

  Future<void> _chargerProduitsDisponibles() async {
    setState(() {
      _isLoading = true; // Activer l'état de chargement
      _errorMessage = null; // Réinitialiser le message d'erreur
    });

    try {
      final produits = await _produitController.obtenirProduits();
      setState(() {
        _produitsDisponibles = produits;
        _produitsFiltres = produits; // Initialiser la liste filtrée
        _isLoading = false; // Désactiver l'état de chargement
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur lors du chargement des produits : $e';
        _isLoading = false;
      });
    }
  }

  void _filtrerProduits() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _produitsFiltres = _produitsDisponibles; // Afficher tous les produits si la recherche est vide
      } else {
        _produitsFiltres = _produitsDisponibles
            .where((produit) => produit.nom.toLowerCase().contains(query)) // Filtrer par nom de produit
            .toList();
      }
    });
  }

  void _ajouterProduit(Produit produit) {
    final produitSelectionne = _produitsSelectionnes.firstWhere(
      (item) => item.keys.first == produit,
      orElse: () => {},
    );

    if (produitSelectionne.isNotEmpty) {
      final quantiteActuelle = produitSelectionne.values.first;
      if (quantiteActuelle < produit.quantite) {
        setState(() {
          produitSelectionne[produit] = quantiteActuelle + 1;
          _montantTotal += produit.prix;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Stock insuffisant pour ${produit.nom}')),
        );
      }
    } else {
      setState(() {
        _produitsSelectionnes.add({produit: 1});
        _montantTotal += produit.prix;
      });
    }
  }

  void _retirerProduit(Produit produit) {
    final produitSelectionne = _produitsSelectionnes.firstWhere(
      (item) => item.keys.first == produit,
      orElse: () => {},
    );

    if (produitSelectionne.isNotEmpty) {
      final quantiteActuelle = produitSelectionne.values.first;
      if (quantiteActuelle > 1) {
        setState(() {
          produitSelectionne[produit] = quantiteActuelle - 1;
          _montantTotal -= produit.prix;
        });
      } else {
        setState(() {
          _produitsSelectionnes.remove(produitSelectionne);
          _montantTotal -= produit.prix;
        });
      }
    }
  }

  Future<void> _validerVente() async {
    // Vérifier les limites du mode test
  final isLimitReached = await TestModeService.checkLimits(context);
  if (isLimitReached) {
    return;
  }
    if (_produitsSelectionnes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Veuillez sélectionner au moins un produit')),
      );
      return;
    }

    // Vérifier que les quantités ne dépassent pas le stock disponible
    for (final item in _produitsSelectionnes) {
      final produit = item.keys.first;
      final quantiteVendue = item.values.first;

      if (quantiteVendue > produit.quantite) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'La quantité de ${produit.nom} dépasse le stock disponible')),
        );
        return;
      }
    }

    // Récupérer l'ID utilisateur connecté
    final prefs = await SharedPreferences.getInstance();
    final idUtilisateur = prefs.getString('idUtilisateur');

    if (idUtilisateur == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Utilisateur non connecté')),
      );
      return;
    }

    // Enregistrer la vente
    final String idVente = Uuid().v4(); // Génère un UUID unique

    // Créer une liste de ProduitVendu
    final List<ProduitVendu> produitsVendus = _produitsSelectionnes.map((item) {
      final produit = item.keys.first;
      final quantiteVendue = item.values.first;
      return ProduitVendu(
        idProduit: produit.idProduit,
        nom: produit.nom,
        prix: produit.prix,
        quantiteVendue: quantiteVendue,
      );
    }).toList();

    

    final vente = Vente(
      idVente: idVente, // Utilisation de l'UUID
      date: DateTime.now(),
      produitsVendus: produitsVendus, // Ajoutez cette ligne
      montantTotal: _montantTotal,
      idUtilisateur: idUtilisateur, // Utiliser l'ID utilisateur réel
    );
    // Ajouter ceci juste avant await _venteController.enregistrerVente(vente);
await TestModeService.incrementVentesEffectuees();

    await _venteController.enregistrerVente(vente);

    // Mettre à jour les stocks des produits vendus
    for (final item in _produitsSelectionnes) {
      final produit = item.keys.first;
      final quantiteVendue = item.values.first;

      produit.quantite -= quantiteVendue;
      await _produitController.modifierProduit(produit);
    }

    // Générer un reçu
    final recu = await _genererRecu(vente); // Utilisez await ici

    // Afficher le reçu
    _afficherRecu(recu);

    // Recharger la liste des produits disponibles
    _chargerProduitsDisponibles();

    // Réinitialiser la sélection
    setState(() {
      _produitsSelectionnes.clear();
      _montantTotal = 0.0;
    });
  }

  Future<Recu> _genererRecu(Vente vente) async {
    final prefs = await SharedPreferences.getInstance();
    final nomBoutique = prefs.getString('nomBoutique') ?? 'Boutique inconnue'; // Récupérer le nom de la boutique

    final contenu = '''
Reçu de vente
Boutique: $nomBoutique
ID de la vente: ${vente.idVente}
Date: ${vente.date.toLocal()}
Produits vendus:
${_produitsSelectionnes.map((item) {
        final produit = item.keys.first;
        final quantite = item.values.first;
        return '${produit.nom} - $quantite x ${produit.prix} FCFA = ${quantite * produit.prix} FCFA';
      }).join('\n')}
Montant total: ${vente.montantTotal} FCFA
  ''';

    return Recu(
      idVente: vente.idVente,
      contenu: contenu,
      nomBoutique: nomBoutique, // Ajoutez cette ligne
    );
  }

  void _afficherRecu(Recu recu) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => RecuPage(recu: recu),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Ventes',
        style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blueAccent,
        
        elevation: 8,
        iconTheme: IconThemeData(color: Colors.white), // Changer la couleur de l'icône de retour
      ),
      body: Column(
        children: [
          // Barre de recherche
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Rechercher un produit',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          Expanded(
            child: _isLoading // Vérifier si les données sont en cours de chargement
                ? Center(
                    child: CircularProgressIndicator(), // Afficher un indicateur de chargement
                  )
                : _errorMessage != null // Vérifier s'il y a une erreur
                    ? Center(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: Colors.red, fontSize: 16),
                        ),
                      )
                    : _produitsFiltres.isEmpty // Vérifier s'il n'y a aucun produit
                        ? Center(
                            child: Text(
                              'Aucun produit disponible.',
                              style: TextStyle(color: Colors.grey, fontSize: 16),
                            ),
                          )
                        : ListView.builder(
                            itemCount: _produitsFiltres.length,
                            itemBuilder: (context, index) {
                              final produit = _produitsFiltres[index];
                              final produitSelectionne = _produitsSelectionnes.firstWhere(
                                (item) => item.keys.first == produit,
                                orElse: () => {},
                              );
                              final quantiteSelectionnee = produitSelectionne.isNotEmpty
                                  ? produitSelectionne.values.first
                                  : 0;
                              final isStockFaible = produit.quantite <= produit.stockMinimum;

                              return Card(
                                elevation: 4,
                                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: ListTile(
                                  title: Text(produit.nom),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                          'Prix: ${produit.prix} FCFA | Stock: ${produit.quantite}'),
                                      if (isStockFaible)
                                        Text(
                                          'Stock faible !',
                                          style: TextStyle(
                                              color: Colors.red, fontWeight: FontWeight.bold),
                                        ),
                                    ],
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: Icon(Icons.remove, color: Colors.red),
                                        onPressed: () {
                                          _retirerProduit(produit);
                                        },
                                      ),
                                      Text('$quantiteSelectionnee'),
                                      IconButton(
                                        icon: Icon(Icons.add, color: Colors.green),
                                        onPressed: () {
                                          _ajouterProduit(produit);
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Text(
                  'Montant total: $_montantTotal FCFA',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _validerVente,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade800,
                    padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Valider la Vente',
                    style: TextStyle(fontSize: 16,color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}