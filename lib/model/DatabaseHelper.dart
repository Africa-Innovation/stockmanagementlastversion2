import 'dart:convert';

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:stockmanagementversion2/model/produitModel.dart';
import 'package:stockmanagementversion2/model/produitvenduModel.dart';
import 'package:stockmanagementversion2/model/venteModel.dart';

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
        idUtilisateur TEXT,
        synchronise INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE ventes(
        idVente TEXT PRIMARY KEY,
        date TEXT,
        produitsVendus TEXT,
        montantTotal REAL,
        idUtilisateur TEXT,
        synchronise INTEGER DEFAULT 0
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
  await db.insert(
    'produits',
    produit,
    conflictAlgorithm: ConflictAlgorithm.replace, // Remplacer si le produit existe déjà
  );
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

  // Vérifier si la vente existe déjà
  final existingVente = await db.query(
    'ventes',
    where: 'idVente = ?',
    whereArgs: [vente['idVente']],
  );

  if (existingVente.isNotEmpty) {
    // Mettre à jour la vente existante
    await db.update(
      'ventes',
      {
        'date': vente['date'] is DateTime
            ? (vente['date'] as DateTime).toIso8601String() // Convertir DateTime en String
            : vente['date'] as String, // Utiliser directement si c'est déjà une String
        'produitsVendus': jsonEncode(vente['produitsVendus']),
        'montantTotal': vente['montantTotal'],
        'idUtilisateur': vente['idUtilisateur'],
        'synchronise': 0, // 0 = non synchronisé
      },
      where: 'idVente = ?',
      whereArgs: [vente['idVente']],
    );
    print('Vente mise à jour localement: ${vente['idVente']}');
  } else {
    // Insérer une nouvelle vente
    await db.insert(
      'ventes',
      {
        'idVente': vente['idVente'],
        'date': vente['date'] is DateTime
            ? (vente['date'] as DateTime).toIso8601String() // Convertir DateTime en String
            : vente['date'] as String, // Utiliser directement si c'est déjà une String
        'produitsVendus': jsonEncode(vente['produitsVendus']),
        'montantTotal': vente['montantTotal'],
        'idUtilisateur': vente['idUtilisateur'],
        'synchronise': 0, // 0 = non synchronisé
      },
    );
    print('Vente insérée localement: ${vente['idVente']}');
  }
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

//synchronisation part********************************************

Future<List<Produit>> getProduitsNonSynchronises(String idUtilisateur) async {
  final db = await database;
  final produits = await db.query(
    'produits',
    where: 'idUtilisateur = ? AND synchronise = ?',
    whereArgs: [idUtilisateur, 0], // 0 = non synchronisé
  );
  return produits.map((p) => Produit.fromMap(p)).toList();
}

Future<void> marquerProduitCommeSynchronise(String idProduit) async {
  final db = await database;
  await db.update(
    'produits',
    {'synchronise': 1}, // 1 = synchronisé
    where: 'idProduit = ?',
    whereArgs: [idProduit],
  );
}

Future<List<Vente>> getVentesNonSynchronisees(String idUtilisateur) async {
  final db = await database;
  final ventes = await db.query(
    'ventes',
    where: 'idUtilisateur = ? AND synchronise = ?',
    whereArgs: [idUtilisateur, 0], // 0 = non synchronisé
  );
  print('Ventes non synchronisées récupérées: ${ventes.length}');
  return ventes.map((v) {
    print('Date locale récupérée: ${v['date']}');
    final produitsVendus = jsonDecode(v['produitsVendus'] as String);
    return Vente(
      idVente: v['idVente'] as String,
      date: DateTime.parse(v['date'] as String), // Convertir String en DateTime
      produitsVendus: (produitsVendus as List)
          .map((p) => ProduitVendu.fromMap(p))
          .toList(),
      montantTotal: v['montantTotal'] as double,
      idUtilisateur: v['idUtilisateur'] as String,
    );
  }).toList();
}

Future<void> marquerVenteCommeSynchronisee(String idVente) async {
  final db = await database;
  await db.update(
    'ventes',
    {'synchronise': 1}, // 1 = synchronisé
    where: 'idVente = ?',
    whereArgs: [idVente],
  );
}


}