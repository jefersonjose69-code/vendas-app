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

  Future<void> abrirVendas(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const VendasPage(),
      ),
    );
  }

  Future<void> abrirAdmin(BuildContext context) async {
    final senhaAtual =
        await DatabaseHelper.instance.obterSenhaAdministrador();

    if (!context.mounted) return;

    if (senhaAtual.isEmpty) {
      await _criarSenhaAdministrador(context);
    } else {
      await _loginAdministrador(context, senhaAtual);
    }
  }

  Future<void> _criarSenhaAdministrador(BuildContext context) async {
    final senhaController = TextEditingController();
    final confirmarController = TextEditingController();

    final resultado = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Criar senha do administrador'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: senhaController,
                obscureText: true,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Nova senha',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: confirmarController,
                obscureText: true,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Confirmar senha',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                final senha = senhaController.text.trim();
                final confirmar = confirmarController.text.trim();

                if (senha.length < 4) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'A senha deve ter pelo menos 4 caracteres.',
                      ),
                    ),
                  );
                  return;
                }

                if (senha != confirmar) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(
                      content: Text('As senhas não conferem.'),
                    ),
                  );
                  return;
                }

                DatabaseHelper.instance
                    .salvarSenhaAdministrador(senha);

                Navigator.pop(dialogContext, true);
              },
              child: const Text('Salvar'),
            ),
          ],
        );
      },
    );

    senhaController.dispose();
    confirmarController.dispose();

    if (resultado == true && context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const AdministracaoPage(),
        ),
      );
    }
  }

  Future<void> _loginAdministrador(
    BuildContext context,
    String senhaCorreta,
  ) async {
    final controller = TextEditingController();

    final resultado = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Administrador'),
          content: TextField(
            controller: controller,
            obscureText: true,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Senha',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                if (controller.text == senhaCorreta) {
                  Navigator.pop(dialogContext, true);
                } else {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(
                      content: Text('Senha incorreta.'),
                    ),
                  );
                }
              },
              child: const Text('Entrar'),
            ),
          ],
        );
      },
    );

    controller.dispose();

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
            tooltip: 'Administrador',
            icon: const Icon(Icons.settings),
            onPressed: () {
              abrirAdmin(context);
            },
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
                abrirVendas(context);
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
  List<Map<String, dynamic>> vendedores = [];

  final nomeController = TextEditingController();
  final comissaoController = TextEditingController();

  @override
  void initState() {
    super.initState();
    carregarVendedores();
  }

  @override
  void dispose() {
    nomeController.dispose();
    comissaoController.dispose();
    super.dispose();
  }

  Future<void> carregarVendedores() async {
    final lista = await DatabaseHelper.instance.listarVendedores();

    if (!mounted) return;

    setState(() {
      vendedores = lista;
    });
  }

  Future<void> adicionarVendedor() async {
    nomeController.clear();
    comissaoController.clear();

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Adicionar vendedor'),
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
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Comissão (%)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                final nome = nomeController.text.trim();

                final comissao = double.tryParse(
                      comissaoController.text
                          .trim()
                          .replaceAll(',', '.'),
                    ) ??
                    0;

                if (nome.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Digite o nome do vendedor.'),
                    ),
                  );
                  return;
                }

                await DatabaseHelper.instance.adicionarVendedor(
                  nome,
                  comissao,
                );

                if (!dialogContext.mounted) return;

                Navigator.pop(dialogContext);

                await carregarVendedores();
              },
              child: const Text('Salvar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> editarVendedor(
    Map<String, dynamic> vendedor,
  ) async {
    final nomeController =
        TextEditingController(text: vendedor['nome'].toString());

    final comissaoController = TextEditingController(
      text: vendedor['comissao'].toString(),
    );

    await showDialog(
      context: context,
      builder: (dialogContext) {
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
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Comissão (%)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                final nome = nomeController.text.trim();

                final comissao = double.tryParse(
                      comissaoController.text
                          .trim()
                          .replaceAll(',', '.'),
                    ) ??
                    0;

                if (nome.isEmpty) return;

                await DatabaseHelper.instance.editarVendedor(
                  vendedor['id'] as int,
                  nome,
                  comissao,
                );

                if (!dialogContext.mounted) return;

                Navigator.pop(dialogContext);

                await carregarVendedores();
              },
              child: const Text('Salvar'),
            ),
          ],
        );
      },
    );

    nomeController.dispose();
    comissaoController.dispose();
  }

  Future<void> excluirVendedor(int id) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Excluir vendedor'),
          content: const Text(
            'Tem certeza que deseja excluir este vendedor?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Excluir'),
            ),
          ],
        );
      },
    );

    if (confirmar != true) return;

    await DatabaseHelper.instance.excluirVendedor(id);

    await carregarVendedores();
  }

  Future<void> alterarSenha() async {
    final atualController = TextEditingController();
    final novaController = TextEditingController();
    final confirmarController = TextEditingController();

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Alterar senha'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: atualController,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Senha atual',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: novaController,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Nova senha',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: confirmarController,
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
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                final senhaAtual = await DatabaseHelper.instance
                    .obterSenhaAdministrador();

                if (atualController.text != senhaAtual) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(
                      content: Text('Senha atual incorreta.'),
                    ),
                  );
                  return;
                }

                if (novaController.text.length < 4) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'A nova senha deve ter pelo menos 4 caracteres.',
                      ),
                    ),
                  );
                  return;
                }

                if (novaController.text !=
                    confirmarController.text) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(
                      content: Text('As senhas não conferem.'),
                    ),
                  );
                  return;
                }

                await DatabaseHelper.instance
                    .salvarSenhaAdministrador(
                  novaController.text,
                );

                if (!dialogContext.mounted) return;

                Navigator.pop(dialogContext);

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

    atualController.dispose();
    novaController.dispose();
    confirmarController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Administração'),
        actions: [
          IconButton(
            tooltip: 'Relatório mensal',
            icon: const Icon(Icons.bar_chart),
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
            tooltip: 'Histórico',
            icon: const Icon(Icons.history),
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
            tooltip: 'Alterar senha',
            icon: const Icon(Icons.password),
            onPressed: () {
              alterarSenha();
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  adicionarVendedor();
                },
                icon: const Icon(Icons.person_add),
                label: const Text('Adicionar vendedor'),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: vendedores.isEmpty
                  ? const Center(
                      child: Text(
                        'Nenhum vendedor cadastrado.',
                      ),
                    )
                  : ListView.builder(
                      itemCount: vendedores.length,
                      itemBuilder: (context, index) {
                        final vendedor = vendedores[index];

                        return Card(
                          child: ListTile(
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
                                  tooltip: 'Editar',
                                  icon: const Icon(Icons.edit),
                                  onPressed: () {
                                    editarVendedor(vendedor);
                                  },
                                ),
                                IconButton(
                                  tooltip: 'Excluir',
                                  icon: const Icon(Icons.delete),
                                  onPressed: () {
                                    excluirVendedor(
                                      vendedor['id'] as int,
                                    );
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
      ),
    );
  }
}

// ============================================================
// RELATÓRIO MENSAL
// ============================================================

class RelatorioMensalPage extends StatefulWidget {
  const RelatorioMensalPage({super.key});

  @override
  State<RelatorioMensalPage> createState() =>
      _RelatorioMensalPageState();
}

class _RelatorioMensalPageState
    extends State<RelatorioMensalPage> {
  late int mesSelecionado;
  late int anoSelecionado;

  List<Map<String, dynamic>> dados = [];

  double totalVendas = 0;
  double totalComissoes = 0;

  bool carregando = true;

  final List<String> nomesMeses = [
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
    setState(() {
      carregando = true;
    });

    final resultado =
        await DatabaseHelper.instance.relatorioMensal(
      mes: mesSelecionado,
      ano: anoSelecionado,
    );

    final totais =
        await DatabaseHelper.instance.totaisRelatorioMensal(
      mes: mesSelecionado,
      ano: anoSelecionado,
    );

    if (!mounted) return;

    setState(() {
      dados = resultado;
      totalVendas = totais['totalVendas'] ?? 0;
      totalComissoes = totais['totalComissoes'] ?? 0;
      carregando = false;
    });
  }

  String dinheiro(double valor) {
    return 'R\$ ${valor.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  double valorVendido(Map<String, dynamic> item) {
    return (item['total_vendido'] as num?)?.toDouble() ?? 0;
  }

  double valorComissao(Map<String, dynamic> item) {
    return (item['total_comissao'] as num?)?.toDouble() ?? 0;
  }

  int quantidadeVendas(Map<String, dynamic> item) {
    return (item['quantidade_vendas'] as num?)?.toInt() ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final vendedorCampeao =
        dados.isNotEmpty ? dados.first['vendedor'].toString() : '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Relatório Mensal'),
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
                              final numeroMes = index + 1;

                              return DropdownMenuItem<int>(
                                value: numeroMes,
                                child: Text(
                                  nomesMeses[index],
                                ),
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
                            6,
                            (index) {
                              final ano =
                                  DateTime.now().year - 2 + index;

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

                  Row(
                    children: [
                      Expanded(
                        child: _CardResumo(
                          titulo: 'Total vendido',
                          valor: dinheiro(totalVendas),
                          icone: Icons.attach_money,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _CardResumo(
                          titulo: 'Comissões',
                          valor: dinheiro(totalComissoes),
                          icone: Icons.payments,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  if (vendedorCampeao.isNotEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.emoji_events,
                              size: 38,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Maior vendedor do mês',
                                    style: TextStyle(
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    vendedorCampeao,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    dinheiro(
                                      valorVendido(dados.first),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  const SizedBox(height: 20),

                  const Text(
                    'Vendas por vendedor',
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
                            'Nenhuma venda registrada neste mês.',
                          ),
                        ),
                      ),
                    )
                  else
                    ...dados.map(
                      (item) => _GraficoVendedor(
                        nome: item['vendedor'].toString(),
                        valor: valorVendido(item),
                        total: totalVendas,
                      ),
                    ),

                  const SizedBox(height: 20),

                  const Text(
                    'Detalhamento',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  ...dados.map(
                    (item) {
                      return Card(
                        child: ListTile(
                          leading: const CircleAvatar(
                            child: Icon(Icons.person),
                          ),
                          title: Text(
                            item['vendedor'].toString(),
                          ),
                          subtitle: Text(
                            '${quantidadeVendas(item)} venda(s)',
                          ),
                          trailing: Column(
                            mainAxisAlignment:
                                MainAxisAlignment.center,
                            crossAxisAlignment:
                                CrossAxisAlignment.end,
                            children: [
                              Text(
                                dinheiro(
                                  valorVendido(item),
                                ),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Comissão: ${dinheiro(valorComissao(item))}',
                                style: const TextStyle(
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
    );
  }
}

// ============================================================
// CARD DE RESUMO
// ============================================================

class _CardResumo extends StatelessWidget {
  final String titulo;
  final String valor;
  final IconData icone;

  const _CardResumo({
    required this.titulo,
    required this.valor,
    required this.icone,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Icon(
              icone,
              size: 30,
            ),
            const SizedBox(height: 8),
            Text(
              titulo,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 5),
            Text(
              valor,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// BARRA DO GRÁFICO
// ============================================================

class _GraficoVendedor extends StatelessWidget {
  final String nome;
  final double valor;
  final double total;

  const _GraficoVendedor({
    required this.nome,
    required this.valor,
    required this.total,
  });

  String dinheiro(double valor) {
    return 'R\$ ${valor.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  @override
  Widget build(BuildContext context) {
    double percentual = 0;

    if (total > 0) {
      percentual = valor / total;
    }

    if (percentual > 1) {
      percentual = 1;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  nome,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
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
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: percentual,
              minHeight: 20,
            ),
          ),
        ],
      ),
    );
  }
}
