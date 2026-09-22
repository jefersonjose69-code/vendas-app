import 'package:flutter/material.dart';
import 'database.dart';

class VendasPage extends StatefulWidget {
  const VendasPage({super.key});

  @override
  State<VendasPage> createState() => _VendasPageState();
}

class _VendasPageState extends State<VendasPage> {
  List<Map<String, dynamic>> vendedores = [];

  int? vendedorSelecionado;

  final produtoController = TextEditingController();
  final quantidadeController = TextEditingController(text: '1');
  final valorController = TextEditingController();
  final clienteController = TextEditingController();

  String formaPagamento = 'À vista';
  int parcelas = 1;

  @override
  void initState() {
    super.initState();
    carregarVendedores();
  }

  Future<void> carregarVendedores() async {
    final dados = await DatabaseHelper.instance.listarVendedores();

    if (!mounted) return;

    setState(() {
      vendedores = dados;
    });
  }

  Future<void> salvarVenda() async {
    final produto = produtoController.text.trim();

    final quantidadeTexto =
        int.tryParse(quantidadeController.text);

    final valorUnitario = double.tryParse(
      valorController.text.replaceAll(',', '.'),
    );

    final cliente = clienteController.text.trim();

    if (vendedorSelecionado == null ||
        produto.isEmpty ||
        quantidadeTexto == null ||
        quantidadeTexto <= 0 ||
        valorUnitario == null ||
        valorUnitario <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preencha todos os campos corretamente.'),
        ),
      );
      return;
    }

    final quantidade = quantidadeTexto;

    if (formaPagamento == 'Crediário' && cliente.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Informe o nome do cliente do crediário.'),
        ),
      );
      return;
    }

    final valor = valorUnitario * quantidade;

    double desconto = 0;

    if (formaPagamento == 'PIX') {
      desconto = valor * 0.10;
    }

    final valorFinal = valor - desconto;

    // Comissão fixa de 1%
    const comissaoPercentual = 1.0;

    final comissaoValor =
        valorFinal * comissaoPercentual / 100;

    final data = DateTime.now().toIso8601String();

    await DatabaseHelper.instance.adicionarVenda(
      vendedorId: vendedorSelecionado!,
      produto: produto,
      quantidade: quantidade,
      valor: valor,
      desconto: desconto,
      valorFinal: valorFinal,
      formaPagamento: formaPagamento,
      parcelas: parcelas,
      cliente: formaPagamento == 'Crediário'
          ? cliente
          : null,
      comissaoPercentual: comissaoPercentual,
      comissaoValor: comissaoValor,
      data: data,
    );

    if (!mounted) return;

    produtoController.clear();
    quantidadeController.text = '1';
    valorController.clear();
    clienteController.clear();

    setState(() {
      formaPagamento = 'À vista';
      parcelas = 1;
      vendedorSelecionado = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Venda registrada! Comissão: R\$ '
          '${comissaoValor.toStringAsFixed(2)}',
        ),
      ),
    );
  }

  @override
  void dispose() {
    produtoController.dispose();
    quantidadeController.dispose();
    valorController.dispose();
    clienteController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nova Venda'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<int>(
              value: vendedorSelecionado,
              decoration: const InputDecoration(
                labelText: 'Vendedor',
                border: OutlineInputBorder(),
              ),
              items: vendedores.map((vendedor) {
                return DropdownMenuItem<int>(
                  value: vendedor['id'] as int,
                  child: Text(
                    vendedor['nome'].toString(),
                  ),
                );
              }).toList(),
              onChanged: (valor) {
                setState(() {
                  vendedorSelecionado = valor;
                });
              },
            ),

            const SizedBox(height: 16),

            TextField(
              controller: produtoController,
              decoration: const InputDecoration(
                labelText: 'Produto',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            TextField(
              controller: quantidadeController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Quantidade',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            TextField(
              controller: valorController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Valor unitário',
                prefixText: 'R\$ ',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            DropdownButtonFormField<String>(
              value: formaPagamento,
              decoration: const InputDecoration(
                labelText: 'Forma de pagamento',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'À vista',
                  child: Text('À vista'),
                ),
                DropdownMenuItem(
                  value: 'PIX',
                  child: Text('PIX - 10% de desconto'),
                ),
                DropdownMenuItem(
                  value: 'Cartão',
                  child: Text('Cartão'),
                ),
                DropdownMenuItem(
                  value: 'Crediário',
                  child: Text('Crediário'),
                ),
              ],
              onChanged: (valor) {
                setState(() {
                  formaPagamento = valor!;
                  parcelas = 1;
                });
              },
            ),

            if (formaPagamento == 'Cartão') ...[
              const SizedBox(height: 16),

              DropdownButtonFormField<int>(
                value: parcelas,
                decoration: const InputDecoration(
                  labelText: 'Número de parcelas',
                  border: OutlineInputBorder(),
                ),
                items: List.generate(10, (index) {
                  final numero = index + 1;

                  return DropdownMenuItem(
                    value: numero,
                    child: Text('${numero}x'),
                  );
                }),
                onChanged: (valor) {
                  setState(() {
                    parcelas = valor!;
                  });
                },
              ),
            ],

            if (formaPagamento == 'Crediário') ...[
              const SizedBox(height: 16),

              TextField(
                controller: clienteController,
                decoration: const InputDecoration(
                  labelText: 'Nome do cliente',
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 16),

              DropdownButtonFormField<int>(
                value: parcelas,
                decoration: const InputDecoration(
                  labelText: 'Número de parcelas',
                  border: OutlineInputBorder(),
                ),
                items: List.generate(6, (index) {
                  final numero = index + 1;

                  return DropdownMenuItem(
                    value: numero,
                    child: Text('${numero}x'),
                  );
                }),
                onChanged: (valor) {
                  setState(() {
                    parcelas = valor!;
                  });
                },
              ),
            ],

            const SizedBox(height: 24),

            ElevatedButton.icon(
              onPressed: salvarVenda,
              icon: const Icon(Icons.save),
              label: const Text('Registrar venda'),
            ),
          ],
        ),
      ),
    );
  }
}
