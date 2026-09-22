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
      home: const VendedoresPage(),
    );
  }
}

class VendedoresPage extends StatefulWidget {
  const VendedoresPage({super.key});

  @override
  State<VendedoresPage> createState() => _VendedoresPageState();
}

class _VendedoresPageState extends State<VendedoresPage> {
  List<Map<String, dynamic>> vendedores = [];

  final nomeController = TextEditingController();
  final comissaoController = TextEditingController(text: '1');

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
        title: const Text('Vendedores'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: nomeController,
              decoration: const InputDecoration(
                labelText: 'Nome do vendedor',
                border: OutlineInputBorder(),
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
              ),
            ),

            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: adicionarVendedor,
                icon: const Icon(
                  Icons.person_add,
                ),
                label: const Text(
                  'Adicionar vendedor',
                ),
              ),
            ),

            const SizedBox(height: 20),

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
                        final vendedor =
                            vendedores[index];

                        return Card(
                          child: ListTile(
                            leading: const CircleAvatar(
                              child: Icon(
                                Icons.person,
                              ),
                            ),
                            title: Text(
                              vendedor['nome'].toString(),
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
                                  vendedor['id'] as int,
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

      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.extended(
            heroTag: 'historico',
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
            icon: const Icon(
              Icons.history,
            ),
            label: const Text(
              'Histórico',
            ),
          ),

          const SizedBox(height: 12),

          FloatingActionButton.extended(
            heroTag: 'nova_venda',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) {
                    return const VendasPage();
                  },
                ),
              );
            },
            icon: const Icon(
              Icons.point_of_sale,
            ),
            label: const Text(
              'Nova venda',
            ),
          ),
        ],
      ),
    );
  }
}
