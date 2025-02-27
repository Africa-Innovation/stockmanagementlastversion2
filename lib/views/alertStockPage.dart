import 'package:flutter/material.dart';
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
    final produitsEnAlerte = await _controller.verifierAlertesStock('idUtilisateur');
    setState(() {
      _produitsEnAlerte = produitsEnAlerte;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Alertes de Stock'),
        backgroundColor: Colors.blue.shade800,
        elevation: 8,
      ),
      body: ListView.builder(
        itemCount: _produitsEnAlerte.length,
        itemBuilder: (context, index) {
          final produit = _produitsEnAlerte[index];
          return Card(
            elevation: 4,
            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              title: Text(produit.nom),
              subtitle: Text('Stock: ${produit.quantite} (Minimum: ${produit.stockMinimum})'),
              trailing: IconButton(
                icon: Icon(Icons.add, color: Colors.blue.shade800),
                onPressed: () {
                  // Logique pour augmenter le stock
                },
              ),
            ),
          );
        },
      ),
    );
  }
}