import 'package:flutter/material.dart';
import 'database.dart';
import 'vendas.dart';
import 'historico.dart';

void main() {
  runApp(const SistemaVendasApp());
}

class SistemaVendasApp extends StatelessWidget {
  const SistemaVendasApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Sistema de Vendas',
      theme: ThemeData(
        primarySwatch: Colors.green,
        useMaterial3: true,
      ),
      home: const TelaInicial(),
    );
  }
}

// ============================================================
// TELA INICIAL
// ============================================================

class TelaInicial extends StatelessWidget {
  const TelaInicial({super.key});

  Future<void> abrirAdministracao(BuildContext context) async {
    final banco = DatabaseHelper();

    final senhaAtual = await banco.obterSenhaAdministrador();

    if (!context.mounted) return;

    final controladorSenha = TextEditingController();
    final controladorConfirmacao = TextEditingController();

    final primeiraVez = senhaAtual.isEmpty;

    final resultado = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: Text(
            primeiraVez
                ? 'Criar senha de administrador'
                : 'Acesso administrativo',
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controladorSenha,
                obscureText: true,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText:
                      primeiraVez ? 'Crie uma senha' : 'Digite sua senha',
                  border: const OutlineInputBorder(),
                ),
              ),
              if (primeiraVez) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: controladorConfirmacao,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Confirme a senha',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                final senha = controladorSenha.text.trim();

                if (senha.length < 4) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'A senha deve ter pelo menos 4 caracteres.',
                      ),
                    ),
                  );
                  return;
                }

                if (primeiraVez) {
                  if (senha != controladorConfirmacao.text.trim()) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('As senhas não conferem.'),
                      ),
                    );
                    return;
                  }

                  await banco.salvarSenhaAdministrador(senha);

                  if (!context.mounted) return;

                  Navigator.pop(context, true);
                } else {
                  if (senha == senhaAtual) {
                    Navigator.pop(context, true);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Senha incorreta.'),
                      ),
                    );
                  }
                }
              },
              child: Text(primeiraVez ? 'Criar' : 'Entrar'),
            ),
          ],
        );
      },
    );

    controladorSenha.dispose();
    controladorConfirmacao.dispose();

    if (resultado == true && context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const AdministracaoPage(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sistema de Vendas'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Administração',
            onPressed: () => abrirAdministracao(context),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SizedBox(
            width: double.infinity,
            height: 65,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const VendasPage(),
                  ),
                );
              },
              child: const Text(
                'INICIAR VENDAS',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// ADMINISTRAÇÃO
// ============================================================

class AdministracaoPage extends StatefulWidget {
  const AdministracaoPage({super.key});

  @override
  State<AdministracaoPage> createState() => _AdministracaoPageState();
}

class _AdministracaoPageState extends State<AdministracaoPage> {
  final DatabaseHelper banco = DatabaseHelper();

  List<Map<String, dynamic>> vendedores = [];

  @override
  void initState() {
    super.initState();
    carregarVendedores();
  }

  Future<void> carregarVendedores() async {
    final dados = await banco.listarVendedores();

    if (!mounted) return;

    setState(() {
      vendedores = dados;
    });
  }

  Future<void> adicionarVendedor() async {
    final nomeController = TextEditingController();
    final comissaoController = TextEditingController(text: '1');

    final resultado = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Novo vendedor'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nomeController,
                decoration: const InputDecoration(
                  labelText: 'Nome do vendedor',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: comissaoController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Comissão (%)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                final nome = nomeController.text.trim();

                if (nome.isEmpty) return;

                final comissao = double.tryParse(
                      comissaoController.text.replaceAll(',', '.'),
                    ) ??
                    1.0;

                await banco.adicionarVendedor(nome, comissao);

                if (!context.mounted) return;

                Navigator.pop(context, true);
              },
              child: const Text('Salvar'),
            ),
          ],
        );
      },
    );

    nomeController.dispose();
    comissaoController.dispose();

    if (resultado == true) {
      carregarVendedores();
    }
  }

  Future<void> editarVendedor(Map<String, dynamic> vendedor) async {
    final nomeController =
        TextEditingController(text: vendedor['nome'].toString());

    final comissaoController =
        TextEditingController(text: vendedor['comissao'].toString());

    final resultado = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Editar vendedor'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nomeController,
                decoration: const InputDecoration(
                  labelText: 'Nome',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: comissaoController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Comissão (%)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                final nome = nomeController.text.trim();

                if (nome.isEmpty) return;

                final comissao = double.tryParse(
                      comissaoController.text.replaceAll(',', '.'),
                    ) ??
                    1.0;

                await banco.editarVendedor(
                  vendedor['id'],
                  nome,
                  comissao,
                );

                if (!context.mounted) return;

                Navigator.pop(context, true);
              },
              child: const Text('Salvar'),
            ),
          ],
        );
      },
    );

    nomeController.dispose();
    comissaoController.dispose();

    if (resultado == true) {
      carregarVendedores();
    }
  }

  Future<void> excluirVendedor(Map<String, dynamic> vendedor) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Excluir vendedor'),
          content: Text(
            'Deseja excluir ${vendedor['nome']}?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Excluir'),
            ),
          ],
        );
      },
    );

    if (confirmar == true) {
      await banco.excluirVendedor(vendedor['id']);
      carregarVendedores();
    }
  }

  Future<void> alterarSenha() async {
    final senhaAtualController = TextEditingController();
    final novaSenhaController = TextEditingController();
    final confirmacaoController = TextEditingController();

    final senhaAtual = await banco.obterSenhaAdministrador();

    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Alterar senha'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: senhaAtualController,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Senha atual',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: novaSenhaController,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Nova senha',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: confirmacaoController,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Confirmar nova senha',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (senhaAtualController.text.trim() != senhaAtual) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Senha atual incorreta.'),
                    ),
                  );
                  return;
                }

                final novaSenha = novaSenhaController.text.trim();

                if (novaSenha.length < 4) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'A nova senha deve ter pelo menos 4 caracteres.',
                      ),
                    ),
                  );
                  return;
                }

                if (novaSenha != confirmacaoController.text.trim()) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('As novas senhas não conferem.'),
                    ),
                  );
                  return;
                }

                await banco.salvarSenhaAdministrador(novaSenha);

                if (!context.mounted) return;

                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Senha alterada com sucesso.'),
                  ),
                );
              },
              child: const Text('Salvar'),
            ),
          ],
        );
      },
    );

    senhaAtualController.dispose();
    novaSenhaController.dispose();
    confirmacaoController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Administração'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart),
            tooltip: 'Relatório mensal',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const RelatorioMensalPage(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Histórico de vendas',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const HistoricoPage(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.password),
            tooltip: 'Alterar senha',
            onPressed: alterarSenha,
          ),
        ],
      ),
      body: vendedores.isEmpty
          ? const Center(
              child: Text('Nenhum vendedor cadastrado.'),
            )
          : ListView.builder(
              itemCount: vendedores.length,
              itemBuilder: (context, index) {
                final vendedor = vendedores[index];

                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  child: ListTile(
                    leading: const CircleAvatar(
                      child: Icon(Icons.person),
                    ),
                    title: Text(
                      vendedor['nome'].toString(),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      'Comissão: ${vendedor['comissao']}%',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => editarVendedor(vendedor),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => excluirVendedor(vendedor),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: adicionarVendedor,
        child: const Icon(Icons.add),
      ),
    );
  }
}

