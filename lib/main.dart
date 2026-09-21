import 'package:flutter/material.dart';
import 'database.dart';
import 'vendas.dart';

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
  final comissaoController = TextEditingController();

  @override
  void initState() {
    super.initState();
    carregarVendedores();
  }

  Future<void> carregarVendedores() async {
    final dados = await DatabaseHelper.instance.listarVendedores();

    setState(() {
      vendedores = dados;
    });
  }

  Future<void> adicionarVendedor() async {
    final nome = nomeController.text.trim();

    final comissao = double.tryParse(
      comissaoController.text.replaceAll(',', '.'),
    );

    if (nome.isEmpty || comissao == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Preencha o nome e a comissão corretamente.',
          ),
        ),
      );
      return;
    }

    if (comissao < 0 || comissao > 100) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'A comissão deve estar entre 0% e 100%.',
          ),
        ),
      );
      return;
    }

    await DatabaseHelper.instance.adicionarVendedor(
      nome,
      comissao,
    );

    nomeController.clear();
    comissaoController.clear();

    await carregarVendedores();

    if (mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> excluirVendedor(int id) async {
    await DatabaseHelper.instance.excluirVendedor(id);
    await carregarVendedores();
  }

  void abrirCadastro() {
    showDialog(
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
              const SizedBox(height: 15),
              TextField(
                controller: comissaoController,
                keyboardType:
                    const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Comissão',
                  hintText: 'Ex.: 5',
                  suffixText: '%',
                  border: OutlineInputBorder(),
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
              onPressed: adicionarVendedor,
              child: const Text('Salvar'),
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
        title: const Text('Vendedores'),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const VendasPage(),
    
    );
  },
  icon: const Icon(Icons.point_of_sale),
  label: const Text('Nova venda'),
),,
      ),
      body: vendedores.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.people_outline,
                    size: 80,
                  ),
                  SizedBox(height: 15),
                  Text(
                    'Nenhum vendedor cadastrado',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Toque em "Novo vendedor" para começar.',
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: vendedores.length,
              itemBuilder: (context, index) {
                final vendedor = vendedores[index];

                return Card(
                  child: ListTile(
                    leading: const CircleAvatar(
                      child: Icon(Icons.person),
                    ),
                    title: Text(
                      vendedor['nome'],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      'Comissão: '
                      '${(vendedor['comissao'] as num).toStringAsFixed(2)}%',
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () =>
                          excluirVendedor(vendedor['id']),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
