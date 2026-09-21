import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();

  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await _initDB('sistema_vendas.db');
    return _database!;
  }

  Future<Database> _initDB(String fileName) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, fileName);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(
    Database db,
    int version,
  ) async {
 await db.execute('''
      CREATE TABLE vendas (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        vendedor_id INTEGER NOT NULL,
        produto TEXT NOT NULL,
        quantidade INTEGER NOT NULL,
        valor REAL NOT NULL,
        comissao_percentual REAL NOT NULL,
        comissao_valor REAL NOT NULL,
        data TEXT NOT NULL,
        FOREIGN KEY (vendedor_id) REFERENCES vendedores (id)
      )
    ''');
  }

  Future<int> adicionarVendedor(
    String nome,
    double comissao,
  ) async {
    final db = await database;

    return await db.insert(
      'vendedores',
      {
        'nome': nome,
        'comissao': comissao,
      },
    );
  }

  Future<List<Map<String, dynamic>>> listarVendedores() async {
    final db = await database;

    return await db.query(
      'vendedores',
      orderBy: 'nome ASC',
    );
  }

  Future<int> excluirVendedor(int id) async {
    final db = await database;

    return await db.delete(
      'vendedores',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
