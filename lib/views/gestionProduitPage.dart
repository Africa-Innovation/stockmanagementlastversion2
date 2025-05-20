import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stockmanagementversion2/controller/produitController.dart';
import 'package:stockmanagementversion2/model/produitModel.dart';
import 'package:stockmanagementversion2/service/test_mode_service.dart';
import 'package:uuid/uuid.dart';

class GestionProduitsPage extends StatefulWidget {
  @override
  _GestionProduitsPageState createState() => _GestionProduitsPageState();
}

class _GestionProduitsPageState extends State<GestionProduitsPage> {
  final ProduitController _controller = ProduitController();
  List<Produit> _produits = [];
  List<Produit> _produitsFiltres = []; // Liste des produits filtrés
  TextEditingController _searchController =
      TextEditingController(); // Contrôleur pour la recherche
  bool _afficherStockFaible =
      false; // État pour gérer le filtre de stock faible
  bool _isLoading = true; // État pour gérer le chargement des données
  String? _errorMessage; // Variable pour stocker l'erreur

  @override
  void initState() {
    super.initState();
    _chargerProduits();
    _searchController.addListener(
        _filtrerProduits); // Écouter les changements dans la recherche
  }

  Future<void> _chargerProduits() async {
    setState(() {
      _isLoading = true; // Activer l'état de chargement
      _errorMessage = null; // Réinitialiser le message d'erreur
    });

    try {
      final produits = await _controller.obtenirProduits();
      setState(() {
        _produits = produits;
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

  Future<void> _afficherFormulaireAjoutProduit(BuildContext context, {Produit? produitExist}) async {
  final prefs = await SharedPreferences.getInstance();
  final idUtilisateur = prefs.getString('idUtilisateur');

  final isLimitReached = await TestModeService.checkLimits(context);
  if (isLimitReached || idUtilisateur == null) return;

  final TextEditingController _nomController = TextEditingController(text: produitExist?.nom);
  final TextEditingController _referenceController = TextEditingController(text: produitExist?.reference);
  final TextEditingController _prixController = TextEditingController(text: produitExist?.prix?.toString());
  final TextEditingController _quantiteController = TextEditingController(text: produitExist?.quantite?.toString());
  final TextEditingController _stockMinimumController = TextEditingController(text: produitExist?.stockMinimum?.toString());
  final TextEditingController _categorieController = TextEditingController(text: produitExist?.categorie);

  bool _nomValide = true;
  bool _prixValide = true;
  bool _quantiteValide = true;
  bool _stockMinimumValide = true;

  await showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(produitExist == null ? 'Ajouter un produit' : 'Modifier le produit'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Nom
                  TextField(
                    controller: _nomController,
                    decoration: InputDecoration(
                      label: RichText(
                        text: TextSpan(
                          text: 'Nom',
                          style: TextStyle(color: Colors.black),
                          children: [
                            TextSpan(
                              text: '*',
                              style: TextStyle(color: _nomValide ? Colors.grey : Colors.red,
                              fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                    onChanged: (value) => setState(() => _nomValide = value.trim().isNotEmpty),
                  ),
                  // Référence
                  TextField(
                    controller: _referenceController,
                    decoration: InputDecoration(labelText: 'Référence'),
                  ),
                  // Prix
                  TextField(
                    controller: _prixController,
                    decoration: InputDecoration(
                      label: RichText(
                        text: TextSpan(
                          text: 'Prix',
                          style: TextStyle(color: Colors.black),
                          children: [
                            TextSpan(
                              text: '*',
                              style: TextStyle(color: _prixValide ? Colors.grey : Colors.red,
                              fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) => setState(() => _prixValide = value.trim().isNotEmpty),
                  ),
                  // Quantité
                  TextField(
                    controller: _quantiteController,
                    decoration: InputDecoration(
                      label: RichText(
                        text: TextSpan(
                          text: 'Stock initial',
                          style: TextStyle(color: Colors.black),
                          children: [
                            TextSpan(
                              text: '*',
                              style: TextStyle(color: _quantiteValide ? Colors.grey : Colors.red,
                              fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) => setState(() => _quantiteValide = value.trim().isNotEmpty),
                  ),
                  // Stock minimum
                  TextField(
                    controller: _stockMinimumController,
                    decoration: InputDecoration(
                      label: RichText(
                        text: TextSpan(
                          text: 'Stock minimum',
                          style: TextStyle(color: Colors.black),
                          children: [
                            TextSpan(
                              text: '*',
                              style: TextStyle(color: _stockMinimumValide ? Colors.grey : Colors.red,
                              fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) => setState(() => _stockMinimumValide = value.trim().isNotEmpty),
                  ),
                  // Catégorie
                  TextField(
                    controller: _categorieController,
                    decoration: InputDecoration(labelText: 'Catégorie'),
                  ),
                  SizedBox(height: 16),
                  const Text('* Champs obligatoires', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('Annuler'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final isLimitReached = await TestModeService.checkLimits(context);
                  if (isLimitReached) return;

                  setState(() {
                    _nomValide = _nomController.text.trim().isNotEmpty;
                    _prixValide = _prixController.text.trim().isNotEmpty;
                    _quantiteValide = _quantiteController.text.trim().isNotEmpty;
                    _stockMinimumValide = _stockMinimumController.text.trim().isNotEmpty;
                  });

                  if (!_nomValide || !_prixValide || !_quantiteValide || !_stockMinimumValide) return;

                  try {
                    int quantite = int.parse(_quantiteController.text);
                    int stockMinimum = int.parse(_stockMinimumController.text);

                    if (stockMinimum > quantite) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Le stock minimum ne peut pas être supérieur à la quantité')),
                      );
                      return;
                    }

                    final produit = Produit(
                      idProduit: produitExist?.idProduit ?? Uuid().v4(),
                      nom: _nomController.text,
                      reference: _referenceController.text,
                      prix: double.parse(_prixController.text),
                      quantite: quantite,
                      stockMinimum: stockMinimum,
                      dateAjout: produitExist?.dateAjout ?? DateTime.now(),
                      categorie: _categorieController.text,
                      idUtilisateur: idUtilisateur,
                    );

                    if (produitExist == null) {
                      await _controller.ajouterProduit(produit);
                    } else {
                      await _controller.modifierProduit(produit);
                    }

                    _chargerProduits();
                    Navigator.of(context).pop();
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Erreur: ${e.toString()}')),
                    );
                  }
                },
                child: Text(produitExist == null ? 'Ajouter' : 'Modifier'),
              ),
            ],
          );
        },
      );
    },
  );
}


  Future<void> _afficherDetailsProduit(
      BuildContext context, Produit produit) async {
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Détails du produit'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Nom: ${produit.nom}'),
                Text('Référence: ${produit.reference ?? 'Non renseigne'}'),
                Text('Prix: ${produit.prix} FCFA'),
                Text('Quantité: ${produit.quantite}'),
                Text('Stock minimum: ${produit.stockMinimum}'),
                Text('Catégorie: ${produit.categorie ?? 'Non renseignée'}'),
                Text('Date d\'ajout: ${produit.dateAjout.toLocal()}'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Fermer le dialog
              },
              child: Text('Fermer'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _afficherConfirmationSuppression(
      BuildContext context, String idProduit) async {
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Confirmer la suppression'),
          content: Text('Êtes-vous sûr de vouloir supprimer ce produit ?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Fermer le dialog sans supprimer
              },
              child: Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () async {
                await _controller.supprimerProduit(idProduit);
                _chargerProduits(); // Recharger la liste des produits
                Navigator.of(context).pop(); // Fermer le dialog
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors
                    .red, // Couleur rouge pour indiquer une action critique
              ),
              child: const Text(
                'Supprimer',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  void _filtrerProduits() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _produitsFiltres =
            _produits; // Afficher tous les produits si la recherche est vide
      } else {
        _produitsFiltres = _produits
            .where((produit) => produit.nom
                .toLowerCase()
                .contains(query)) // Filtrer par nom de produit
            .toList();
      }

      // Appliquer le filtre de stock faible si activé
      if (_afficherStockFaible) {
        _produitsFiltres = _produitsFiltres
            .where((produit) => produit.quantite <= produit.stockMinimum)
            .toList();
      }
    });
  }

  void _basculerFiltreStockFaible() {
    setState(() {
      _afficherStockFaible =
          !_afficherStockFaible; // Activer/désactiver le filtre
      _filtrerProduits(); // Appliquer le filtre
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            Text('Gestion des Produits', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blueAccent,
        elevation: 8,
        iconTheme: IconThemeData(
            color: Colors.white), // Changer la couleur de l'icône de retour
        actions: [
          IconButton(
            icon: Icon(
              _afficherStockFaible ? Icons.filter_alt : Icons.filter_alt_off,
              color: _afficherStockFaible ? Colors.red : Colors.white,
            ),
            onPressed:
                _basculerFiltreStockFaible, // Basculer le filtre de stock faible
          ),
        ],
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
            child:
                _isLoading // Vérifier si les données sont en cours de chargement
                    ? Center(
                        child:
                            CircularProgressIndicator(), // Afficher un indicateur de chargement
                      )
                    : _errorMessage != null // Vérifier s'il y a une erreur
                        ? Center(
                            child: Text(
                              _errorMessage!,
                              style: TextStyle(color: Colors.red, fontSize: 16),
                            ),
                          )
                        : _produitsFiltres
                                .isEmpty // Vérifier s'il n'y a aucun produit
                            ? const Center(
                                child: Text(
                                  'Aucun stock faible disponible.',
                                  style: TextStyle(
                                      color: Colors.grey, fontSize: 16),
                                ),
                              )
                            : ListView.builder(
                                itemCount: _produitsFiltres.length,
                                itemBuilder: (context, index) {
                                  final produit = _produitsFiltres[index];
                                  final isStockFaible =
                                      produit.quantite <= produit.stockMinimum;

                                  return Card(
                                    elevation: 4,
                                    margin: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 8),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: ListTile(
                                      title: Text(produit.nom),
                                      subtitle: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text('Stock: ${produit.quantite}'),
                                          if (isStockFaible)
                                            const Text(
                                              'Stock faible !',
                                              style: TextStyle(
                                                  color: Colors.red,
                                                  fontWeight: FontWeight.bold),
                                            ),
                                        ],
                                      ),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: Icon(Icons.visibility,
                                                color: Colors.blue),
                                            onPressed: () {
                                              _afficherDetailsProduit(
                                                  context, produit);
                                            },
                                          ),
                                          IconButton(
                                            icon: Icon(Icons.edit,
                                                color: Colors.orange),
                                            onPressed: () {
                                              _afficherFormulaireAjoutProduit(
                                                  context,
                                                  produitExist: produit);
                                            },
                                          ),
                                          IconButton(
                                            icon: Icon(Icons.delete,
                                                color: Colors.red),
                                            onPressed: () async {
                                              await _afficherConfirmationSuppression(
                                                  context, produit.idProduit!);
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _afficherFormulaireAjoutProduit(
              context); // Afficher le formulaire d'ajout
        },
        backgroundColor: Colors.blue.shade800,
        child: Icon(
          Icons.add,
          color: Colors.white,
        ),
      ),
    );
  }
}