// ============================================================
// RELATÓRIO MENSAL / FECHAMENTO
// ============================================================

class RelatorioMensalPage extends StatefulWidget {
  const RelatorioMensalPage({super.key});

  @override
  State<RelatorioMensalPage> createState() => _RelatorioMensalPageState();
}

class _RelatorioMensalPageState extends State<RelatorioMensalPage> {
  final DatabaseHelper banco = DatabaseHelper();

  late int mesSelecionado;
  late int anoSelecionado;

  List<Map<String, dynamic>> dados = [];

  double totalVendas = 0;
  double totalComissoes = 0;

  bool carregando = true;

  final List<String> nomesMeses = const [
    'Janeiro',
    'Fevereiro',
    'Março',
    'Abril',
    'Maio',
    'Junho',
    'Julho',
    'Agosto',
    'Setembro',
    'Outubro',
    'Novembro',
    'Dezembro',
  ];

  @override
  void initState() {
    super.initState();

    final agora = DateTime.now();

    mesSelecionado = agora.month;
    anoSelecionado = agora.year;

    carregarRelatorio();
  }

  Future<void> carregarRelatorio() async {
    if (mounted) {
      setState(() {
        carregando = true;
      });
    }

    final relatorio = await banco.relatorioMensal(
      mes: mesSelecionado,
      ano: anoSelecionado,
    );

    final totais = await banco.totaisRelatorioMensal(
      mes: mesSelecionado,
      ano: anoSelecionado,
    );

    if (!mounted) return;

    setState(() {
      dados = relatorio;
      totalVendas = totais['totalVendas'] ?? 0.0;
      totalComissoes = totais['totalComissoes'] ?? 0.0;
      carregando = false;
    });
  }

