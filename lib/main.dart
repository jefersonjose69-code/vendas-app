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
        builder: (context) {
          return const VendasPage();
        },
      ),
    );
  }

  void abrirAdmin(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        final senhaController = TextEditingController();

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
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Senha',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.lock_outline),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                if (senhaController.text == '1234') {
                  Navigator.pop(context);

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) {
                        return const AdministracaoPage();
                      },
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Senha incorreta.',
                      ),
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
            icon: const Icon(
              Icons.settings,
            ),
            onPressed: () {
              abrirAdmin(context);
            },
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
                  onPressed: () {
                    abrirVendas(context);
                  },
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

              const SizedBox(height: 20),

              TextButton.icon(
                onPressed: () {
                  abrirAdmin(context);
                },
                icon: const Icon(
                  Icons.admin_panel_settings,
                ),
                label: const Text(
                  'Área do Administrador',
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
// ÁREA DO ADMINISTRADOR
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
          content: Text(
            'Informe o nome do vendedor.',
          ),
        ),
      );
      return;
    }

    final comissao =
        double.tryParse(
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
        content: Text(
          'Vendedor cadastrado!',
        ),
      ),
    );
  }

  Future<void> excluirVendedor(int id) async {
    await DatabaseHelper.instance.excluirVendedor(id);
    await carregarVendedores();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Vendedor excluído.',
        ),
      ),
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
            tooltip: 'Histórico de vendas',
            icon: const Icon(
              Icons.history,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) {
                    return const HistoricoPage();
                  },
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
                Text(
                  'Configurações administrativas',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
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
                            trailing: IconButton(
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
