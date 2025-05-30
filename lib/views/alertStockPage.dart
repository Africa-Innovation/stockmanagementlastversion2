import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:stockmanagementversion2/controller/produitController.dart';
import 'package:stockmanagementversion2/model/produitModel.dart';

class AlertesStockPage extends StatefulWidget {
  @override
  _AlertesStockPageState createState() => _AlertesStockPageState();
}

class _AlertesStockPageState extends State<AlertesStockPage> {
  final ProduitController _controller = ProduitController();
  List<Produit> _produitsEnAlerte = [];

  @override
  void initState() {
    super.initState();
    _chargerProduitsEnAlerte();
  }

  Future<void> _chargerProduitsEnAlerte() async {
    final produitsEnAlerte = await _controller.verifierAlertesStock();
    setState(() {
      _produitsEnAlerte = produitsEnAlerte;
    });
  }

  Future<void> _afficherFormulaireRavitaillerStock(
      BuildContext context, Produit produit) async {
    final TextEditingController _quantiteController = TextEditingController();

    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Ravitailler le stock'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Produit: ${produit.nom}'),
              const SizedBox(height: 16),
              TextField(
                controller: _quantiteController,
                decoration: const InputDecoration(
                  labelText: 'Quantité à ajouter',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Fermer le dialog
              },
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  final quantiteAjoutee = int.parse(_quantiteController.text);
                  if (quantiteAjoutee <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content:
                              Text('La quantité doit être supérieure à 0')),
                    );
                    return;
                  }

                  // Mettre à jour le stock du produit
                  produit.quantite += quantiteAjoutee;
                  await _controller.modifierProduit(produit);

                  // Recharger la liste des produits en alerte
                  _chargerProduitsEnAlerte();

                  // Fermer le dialog
                  Navigator.of(context).pop();

                  // Afficher un message de succès
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Stock ravitaillé avec succès'),
                      backgroundColor: Colors.green.shade600,
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Erreur: ${e.toString()}'),
                      backgroundColor: Colors.red.shade400,
                    ),
                  );
                }
              },
              child: const Text('Valider'),
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
        title: const Text(
          'Alertes de Stock',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.blueAccent,
        elevation: 8,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _produitsEnAlerte.isEmpty
          ? const Center(
              child: Text(
                'Aucun produit en stock faible',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            )
          : ListView.builder(
              itemCount: _produitsEnAlerte.length,
              itemBuilder: (context, index) {
                final produit = _produitsEnAlerte[index];
                return Card(
                  elevation: 4,
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    title: Text(produit.nom),
                    subtitle: Text(
                        'Stock: ${produit.quantite} (Minimum: ${produit.stockMinimum})'),
                    trailing: IconButton(
                      icon: Icon(Icons.add, color: Colors.blue.shade800),
                      onPressed: () {
                        _afficherFormulaireRavitaillerStock(context, produit);
                      },
                    ),
                  ),
                );
              },
            ),
    );
  }
}