  String dinheiro(double valor) {
    return 'R\$ ${valor.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  @override
  Widget build(BuildContext context) {
    double maiorValor = 0;

    for (final item in dados) {
      final valor = (item['total_vendido'] as num?)?.toDouble() ?? 0.0;

      if (valor > maiorValor) {
        maiorValor = valor;
      }
    }

    Map<String, dynamic>? maiorVendedor;

    if (dados.isNotEmpty) {
      maiorVendedor = dados.first;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Relatório Mensal'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: carregarRelatorio,
          ),
        ],
      ),
      body: carregando
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : RefreshIndicator(
              onRefresh: carregarRelatorio,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // ========================================================
                  // MÊS E ANO
                  // ========================================================

                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          value: mesSelecionado,
                          decoration: const InputDecoration(
                            labelText: 'Mês',
                            border: OutlineInputBorder(),
                          ),
                          items: List.generate(
                            12,
                            (index) {
                              final numero = index + 1;

                              return DropdownMenuItem<int>(
                                value: numero,
                                child: Text(nomesMeses[index]),
                              );
                            },
                          ),
                          onChanged: (valor) {
                            if (valor == null) return;

                            setState(() {
                              mesSelecionado = valor;
                            });

                            carregarRelatorio();
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          value: anoSelecionado,
                          decoration: const InputDecoration(
                            labelText: 'Ano',
                            border: OutlineInputBorder(),
                          ),
                          items: List.generate(
                            5,
                            (index) {
                              final ano = DateTime.now().year - 2 + index;

                              return DropdownMenuItem<int>(
                                value: ano,
                                child: Text(ano.toString()),
                              );
                            },
                          ),
                          onChanged: (valor) {
                            if (valor == null) return;

                            setState(() {
                              anoSelecionado = valor;
                            });

                            carregarRelatorio();
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // ========================================================
                  // FECHAMENTO
                  // ========================================================

                  Card(
                    elevation: 3,
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.lock_clock,
                                size: 28,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Fechamento do mês',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleLarge
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${nomesMeses[mesSelecionado - 1]} de $anoSelecionado',
                            style: const TextStyle(
                              fontSize: 16,
                            ),
                          ),
                          const Divider(height: 28),

                          const Text(
                            'TOTAL VENDIDO',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            dinheiro(totalVendas),
                            style: const TextStyle(
                              fontSize: 27,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 18),

                          const Text(
                            'TOTAL DE COMISSÕES',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            dinheiro(totalComissoes),
                            style: const TextStyle(
                              fontSize: 27,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 18),

                          const Text(
                            'VENDEDOR COM MAIOR TOTAL',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            maiorVendedor == null
                                ? 'Nenhuma venda no período'
                                : maiorVendedor['vendedor'].toString(),
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          if (maiorVendedor != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              dinheiro(
                                (maiorVendedor['total_vendido'] as num?)
                                        ?.toDouble() ??
                                    0.0,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ========================================================
                  // GRÁFICO
                  // ========================================================

                  const Text(
                    'Desempenho dos vendedores',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 12),

                  if (dados.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Center(
                          child: Text(
                            'Nenhuma venda encontrada neste mês.',
                          ),
                        ),
                      ),
                    )
                  else
                    ...dados.map(
                      (item) {
                        final valor =
                            (item['total_vendido'] as num?)?.toDouble() ?? 0.0;

                        final double percentual = maiorValor <= 0
                            ? 0.0
                            : (valor / maiorValor)
                                .clamp(0.0, 1.0)
                                .toDouble();

                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.person),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        item['vendedor'].toString(),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      dinheiro(valor),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                LinearProgressIndicator(
                                  value: percentual,
                                  minHeight: 10,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                  const SizedBox(height: 20),

                  // ========================================================
                  // DETALHAMENTO
                  // ========================================================

                  const Text(
                    'Detalhamento por vendedor',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 12),

                  ...dados.map(
                    (item) {
                      final quantidade =
                          (item['quantidade_vendas'] as num?)?.toInt() ?? 0;

                      final vendido =
                          (item['total_vendido'] as num?)?.toDouble() ?? 0.0;

                      final comissao =
                          (item['total_comissao'] as num?)?.toDouble() ?? 0.0;

                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item['vendedor'].toString(),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Quantidade de vendas: $quantidade',
                              ),
                              Text(
                                'Total vendido: ${dinheiro(vendido)}',
                              ),
                              Text(
                                'Comissão: ${dinheiro(comissao)}',
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 30),

                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.info_outline),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Este fechamento é um resumo do mês selecionado. '
                              'As vendas continuam registradas no sistema e '
                              'não são apagadas ou bloqueadas.',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }
}
