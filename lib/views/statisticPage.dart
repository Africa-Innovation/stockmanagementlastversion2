import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stockmanagementversion2/controller/venteController.dart';
import 'package:stockmanagementversion2/model/venteModel.dart';
import 'package:stockmanagementversion2/service/pdf_util.dart';

class StatisticPage extends StatefulWidget {
  @override
  _StatisticPageState createState() => _StatisticPageState();
}

class _StatisticPageState extends State<StatisticPage>
    with SingleTickerProviderStateMixin {
  final VenteController _controller = VenteController();
  List<Vente> _ventes = [];
  DateTime? _selectedDate;
  String _selectedPeriod = 'Jour';
  List<Vente> _ventesFiltrees = [];
  List<Vente> _paginatedVentes = [];
  double _totalVentes = 0.0;
  Map<String, int> _topProduits = {};
  Map<String, int> _paginatedTopProduits = {};
  bool isLoading = true;
  late TabController _tabController;
  int _nombreTotalVentes = 0;
  int _nombreTotalProduitsVendus = 0;
  
  // Variables pour la pagination
  final int _itemsPerPage = 10;
  int _currentPageVentes = 1;
  int _totalPagesVentes = 1;
  int _currentPageProduits = 1;
  int _totalPagesProduits = 1;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _selectedDate = DateTime.now();
    _chargerVentes();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _genererPDF() async {
    await PDFUtil.genererPDF(
      titre: "Statistiques des Ventes",
      totalVentes: _totalVentes,
      ventesFiltrees: _ventesFiltrees,
      topProduits: _topProduits,
      nombreTotalVentes: _nombreTotalVentes,
      nombreTotalProduitsVendus: _nombreTotalProduitsVendus,
      fileName: "statistiques_ventes",
    );
  }

  Future<void> _chargerVentes() async {
    final prefs = await SharedPreferences.getInstance();
    final idUtilisateur = prefs.getString('idUtilisateur');

    if (idUtilisateur == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Utilisateur non connecté'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
      return;
    }

    setState(() => isLoading = true);
    
    try {
      final ventes = await _controller.obtenirHistoriqueVentes(idUtilisateur);
      setState(() {
        _ventes = ventes;
        isLoading = false;
        _filtrerVentes();
      });
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur de chargement: $e'),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _updatePaginatedVentes() {
    final startIndex = (_currentPageVentes - 1) * _itemsPerPage;
    final endIndex = startIndex + _itemsPerPage;
    setState(() {
      _paginatedVentes = _ventesFiltrees.sublist(
        startIndex,
        endIndex < _ventesFiltrees.length ? endIndex : _ventesFiltrees.length,
      );
    });
  }

  void _updatePaginatedTopProduits() {
    final startIndex = (_currentPageProduits - 1) * _itemsPerPage;
    final endIndex = startIndex + _itemsPerPage;
    setState(() {
      _paginatedTopProduits = Map.fromEntries(
        _topProduits.entries.toList().sublist(
          startIndex,
          endIndex < _topProduits.length ? endIndex : _topProduits.length,
        ),
      );
    });
  }

  void _filtrerVentes() {
    if (_selectedDate == null) return;

    setState(() {
      _ventesFiltrees = _ventes;

      if (_selectedPeriod == 'Jour') {
        _ventesFiltrees = _ventesFiltrees
            .where((vente) =>
                DateFormat('yyyy-MM-dd').format(vente.date) ==
                DateFormat('yyyy-MM-dd').format(_selectedDate!))
            .toList();
      } else if (_selectedPeriod == 'Mois') {
        _ventesFiltrees = _ventesFiltrees
            .where((vente) =>
                DateFormat('yyyy-MM').format(vente.date) ==
                DateFormat('yyyy-MM').format(_selectedDate!))
            .toList();
      } else if (_selectedPeriod == 'Année') {
        _ventesFiltrees = _ventesFiltrees
            .where((vente) =>
                DateFormat('yyyy').format(vente.date) ==
                DateFormat('yyyy').format(_selectedDate!))
            .toList();
      }

      _totalVentes = _ventesFiltrees.fold(
          0.0, (total, vente) => total + vente.montantTotal);

      _nombreTotalVentes = _ventesFiltrees.length;

      _nombreTotalProduitsVendus = _ventesFiltrees.fold(
          0, (total, vente) => total + vente.produitsVendus.fold(
              0, (sum, produit) => sum + produit.quantiteVendue));

      _topProduits = {};
      for (var vente in _ventesFiltrees) {
        for (var produit in vente.produitsVendus) {
          _topProduits[produit.nom] =
              (_topProduits[produit.nom] ?? 0) + produit.quantiteVendue;
        }
      }

      _topProduits = Map.fromEntries(
        _topProduits.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value)),
      );

      // Mettre à jour la pagination
      _currentPageVentes = 1;
      _currentPageProduits = 1;
      _totalPagesVentes = (_ventesFiltrees.length / _itemsPerPage).ceil();
      _totalPagesProduits = (_topProduits.length / _itemsPerPage).ceil();
      _updatePaginatedVentes();
      _updatePaginatedTopProduits();
    });
  }

  Widget _buildPaginationControls(bool isVentesTab) {
    final currentPage = isVentesTab ? _currentPageVentes : _currentPageProduits;
    final totalPages = isVentesTab ? _totalPagesVentes : _totalPagesProduits;
    final Function(bool) onPageChanged = isVentesTab 
        ? (forward) {
            setState(() {
              if (forward) {
                _currentPageVentes++;
              } else {
                _currentPageVentes--;
              }
              _updatePaginatedVentes();
            });
          }
        : (forward) {
            setState(() {
              if (forward) {
                _currentPageProduits++;
              } else {
                _currentPageProduits--;
              }
              _updatePaginatedTopProduits();
            });
          };

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: Icon(Icons.chevron_left, color: Colors.blue.shade800),
            onPressed: currentPage > 1
                ? () => onPageChanged(false)
                : null,
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Page $currentPage/$totalPages',
              style: TextStyle(
                color: Colors.blue.shade800,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.chevron_right, color: Colors.blue.shade800),
            onPressed: currentPage < totalPages
                ? () => onPageChanged(true)
                : null,
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.blue.shade800,
              onPrimary: Colors.white,
              onSurface: Colors.grey.shade800,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Colors.blue.shade800,
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _filtrerVentes();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Statistiques des Ventes',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blueAccent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.download_rounded, size: 24),
            tooltip: 'Exporter en PDF',
            onPressed: _genererPDF,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              indicatorColor: Colors.blue.shade800,
              labelColor: Colors.blue.shade800,
              unselectedLabelColor: Colors.grey.shade600,
              labelStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.normal,
              ),
              tabs: const [
                Tab(text: 'Ventes'),
                Tab(text: 'Top Produits'),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Filtres
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButton<String>(
                      value: _selectedPeriod,
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _selectedPeriod = newValue;
                            _filtrerVentes();
                          });
                        }
                      },
                      items: <String>['Jour', 'Mois', 'Année']
                          .map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(
                            value,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade800,
                            ),
                          ),
                        );
                      }).toList(),
                      underline: const SizedBox(),
                      isExpanded: true,
                      icon: Icon(Icons.arrow_drop_down_rounded,
                          color: Colors.grey.shade600),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                InkWell(
                  onTap: () => _selectDate(context),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade800,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_rounded,
                            size: 20, color: Colors.white),
                        const SizedBox(width: 8),
                        Text(
                          _selectedDate != null
                              ? DateFormat('dd/MM/yyyy').format(_selectedDate!)
                              : 'Sélectionner',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Statistiques principales
          Container(
            padding: const EdgeInsets.all(7),
            margin: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildStatCard(
                  icon: Icons.attach_money_rounded,
                  title: 'Total des ventes',
                  value: '${_totalVentes.toStringAsFixed(2)} FCFA',
                  color: Colors.green.shade600,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        icon: Icons.receipt_rounded,
                        title: 'Nombre de ventes',
                        value: '$_nombreTotalVentes',
                        color: Colors.blue.shade600,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        icon: Icons.shopping_bag_rounded,
                        title: 'Produits vendus',
                        value: '$_nombreTotalProduitsVendus',
                        color: Colors.orange.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Contenu des onglets
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Onglet Ventes
                Column(
                  children: [
                    Expanded(
                      child: isLoading
                          ? Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.blue.shade800),
                              ),
                            )
                          : _ventesFiltrees.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.receipt_long_rounded,
                                          size: 48, color: Colors.grey.shade400),
                                      const SizedBox(height: 16),
                                      Text(
                                        'Aucune vente trouvée',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                      Text(
                                        'Sélectionnez une autre période',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey.shade500,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : ListView.separated(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  itemCount: _paginatedVentes.length,
                                  separatorBuilder: (context, index) =>
                                      const SizedBox(height: 8),
                                  itemBuilder: (context, index) {
                                    final vente = _paginatedVentes[index];
                                    final formattedDate = DateFormat('dd/MM/yyyy HH:mm')
                                        .format(vente.date);
                                    return Card(
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        side: BorderSide(
                                          color: Colors.grey.shade200,
                                          width: 1,
                                        ),
                                      ),
                                      child: ExpansionTile(
                                        leading: Icon(Icons.receipt_rounded,
                                            color: Colors.blue.shade800),
                                        title: Text(
                                          'Vente #${vente.idVente}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        subtitle: Text(
                                          formattedDate,
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                        trailing: Text(
                                          '${vente.montantTotal.toStringAsFixed(2)} FCFA',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: Colors.green.shade600,
                                          ),
                                        ),
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 16, vertical: 8),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: vente.produitsVendus
                                                  .map((produit) => Padding(
                                                        padding:
                                                            const EdgeInsets.only(bottom: 8),
                                                        child: Row(
                                                          children: [
                                                            Expanded(
                                                              child: Text(
                                                                '- ${produit.nom}',
                                                                style: const TextStyle(
                                                                    fontSize: 14),
                                                              ),
                                                            ),
                                                            Text(
                                                              'x${produit.quantiteVendue}',
                                                              style: TextStyle(
                                                                fontSize: 14,
                                                                color: Colors
                                                                    .grey.shade600,
                                                              ),
                                                            ),
                                                            const SizedBox(width: 16),
                                                            Text(
                                                              '${(produit.prix * produit.quantiteVendue).toStringAsFixed(2)} FCFA',
                                                              style: const TextStyle(
                                                                fontSize: 14,
                                                                fontWeight:
                                                                    FontWeight.w500,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ))
                                                  .toList(),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                    ),
                    _buildPaginationControls(true),
                  ],
                ),

                // Onglet Top Produits
                Column(
                  children: [
                    Expanded(
                      child: isLoading
                          ? Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.blue.shade800),
                              ),
                            )
                          : _topProduits.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.shopping_bag_rounded,
                                          size: 48, color: Colors.grey.shade400),
                                      const SizedBox(height: 16),
                                      Text(
                                        'Aucun produit vendu',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                      Text(
                                        'Sélectionnez une autre période',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey.shade500,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : ListView.separated(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  itemCount: _paginatedTopProduits.length,
                                  separatorBuilder: (context, index) =>
                                      const SizedBox(height: 8),
                                  itemBuilder: (context, index) {
                                    final entry = _paginatedTopProduits.entries.elementAt(index);
                                    return Card(
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        side: BorderSide(
                                          color: Colors.grey.shade200,
                                          width: 1,
                                        ),
                                      ),
                                      child: ListTile(
                                        leading: Container(
                                          width: 40,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            color: Colors.blue.shade50,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Center(
                                            child: Text(
                                              '${(_currentPageProduits - 1) * _itemsPerPage + index + 1}',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.blue.shade800,
                                              ),
                                            ),
                                          ),
                                        ),
                                        title: Text(
                                          entry.key,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        trailing: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: Colors.blue.shade50,
                                            borderRadius: BorderRadius.circular(16),
                                          ),
                                          child: Text(
                                            '${entry.value} unités',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.blue.shade800,
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                    ),
                    _buildPaginationControls(false),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}