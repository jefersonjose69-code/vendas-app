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
  final quantidadeController =
      TextEditingController(text: '1');
  final valorController = TextEditingController();
  final clienteController = TextEditingController();
  final jurosController =
      TextEditingController(text: '0');

  String formaPagamento = 'À vista';
  int parcelas = 1;

  final List<Map<String, dynamic>> itens = [];

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

  double numero(String texto) {
    return double.tryParse(
          texto.replaceAll(',', '.'),
        ) ??
        0;
  }

  int quantidadeAtual() {
    return int.tryParse(
          quantidadeController.text,
        ) ??
        0;
  }

  double calcularSubtotal() {
    double total = 0;

    for (final item in itens) {
      total += item['subtotal'] as double;
    }

    return total;
  }

  double calcularDesconto(double total) {
    if (formaPagamento == 'PIX') {
      return total * 0.10;
    }

    return 0;
  }

  double calcularJuros(double valor) {
    final percentual = numero(jurosController.text);

    return valor * percentual / 100;
  }

  double calcularTotalComJuros() {
    final total = calcularSubtotal();
    final desconto = calcularDesconto(total);
    final valorFinal = total - desconto;
    final juros = calcularJuros(valorFinal);

    return valorFinal + juros;
  }

  double calcularValorParcela() {
    final total = calcularTotalComJuros();

    if (parcelas <= 0) {
      return total;
    }

    return total / parcelas;
  }

  // =========================
  // ADICIONAR PRODUTO
  // =========================

  void adicionarProduto() {
    final produto = produtoController.text.trim();
    final quantidade = quantidadeAtual();
    final valorUnitario = numero(valorController.text);

    if (produto.isEmpty ||
        quantidade <= 0 ||
        valorUnitario <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Informe produto, quantidade e valor.',
          ),
        ),
      );
      return;
    }

    const comissaoPercentual = 1.0;

    final subtotal =
        valorUnitario * quantidade;

    final comissao =
        subtotal * comissaoPercentual / 100;

    setState(() {
      itens.add({
        'produto': produto,
        'quantidade': quantidade,
        'valorUnitario': valorUnitario,
        'subtotal': subtotal,
        'comissaoPercentual':
            comissaoPercentual,
        'comissaoValor': comissao,
      });

      produtoController.clear();
      quantidadeController.text = '1';
      valorController.clear();
    });
  }

  // =========================
  // REMOVER PRODUTO
  // =========================

  void removerProduto(int index) {
    setState(() {
      itens.removeAt(index);
    });
  }

  // =========================
  // CONFIRMAR VENDA
  // =========================

  Future<void> confirmarVenda() async {
    if (vendedorSelecionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Selecione o vendedor.',
          ),
        ),
      );
      return;
    }

    if (itens.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Adicione pelo menos um produto.',
          ),
        ),
      );
      return;
    }

    final cliente = clienteController.text.trim();

    if (formaPagamento == 'Crediário' &&
        cliente.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Informe o nome do cliente.',
          ),
        ),
      );
      return;
    }

    final total = calcularSubtotal();
    final desconto = calcularDesconto(total);
    final valorFinal = total - desconto;

    final percentualJuros =
        numero(jurosController.text);

    final valorJuros =
        calcularJuros(valorFinal);

    final totalComJuros =
        valorFinal + valorJuros;

    final valorParcela =
        calcularValorParcela();

    final confirmado =
        await mostrarConfirmacao(
      total: total,
      desconto: desconto,
      valorFinal: valorFinal,
      percentualJuros: percentualJuros,
      valorJuros: valorJuros,
      totalComJuros: totalComJuros,
      valorParcela: valorParcela,
      cliente: cliente,
    );

    if (!confirmado) {
      return;
    }

    await salvarVenda(
      total: total,
      desconto: desconto,
      valorFinal: valorFinal,
      percentualJuros: percentualJuros,
      totalComJuros: totalComJuros,
      valorParcela: valorParcela,
      cliente: cliente,
    );
  }

  // =========================
  // TELA DE CONFIRMAÇÃO
  // =========================

  Future<bool> mostrarConfirmacao({
    required double total,
    required double desconto,
    required double valorFinal,
    required double percentualJuros,
    required double valorJuros,
    required double totalComJuros,
    required double valorParcela,
    required String cliente,
  }) async {
    final resultado =
        await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.receipt_long),
              SizedBox(width: 8),
              Text('Confirmar venda'),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Produtos',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 10),

                  ...itens.map(
                    (item) {
                      final quantidade =
                          item['quantidade'];

                      final produto =
                          item['produto'];

                      final subtotal =
                          item['subtotal'] as double;

                      return Padding(
                        padding:
                            const EdgeInsets.only(
                          bottom: 8,
                        ),
                        child: Row(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                '$quantidade x $produto',
                              ),
                            ),
                            Text(
                              'R\$ ${subtotal.toStringAsFixed(2)}',
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  const Divider(),

                  _linha(
                    'Subtotal',
                    total,
                  ),

                  if (desconto > 0)
                    _linha(
                      'Desconto PIX',
                      -desconto,
                    ),

                  _linha(
                    'Total',
                    valorFinal,
                    destaque: true,
                  ),

                  if (percentualJuros > 0) ...[
                    _linha(
                      'Juros ($percentualJuros%)',
                      valorJuros,
                    ),
                    _linha(
                      'Total com juros',
                      totalComJuros,
                      destaque: true,
                    ),
                  ],

                  const SizedBox(height: 8),

                  if (parcelas > 1)
                    _linhaTexto(
                      'Parcelamento',
                      '${parcelas}x de R\$ ${valorParcela.toStringAsFixed(2)}',
                    )
                  else
                    _linhaTexto(
                      'Pagamento',
                      formaPagamento,
                    ),

                  if (cliente.isNotEmpty)
                    _linhaTexto(
                      'Cliente',
                      cliente,
                    ),

                  _linhaTexto(
                    'Forma de pagamento',
                    formaPagamento,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Voltar'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context, true);
              },
              icon: const Icon(Icons.check),
              label: const Text(
                'Confirmar venda',
              ),
            ),
          ],
        );
      },
    );

    return resultado ?? false;
  }

  Widget _linha(
    String titulo,
    double valor, {
    bool destaque = false,
  }) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment:
            MainAxisAlignment.spaceBetween,
        children: [
          Text(
            titulo,
            style: TextStyle(
              fontWeight: destaque
                  ? FontWeight.bold
                  : FontWeight.normal,
            ),
          ),
          Text(
            'R\$ ${valor.toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: destaque
                  ? FontWeight.bold
                  : FontWeight.normal,
              fontSize:
                  destaque ? 16 : 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _linhaTexto(
    String titulo,
    String valor,
  ) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            '$titulo: ',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: Text(valor),
          ),
        ],
      ),
    );
  }

  // =========================
  // SALVAR VENDA
  // =========================

  Future<void> salvarVenda({
    required double total,
    required double desconto,
    required double valorFinal,
    required double percentualJuros,
    required double totalComJuros,
    required double valorParcela,
    required String cliente,
  }) async {
    double comissaoTotal = 0;

    for (final item in itens) {
      comissaoTotal +=
          item['comissaoValor'] as double;
    }

    final data =
        DateTime.now().toIso8601String();

    await DatabaseHelper.instance.adicionarVenda(
      vendedorId: vendedorSelecionado!,
      itens: List<Map<String, dynamic>>.from(
        itens,
      ),
      valor: total,
      desconto: desconto,
      valorFinal: valorFinal,
      formaPagamento: formaPagamento,
      parcelas: parcelas,
      cliente: formaPagamento == 'Crediário'
          ? cliente
          : null,
      comissaoPercentual: 1.0,
      comissaoValor: comissaoTotal,
      juros: percentualJuros,
      totalComJuros: totalComJuros,
      valorParcela: valorParcela,
      data: data,
    );

    if (!mounted) return;

    setState(() {
      itens.clear();

      vendedorSelecionado = null;

      formaPagamento = 'À vista';

      parcelas = 1;
    });

    produtoController.clear();
    quantidadeController.text = '1';
    valorController.clear();
    clienteController.clear();
    jurosController.text = '0';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Venda registrada com sucesso! '
          'Comissão: R\$ '
          '${comissaoTotal.toStringAsFixed(2)}',
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
    jurosController.dispose();

    super.dispose();
  }

  // =========================
  // INTERFACE
  // =========================

  @override
  Widget build(BuildContext context) {
    final total = calcularSubtotal();

    final desconto =
        calcularDesconto(total);

    final valorFinal =
        total - desconto;

    final totalComJuros =
        calcularTotalComJuros();

    final valorParcela =
        calcularValorParcela();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nova Venda'),
        centerTitle: true,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),

        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.stretch,

          children: [
            // VENDEDOR
            DropdownButtonFormField<int>(
              value: vendedorSelecionado,

              decoration:
                  const InputDecoration(
                labelText: 'Vendedor',
                border: OutlineInputBorder(),
              ),

              items:
                  vendedores.map((vendedor) {
                return DropdownMenuItem<int>(
                  value:
                      vendedor['id'] as int,

                  child: Text(
                    vendedor['nome']
                        .toString(),
                  ),
                );
              }).toList(),

              onChanged: (valor) {
                setState(() {
                  vendedorSelecionado =
                      valor;
                });
              },
            ),

            const SizedBox(height: 16),

            // PRODUTO
            TextField(
              controller:
                  produtoController,

              decoration:
                  const InputDecoration(
                labelText: 'Produto',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 12),

            // QUANTIDADE + VALOR
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller:
                        quantidadeController,

                    keyboardType:
                        TextInputType.number,

                    decoration:
                        const InputDecoration(
                      labelText:
                          'Quantidade',
                      border:
                          OutlineInputBorder(),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: TextField(
                    controller:
                        valorController,

                    keyboardType:
                        const TextInputType
                            .numberWithOptions(
                      decimal: true,
                    ),

                    decoration:
                        const InputDecoration(
                      labelText:
                          'Valor unitário',
                      prefixText: 'R\$ ',
                      border:
                          OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // BOTÃO ADICIONAR
            ElevatedButton.icon(
              onPressed: adicionarProduto,

              icon:
                  const Icon(Icons.add),

              label: const Text(
                'Adicionar produto',
              ),
            ),

            const SizedBox(height: 20),

            // LISTA DE PRODUTOS
            if (itens.isNotEmpty)
              Card(
                child: Padding(
                  padding:
                      const EdgeInsets.all(12),

                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,

                    children: [
                      const Text(
                        'Produtos da venda',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 10),

                      ...List.generate(
                        itens.length,
                        (index) {
                          final item =
                              itens[index];

                          return ListTile(
                            contentPadding:
                                EdgeInsets.zero,

                            title: Text(
                              item['produto']
                                  .toString(),
                            ),

                            subtitle: Text(
                              '${item['quantidade']} x '
                              'R\$ '
                              '${(item['valorUnitario'] as double).toStringAsFixed(2)}',
                            ),

                            trailing: Row(
                              mainAxisSize:
                                  MainAxisSize.min,

                              children: [
                                Text(
                                  'R\$ '
                                  '${(item['subtotal'] as double).toStringAsFixed(2)}',
                                  style:
                                      const TextStyle(
                                    fontWeight:
                                        FontWeight.bold,
                                  ),
                                ),

                                IconButton(
                                  onPressed: () {
                                    removerProduto(
                                      index,
                                    );
                                  },
                                  icon:
                                      const Icon(
                                    Icons.delete,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),

            if (itens.isNotEmpty)
              const SizedBox(height: 16),

            // FORMA PAGAMENTO
            DropdownButtonFormField<String>(
              value: formaPagamento,

              decoration:
                  const InputDecoration(
                labelText:
                    'Forma de pagamento',
                border:
                    OutlineInputBorder(),
              ),

              items: const [
                DropdownMenuItem(
                  value: 'À vista',
                  child: Text(
                    'À vista',
                  ),
                ),
                DropdownMenuItem(
                  value: 'PIX',
                  child: Text(
                    'PIX - 10% de desconto',
                  ),
                ),
                DropdownMenuItem(
                  value: 'Cartão',
                  child: Text(
                    'Cartão',
                  ),
                ),
                DropdownMenuItem(
                  value: 'Crediário',
                  child: Text(
                    'Crediário',
                  ),
                ),
              ],

              onChanged: (valor) {
                setState(() {
                  formaPagamento =
                      valor!;
                  parcelas = 1;
                });
              },
            ),

            // CLIENTE
            if (formaPagamento ==
                'Crediário') ...[
              const SizedBox(height: 16),

              TextField(
                controller:
                    clienteController,

                decoration:
                    const InputDecoration(
                  labelText:
                      'Nome do cliente',
                  border:
                      OutlineInputBorder(),
                ),
              ),
            ],

            // PARCELAS
            if (formaPagamento ==
                    'Cartão' ||
                formaPagamento ==
                    'Crediário') ...[
              const SizedBox(height: 16),

              DropdownButtonFormField<int>(
                value: parcelas,

                decoration:
                    const InputDecoration(
                  labelText:
                      'Número de parcelas',
                  border:
                      OutlineInputBorder(),
                ),

                items:
                    List.generate(
                  12,
                  (index) {
                    final numero =
                        index + 1;

                    return DropdownMenuItem(
                      value: numero,
                      child: Text(
                        '${numero}x',
                      ),
                    );
                  },
                ),

                onChanged: (valor) {
                  setState(() {
                    parcelas =
                        valor!;
                  });
                },
              ),

              const SizedBox(height: 16),

              // JUROS
              TextField(
                controller:
                    jurosController,

                keyboardType:
                    const TextInputType
                        .numberWithOptions(
                  decimal: true,
                ),

                decoration:
                    const InputDecoration(
                  labelText:
                      'Juros (%)',
                  suffixText: '%',
                  border:
                      OutlineInputBorder(),
                ),

                onChanged: (_) {
                  setState(() {});
                },
              ),
            ],

            const SizedBox(height: 20),

            // RESUMO
            if (itens.isNotEmpty)
              Card(
                child: Padding(
                  padding:
                      const EdgeInsets.all(16),

                  child: Column(
                    children: [
                      _linha(
                        'Subtotal',
                        total,
                      ),

                      if (desconto > 0)
                        _linha(
                          'Desconto PIX',
                          -desconto,
                        ),

                      _linha(
                        'Total',
                        valorFinal,
                        destaque: true,
                      ),

                      if (numero(
                            jurosController
                                .text,
                          ) >
                          0) ...[
                        _linha(
                          'Total com juros',
                          totalComJuros,
                          destaque: true,
                        ),
                      ],

                      if (parcelas > 1)
                        _linhaTexto(
                          'Parcelas',
                          '${parcelas}x de R\$ '
                          '${valorParcela.toStringAsFixed(2)}',
                        ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 24),

            // CONFIRMAR
            ElevatedButton.icon(
              onPressed:
                  confirmarVenda,

              icon: const Icon(
                Icons.check_circle,
              ),

              label: const Text(
                'CONFERIR E CONFIRMAR VENDA',
              ),

              style:
                  ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(
                  vertical: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
