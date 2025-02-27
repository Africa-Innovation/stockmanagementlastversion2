import 'package:flutter/material.dart';
import 'package:stockmanagementversion2/controller/produitController.dart';
import 'package:stockmanagementversion2/model/produitModel.dart';

class GestionProduitsPage extends StatefulWidget {
  @override
  _GestionProduitsPageState createState() => _GestionProduitsPageState();
}

class _GestionProduitsPageState extends State<GestionProduitsPage> {
  final ProduitController _controller = ProduitController();
  List<Produit> _produits = [];
  List<Produit> _produitsFiltres = []; // Liste des produits filtrés
  TextEditingController _searchController = TextEditingController(); // Contrôleur pour la recherche

  @override
  void initState() {
    super.initState();
    _chargerProduits();
    _searchController.addListener(_filtrerProduits); // Écouter les changements dans la recherche
  }

  Future<void> _chargerProduits() async {
    final produits = await _controller.obtenirProduits('idUtilisateur');
    setState(() {
      _produits = produits;
      _produitsFiltres = produits; // Initialiser la liste filtrée
    });
  }

  void _filtrerProduits() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _produitsFiltres = _produits; // Afficher tous les produits si la recherche est vide
      } else {
        _produitsFiltres = _produits
            .where((produit) =>
                produit.nom.toLowerCase().contains(query)) // Filtrer par nom de produit
            .toList();
      }
    });
  }

  Future<void> _afficherFormulaireAjoutProduit(BuildContext context,
      {Produit? produitExist}) async {
    final TextEditingController _nomController =
        TextEditingController(text: produitExist?.nom);
    final TextEditingController _referenceController =
        TextEditingController(text: produitExist?.reference);
    final TextEditingController _prixController =
        TextEditingController(text: produitExist?.prix.toString());
    final TextEditingController _quantiteController =
        TextEditingController(text: produitExist?.quantite.toString());
    final TextEditingController _stockMinimumController =
        TextEditingController(text: produitExist?.stockMinimum.toString());
    final TextEditingController _categorieController =
        TextEditingController(text: produitExist?.categorie);

    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(produitExist == null
              ? 'Ajouter un produit'
              : 'Modifier le produit'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _nomController,
                  decoration: InputDecoration(labelText: 'Nom*'),
                ),
                TextField(
                  controller: _referenceController,
                  decoration: InputDecoration(labelText: 'Référence'),
                ),
                TextField(
                  controller: _prixController,
                  decoration: InputDecoration(labelText: 'Prix*'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: _quantiteController,
                  decoration: InputDecoration(labelText: 'Quantité*'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: _stockMinimumController,
                  decoration: InputDecoration(labelText: 'Stock minimum*'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: _categorieController,
                  decoration: InputDecoration(labelText: 'Catégorie'),
                ),
                SizedBox(height: 16),
                Text('* Champs obligatoires',
                    style: TextStyle(color: Colors.grey)),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Fermer le dialog
              },
              child: Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  // Vérifier que les champs obligatoires ne sont pas vides
                  if (_nomController.text.isEmpty ||
                      _prixController.text.isEmpty ||
                      _quantiteController.text.isEmpty ||
                      _stockMinimumController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text(
                              'Veuillez remplir tous les champs obligatoires')),
                    );
                    return;
                  }

                  int quantite = int.parse(_quantiteController.text);
                  int stockMinimum = int.parse(_stockMinimumController.text);

                  // Vérifier que le stock minimum ne dépasse pas la quantité
                  if (stockMinimum > quantite) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text(
                              'Le stock minimum ne peut pas être supérieur à la quantité')),
                    );
                    return;
                  }

                  final produit = Produit(
                    idProduit:
                        produitExist?.idProduit ?? DateTime.now().toString(),
                    nom: _nomController.text,
                    reference: _referenceController.text,
                    prix: double.parse(_prixController.text),
                    quantite: quantite,
                    stockMinimum: stockMinimum,
                    dateAjout: produitExist?.dateAjout ?? DateTime.now(),
                    categorie: _categorieController.text,
                    idUtilisateur: 'idUtilisateur',
                  );

                  if (produitExist == null) {
                    await _controller.ajouterProduit(produit);
                  } else {
                    await _controller.modifierProduit(produit);
                  }

                  _chargerProduits(); // Recharger la liste des produits
                  Navigator.of(context).pop(); // Fermer le dialog
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
              child: Text('Supprimer'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Gestion des Produits'),
        backgroundColor: Colors.blue.shade800,
        elevation: 8,
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
            child: ListView.builder(
              itemCount: _produitsFiltres.length,
              itemBuilder: (context, index) {
                final produit = _produitsFiltres[index];
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
                        Text('Quantité: ${produit.quantite}'),
                        if (isStockFaible)
                          Text(
                            'Stock faible !',
                            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                          ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.visibility, color: Colors.blue),
                          onPressed: () {
                            _afficherDetailsProduit(context, produit);
                          },
                        ),
                        IconButton(
                          icon: Icon(Icons.edit, color: Colors.orange),
                          onPressed: () {
                            _afficherFormulaireAjoutProduit(context,
                                produitExist: produit);
                          },
                        ),
                        IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
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
        child: Icon(Icons.add),
      ),
    );
  }
}