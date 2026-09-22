import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  // Construtor público para permitir DatabaseHelper()
  DatabaseHelper();

  // Instância principal do banco
  static final DatabaseHelper instance = DatabaseHelper._init();

  static Database? _database;

  // Construtor privado usado pela instância principal
  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    _database = await _initDB('sistema_vendas.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 3,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _createDB(
    Database db,
    int version,
  ) async {
    await db.execute('''
      CREATE TABLE vendedores (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nome TEXT NOT NULL,
        comissao REAL NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE vendas (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        vendedor_id INTEGER NOT NULL,
        produto TEXT NOT NULL,
        quantidade INTEGER NOT NULL,
        valor REAL NOT NULL,
        desconto REAL NOT NULL,
        valor_final REAL NOT NULL,
        forma_pagamento TEXT NOT NULL,
        parcelas INTEGER NOT NULL,
        cliente TEXT,
        comissao_percentual REAL NOT NULL,
        comissao_valor REAL NOT NULL,
        data TEXT NOT NULL,
        total REAL NOT NULL DEFAULT 0,
        juros REAL NOT NULL DEFAULT 0,
        total_com_juros REAL NOT NULL DEFAULT 0,
        valor_parcela REAL NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE venda_itens (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        venda_id INTEGER NOT NULL,
        produto TEXT NOT NULL,
        quantidade INTEGER NOT NULL,
        valor_unitario REAL NOT NULL,
        subtotal REAL NOT NULL,
        comissao_percentual REAL NOT NULL,
        comissao_valor REAL NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE admin_config (
        id INTEGER PRIMARY KEY,
        senha TEXT NOT NULL
      )
    ''');

    await db.insert(
      'admin_config',
      {
        'id': 1,
        'senha': '',
      },
    );
  }

  Future<void> _upgradeDB(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 2) {
      await db.execute(
        'ALTER TABLE vendas ADD COLUMN total REAL NOT NULL DEFAULT 0',
      );

      await db.execute(
        'ALTER TABLE vendas ADD COLUMN juros REAL NOT NULL DEFAULT 0',
      );

      await db.execute(
        'ALTER TABLE vendas ADD COLUMN total_com_juros REAL NOT NULL DEFAULT 0',
      );

      await db.execute(
        'ALTER TABLE vendas ADD COLUMN valor_parcela REAL NOT NULL DEFAULT 0',
      );

      await db.execute('''
        CREATE TABLE venda_itens (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          venda_id INTEGER NOT NULL,
          produto TEXT NOT NULL,
          quantidade INTEGER NOT NULL,
          valor_unitario REAL NOT NULL,
          subtotal REAL NOT NULL,
          comissao_percentual REAL NOT NULL,
          comissao_valor REAL NOT NULL
        )
      ''');

      await db.execute('''
        UPDATE vendas
        SET
          total = valor_final,
          total_com_juros = valor_final,
          valor_parcela =
            CASE
              WHEN parcelas > 0
              THEN valor_final / parcelas
              ELSE valor_final
            END
        WHERE total = 0
      ''');
    }

    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE admin_config (
          id INTEGER PRIMARY KEY,
          senha TEXT NOT NULL
        )
      ''');

      await db.insert(
        'admin_config',
        {
          'id': 1,
          'senha': '',
        },
      );
    }
  }

  // ============================================================
  // ADMINISTRADOR
  // ============================================================

  Future<String> obterSenhaAdministrador() async {
    final db = await database;

    final resultado = await db.query(
      'admin_config',
      where: 'id = ?',
      whereArgs: [1],
      limit: 1,
    );

    if (resultado.isEmpty) {
      return '';
    }

    return resultado.first['senha'].toString();
  }

  Future<void> salvarSenhaAdministrador(
    String senha,
  ) async {
    final db = await database;

    await db.update(
      'admin_config',
      {
        'senha': senha,
      },
      where: 'id = ?',
      whereArgs: [1],
    );
  }

  // ============================================================
  // VENDEDORES
  // ============================================================

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

  Future<int> editarVendedor(
    int id,
    String nome,
    double comissao,
  ) async {
    final db = await database;

    return await db.update(
      'vendedores',
      {
        'nome': nome,
        'comissao': comissao,
      },
      where: 'id = ?',
      whereArgs: [id],
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

  // ============================================================
  // VENDAS
  // ============================================================

  Future<int> adicionarVenda({
    required int vendedorId,
    required List<Map<String, dynamic>> itens,
    required double valor,
    required double desconto,
    required double valorFinal,
    required String formaPagamento,
    required int parcelas,
    String? cliente,
    required double comissaoPercentual,
    required double comissaoValor,
    required double juros,
    required double totalComJuros,
    required double valorParcela,
    required String data,
  }) async {
    final db = await database;

    return await db.transaction<int>((txn) async {
      final primeiroProduto =
          itens.isNotEmpty ? itens.first['produto'].toString() : '';

      final primeiraQuantidade =
          itens.isNotEmpty ? itens.first['quantidade'] as int : 0;

      final vendaId = await txn.insert(
        'vendas',
        {
          'vendedor_id': vendedorId,
          'produto': itens.length == 1
              ? primeiroProduto
              : '${itens.length} produtos',
          'quantidade': primeiraQuantidade,
          'valor': valor,
          'desconto': desconto,
          'valor_final': valorFinal,
          'forma_pagamento': formaPagamento,
          'parcelas': parcelas,
          'cliente': cliente,
          'comissao_percentual': comissaoPercentual,
          'comissao_valor': comissaoValor,
          'data': data,
          'total': valorFinal,
          'juros': juros,
          'total_com_juros': totalComJuros,
          'valor_parcela': valorParcela,
        },
      );

      for (final item in itens) {
        await txn.insert(
          'venda_itens',
          {
            'venda_id': vendaId,
            'produto': item['produto'],
            'quantidade': item['quantidade'],
            'valor_unitario': item['valorUnitario'],
            'subtotal': item['subtotal'],
            'comissao_percentual': item['comissaoPercentual'],
            'comissao_valor': item['comissaoValor'],
          },
        );
      }

      return vendaId;
    });
  }

  Future<List<Map<String, dynamic>>> listarVendas() async {
    final db = await database;

    return await db.query(
      'vendas',
      orderBy: 'data DESC',
    );
  }

  Future<List<Map<String, dynamic>>> listarItensVenda(
    int vendaId,
  ) async {
    final db = await database;

    return await db.query(
      'venda_itens',
      where: 'venda_id = ?',
      whereArgs: [vendaId],
      orderBy: 'id ASC',
    );
  }

  Future<void> excluirVenda(int vendaId) async {
    final db = await database;

    await db.transaction((txn) async {
      await txn.delete(
        'venda_itens',
        where: 'venda_id = ?',
        whereArgs: [vendaId],
      );

      await txn.delete(
        'vendas',
        where: 'id = ?',
        whereArgs: [vendaId],
      );
    });
  }

  // ============================================================
  // RELATÓRIO MENSAL DE VENDAS E COMISSÕES
  // ============================================================

  Future<List<Map<String, dynamic>>> relatorioMensal({
    required int mes,
    required int ano,
  }) async {
    final db = await database;

    final inicio =
        '${ano.toString().padLeft(4, '0')}-${mes.toString().padLeft(2, '0')}-01';

    final proximoMes = mes == 12
        ? '${(ano + 1).toString().padLeft(4, '0')}-01-01'
        : '${ano.toString().padLeft(4, '0')}-${(mes + 1).toString().padLeft(2, '0')}-01';

    return await db.rawQuery('''
      SELECT
        v.id AS vendedor_id,
        v.nome AS vendedor,
        COUNT(vendas.id) AS quantidade_vendas,
        COALESCE(SUM(vendas.valor_final), 0) AS total_vendido,
        COALESCE(SUM(vendas.comissao_valor), 0) AS total_comissao
      FROM vendedores v
      LEFT JOIN vendas
        ON vendas.vendedor_id = v.id
        AND vendas.data >= ?
        AND vendas.data < ?
      GROUP BY v.id, v.nome
      ORDER BY total_vendido DESC
    ''', [
      inicio,
      proximoMes,
    ]);
  }

  Future<Map<String, double>> totaisRelatorioMensal({
    required int mes,
    required int ano,
  }) async {
    final db = await database;

    final inicio =
        '${ano.toString().padLeft(4, '0')}-${mes.toString().padLeft(2, '0')}-01';

    final proximoMes = mes == 12
        ? '${(ano + 1).toString().padLeft(4, '0')}-01-01'
        : '${ano.toString().padLeft(4, '0')}-${(mes + 1).toString().padLeft(2, '0')}-01';

    final resultado = await db.rawQuery('''
      SELECT
        COALESCE(SUM(valor_final), 0) AS total_vendas,
        COALESCE(SUM(comissao_valor), 0) AS total_comissoes
      FROM vendas
      WHERE data >= ?
        AND data < ?
    ''', [
      inicio,
      proximoMes,
    ]);

    return {
      'totalVendas':
          (resultado.first['total_vendas'] as num?)?.toDouble() ?? 0.0,
      'totalComissoes':
          (resultado.first['total_comissoes'] as num?)?.toDouble() ?? 0.0,
    };
  }
}
