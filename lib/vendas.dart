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
  String formaPagamento = 'À vista';
  int parcelas = 1;
  final clienteController = TextEditingController();
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

  Future<void> salvarVenda() async {
  final produto = produtoController.text.trim();
  final quantidade = int.tryParse(quantidadeController.text);
  final valorUnitario = double.tryParse(
    valorController.text.replaceAll(',', '.'),
  );

  final cliente = clienteController.text.trim();

  if (vendedorSelecionado == null ||
      produto.isEmpty ||
      quantidade == null ||
      quantidade <= 0 ||
      valorUnitario == null ||
      valorUnitario <= 0) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Preencha todos os campos corretamente.'),
      ),
    );
    return;
  }

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
  final comissaoValor = valorFinal * comissaoPercentual / 100;

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
    cliente: formaPagamento == 'Crediário' ? cliente : null,
    comissaoPercentual: comissaoPercentual,
    comissaoValor: comissaoValor,
    data: data,
  );

  produtoController.clear();
  quantidadeController.text = '1';
  valorController.clear();
  clienteController.clear();

  setState(() {
    formaPagamento = 'À vista';
    parcelas = 1;
    vendedorSelecionado = null;
  });

  if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Venda registrada! Comissão: R\$ ${comissaoValor.toStringAsFixed(2)}',
        ),
      ),
    );
  }

    final produto = produtoController.text.trim();
    final quantidadeTexto = int.tryParse(quantidadeController.text);

if (quantidadeTexto == null || quantidadeTexto <= 0) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('Informe uma quantidade válida.'),
    ),
  );
  return;
}

final quantidade = quantidadeTexto;
    final valor = double.tryParse(
      valorController.text.replaceAll(',', '.'),
    );

    if (vendedorSelecionado == null ||
        produto.isEmpty ||
        quantidade == null ||
        quantidade <= 0 ||
        valor == null ||
        valor <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preencha todos os campos corretamente.'),
        ),
      );
      return;
    }

    final vendedor = vendedores.firstWhere(
      (item) => item['id'] == vendedorSelecionado,
    );

    final comissaoPercentual =
        (vendedor['comissao'] as num).toDouble();

    final valorTotal = valor * quantidade;

    final comissaoValor =
        valorTotal * comissaoPercentual / 100;

    final data = DateTime.now().toIso8601String();

    await DatabaseHelper.instance.adicionarVenda(
      vendedorId: vendedorSelecionado!,
      produto: produto,
      quantidade: quantidade,
      valor: valorTotal,
      comissaoPercentual: comissaoPercentual,
      comissaoValor: comissaoValor,
      data: data,
    );

    produtoController.clear();
    quantidadeController.text = '1';
    valorController.clear();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Venda registrada com sucesso!'),
        ),
      );
    }
  }

  @override
  void dispose() {
    produtoController.dispose();
    quantidadeController.dispose();
    valorController.dispose();
    clienteController.dispose();
    
    super.dispose();
  }
Future<void> salvarVenda() async {
  final produto = produtoController.text.trim();
  final quantidade = int.tryParse(quantidadeController.text);
  final valorUnitario = double.tryParse(
    valorController.text.replaceAll(',', '.'),
  );

  final cliente = clienteController.text.trim();

  if (vendedorSelecionado == null ||
      produto.isEmpty ||
      quantidade == null ||
      quantidade <= 0 ||
      valorUnitario == null ||
      valorUnitario <= 0) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Preencha todos os campos corretamente.'),
      ),
    );
    return;
  }

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

  const comissaoPercentual = 1.0;
  final comissaoValor = valorFinal * comissaoPercentual / 100;

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
    cliente: formaPagamento == 'Crediário' ? cliente : null,
    comissaoPercentual: comissaoPercentual,
    comissaoValor: comissaoValor,
    data: data,
  );

  produtoController.clear();
  quantidadeController.text = '1';
  valorController.clear();
  clienteController.clear();

  setState(() {
    formaPagamento = 'À vista';
    parcelas = 1;
    vendedorSelecionado = null;
  });

  if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Venda registrada! Comissão: R\$ ${comissaoValor.toStringAsFixed(2)}',
        ),
      ),
    );
  }
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
                  child: Text(vendedor['nome']),
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

            TextField(const SizedBox(height: 16),

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
