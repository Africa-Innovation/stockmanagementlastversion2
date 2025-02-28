import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:stockmanagementversion2/model/produitModel.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() {
    return _instance;
  }

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'gestion_stock.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE utilisateurs(
        idUtilisateur TEXT PRIMARY KEY,
        nom TEXT,
        numero TEXT,
        nomBoutique TEXT,
        motDePasse TEXT,
        codeSecret TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE produits(
        idProduit TEXT PRIMARY KEY,
        nom TEXT,
        reference TEXT,
        prix REAL,
        quantite INTEGER,
        stockMinimum INTEGER,
        dateAjout TEXT,
        categorie TEXT,
        idUtilisateur TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE ventes(
        idVente TEXT PRIMARY KEY,
        date TEXT,
        produitsVendus TEXT,
        montantTotal REAL,
        idUtilisateur TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE produits_vendus(
        idVente TEXT,
        idProduit TEXT,
        quantiteVendue INTEGER,
        PRIMARY KEY (idVente, idProduit)
      )
    ''');

    await db.execute('''
      CREATE TABLE historique_ventes(
        idHistorique TEXT PRIMARY KEY,
        idUtilisateur TEXT
      )
    ''');
  }

  // Méthodes pour interagir avec la base de données
  Future<void> insertUtilisateur(Map<String, dynamic> utilisateur) async {
    final db = await database;
    await db.insert('utilisateurs', utilisateur);
  }

  Future<List<Map<String, dynamic>>> getUtilisateurs() async {
    final db = await database;
    return await db.query('utilisateurs');
  }

  Future<void> insertProduit(Map<String, dynamic> produit) async {
    final db = await database;
    await db.insert('produits', produit);
  }

  Future<List<Map<String, dynamic>>> getProduits(String idUtilisateur) async {
  final db = await database;
  return await db.query(
    'produits',
    where: 'idUtilisateur = ?',
    whereArgs: [idUtilisateur],
  );
}

  Future<void> deleteProduit(String idProduit) async {
    final db = await database;
    await db.delete(
      'produits',
      where: 'idProduit = ?',
      whereArgs: [idProduit],
    );
  }

 Future<void> insertVente(Map<String, dynamic> vente) async {
  final db = await database;
  await db.insert('ventes', vente);
}

Future<List<Map<String, dynamic>>> getVentes(String idUtilisateur) async {
  final db = await database;
  return await db.query(
    'ventes',
    where: 'idUtilisateur = ?',
    whereArgs: [idUtilisateur],
  );
}
  Future<void> updateProduit(Produit produit) async {
  final db = await database;
  await db.update(
    'produits',
    produit.toMap(),
    where: 'idProduit = ?',
    whereArgs: [produit.idProduit],
  );
}

Future<void> deleteVente(String idVente) async {
  final db = await database;
  await db.delete(
    'ventes',
    where: 'idVente = ?',
    whereArgs: [idVente],
  );
}



}