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
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
        ),
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

  void abrirVendas(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const VendasPage(),
      ),
    );
  }

  Future<void> abrirAdmin(BuildContext context) async {
    final senhaAtual =
        await DatabaseHelper.instance.obterSenhaAdministrador();

    if (!context.mounted) return;

    if (senhaAtual.isEmpty) {
      _criarSenhaAdministrador(context);
    } else {
      _loginAdministrador(context, senhaAtual);
    }
  }

  void _criarSenhaAdministrador(BuildContext context) {
    final senhaController = TextEditingController();
    final confirmarController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.admin_panel_settings),
              SizedBox(width: 10),
              Expanded(
                child: Text('Criar senha do administrador'),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Crie uma senha para proteger a área administrativa.',
              ),
              const SizedBox(height: 16),
              TextField(
                controller: senhaController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Nova senha',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: confirmarController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Confirmar senha',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock_outline),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                final senha = senhaController.text;
                final confirmar = confirmarController.text;

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

                if (senha != confirmar) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'As senhas não são iguais.',
                      ),
                    ),
                  );
                  return;
                }

                await DatabaseHelper.instance
                    .salvarSenhaAdministrador(senha);

                if (!context.mounted) return;

                Navigator.pop(context);

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        const AdministracaoPage(),
                  ),
                );
              },
              child: const Text('Salvar senha'),
            ),
          ],
        );
      },
    );
  }

  void _loginAdministrador(
    BuildContext context,
    String senhaCorreta,
  ) {
    final senhaController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.lock),
              SizedBox(width: 10),
              Text('Administrador'),
            ],
          ),
          content: TextField(
            controller: senhaController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Senha',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.lock_outline),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                if (senhaController.text == senhaCorreta) {
                  Navigator.pop(context);

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          const AdministracaoPage(),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Sistema de Vendas',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Administrador',
            icon: const Icon(Icons.settings),
            onPressed: () => abrirAdmin(context),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.storefront,
                size: 90,
              ),
              const SizedBox(height: 25),
              const Text(
                'Sistema de Vendas',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Gerencie suas vendas de forma simples',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 45),
              SizedBox(
                width: double.infinity,
                height: 65,
                child: ElevatedButton.icon(
                  onPressed: () => abrirVendas(context),
                  icon: const Icon(
                    Icons.point_of_sale,
                    size: 30,
                  ),
                  label: const Text(
                    'INICIAR VENDAS',
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
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
  State<AdministracaoPage> createState() =>
      _AdministracaoPageState();
}

class _AdministracaoPageState
    extends State<AdministracaoPage> {
  List<Map<String, dynamic>> vendedores = [];

  final nomeController = TextEditingController();
  final comissaoController =
      TextEditingController(text: '1');

  @override
  void initState() {
    super.initState();
    carregarVendedores();
  }

  Future<void> carregarVendedores() async {
    final dados =
        await DatabaseHelper.instance.listarVendedores();

    if (!mounted) return;

    setState(() {
      vendedores = dados;
    });
  }

  Future<void> adicionarVendedor() async {
    final nome = nomeController.text.trim();

    if (nome.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Informe o nome do vendedor.'),
        ),
      );
      return;
    }

    final comissao = double.tryParse(
          comissaoController.text.replaceAll(',', '.'),
        ) ??
        1.0;

    await DatabaseHelper.instance.adicionarVendedor(
      nome,
      comissao,
    );

    nomeController.clear();
    comissaoController.text = '1';

    await carregarVendedores();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Vendedor cadastrado!'),
      ),
    );
  }

  // ==========================================================
  // EDITAR VENDEDOR
  // ==========================================================

  void editarVendedor(
    Map<String, dynamic> vendedor,
  ) {
    final nomeControllerEdicao =
        TextEditingController(
      text: vendedor['nome'].toString(),
    );

    final comissaoControllerEdicao =
        TextEditingController(
      text: vendedor['comissao'].toString(),
    );

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Editar vendedor',
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nomeControllerEdicao,
                decoration: const InputDecoration(
                  labelText: 'Nome do vendedor',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
              ),

              const SizedBox(height: 16),

              TextField(
                controller: comissaoControllerEdicao,
                keyboardType:
                    const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Comissão (%)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.percent),
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

            ElevatedButton.icon(
              onPressed: () async {
                final nome =
                    nomeControllerEdicao.text.trim();

                if (nome.isEmpty) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Informe o nome do vendedor.',
                      ),
                    ),
                  );
                  return;
                }

                final comissao = double.tryParse(
                      comissaoControllerEdicao.text
                          .replaceAll(',', '.'),
                    ) ??
                    1.0;

                await DatabaseHelper.instance
                    .editarVendedor(
                  vendedor['id'] as int,
                  nome,
                  comissao,
                );

                if (!dialogContext.mounted) return;

                Navigator.pop(dialogContext);

                await carregarVendedores();

                if (!mounted) return;

                ScaffoldMessenger.of(context)
                    .showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Vendedor atualizado!',
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.save),
              label: const Text('Salvar'),
            ),
          ],
        );
      },
    );
  }

  // ==========================================================
  // EXCLUIR VENDEDOR
  // ==========================================================

  Future<void> excluirVendedor(int id) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Excluir vendedor?',
          ),
          content: const Text(
            'Essa ação excluirá o vendedor do cadastro.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text('Excluir'),
            ),
          ],
        );
      },
    );

    if (confirmar != true) return;

    await DatabaseHelper.instance
        .excluirVendedor(id);

    await carregarVendedores();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Vendedor excluído.'),
      ),
    );
  }

  // ==========================================================
  // ALTERAR SENHA
  // ==========================================================

  Future<void> alterarSenha() async {
    final senhaAtualController =
        TextEditingController();

    final novaSenhaController =
        TextEditingController();

    final confirmarController =
        TextEditingController();

    final senhaAtual =
        await DatabaseHelper.instance
            .obterSenhaAdministrador();

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Alterar senha',
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: senhaAtualController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Senha atual',
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 12),

                TextField(
                  controller: novaSenhaController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Nova senha',
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 12),

                TextField(
                  controller: confirmarController,
                  obscureText: true,
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
                if (senhaAtualController.text !=
                    senhaAtual) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(
                    const SnackBar(
                      content: Text(
                        'A senha atual está incorreta.',
                      ),
                    ),
                  );
                  return;
                }

                final novaSenha =
                    novaSenhaController.text;

                if (novaSenha.length < 4) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(
                    const SnackBar(
                      content: Text(
                        'A nova senha deve ter pelo menos 4 caracteres.',
                      ),
                    ),
                  );
                  return;
                }

                if (novaSenha !=
                    confirmarController.text) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(
                    const SnackBar(
                      content: Text(
                        'As novas senhas não são iguais.',
                      ),
                    ),
                  );
                  return;
                }

                await DatabaseHelper.instance
                    .salvarSenhaAdministrador(
                  novaSenha,
                );

                if (!dialogContext.mounted) return;

                Navigator.pop(dialogContext);

                if (!mounted) return;

                ScaffoldMessenger.of(context)
                    .showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Senha alterada com sucesso!',
                    ),
                  ),
                );
              },
              child: const Text(
                'Alterar senha',
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    nomeController.dispose();
    comissaoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Administração',
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Alterar senha',
            icon: const Icon(
              Icons.password,
            ),
            onPressed: alterarSenha,
          ),

          IconButton(
            tooltip: 'Histórico de vendas',
            icon: const Icon(
              Icons.history,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      const HistoricoPage(),
                ),
              );
            },
          ),
        ],
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Row(
              children: [
                Icon(
                  Icons.admin_panel_settings,
                  size: 28,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Configurações administrativas',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            TextField(
              controller: nomeController,
              decoration: const InputDecoration(
                labelText: 'Nome do vendedor',
                border: OutlineInputBorder(),
                prefixIcon: Icon(
                  Icons.person,
                ),
              ),
            ),

            const SizedBox(height: 16),

            TextField(
              controller: comissaoController,
              keyboardType:
                  const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Comissão (%)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(
                  Icons.percent,
                ),
              ),
            ),

            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: adicionarVendedor,
                icon: const Icon(
                  Icons.person_add,
                ),
                label: const Text(
                  'Cadastrar vendedor',
                ),
              ),
            ),

            const SizedBox(height: 20),

            const Divider(),

            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Vendedores cadastrados',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 10),

            Expanded(
              child: vendedores.isEmpty
                  ? const Center(
                      child: Text(
                        'Nenhum vendedor cadastrado.',
                      ),
                    )
                  : ListView.builder(
                      itemCount: vendedores.length,
                      itemBuilder: (
                        context,
                        index,
                      ) {
                        final vendedor =
                            vendedores[index];

                        return Card(
                          child: ListTile(
                            leading:
                                const CircleAvatar(
                              child: Icon(
                                Icons.person,
                              ),
                            ),

                            title: Text(
                              vendedor['nome']
                                  .toString(),
                            ),

                            subtitle: Text(
                              'Comissão: '
                              '${vendedor['comissao']}%',
                            ),

                            trailing: Row(
                              mainAxisSize:
                                  MainAxisSize.min,
                              children: [
                                IconButton(
                                  tooltip: 'Editar',
                                  icon: const Icon(
                                    Icons.edit,
                                  ),
                                  onPressed: () {
                                    editarVendedor(
                                      vendedor,
                                    );
                                  },
                                ),

                                IconButton(
                                  tooltip: 'Excluir',
                                  icon: const Icon(
                                    Icons.delete,
                                  ),
                                  onPressed: () {
                                    excluirVendedor(
                                      vendedor['id']
                                          as int,
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
