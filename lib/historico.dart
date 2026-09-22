import 'package:flutter/material.dart';
import 'database.dart';

class HistoricoPage extends StatefulWidget {
  const HistoricoPage({super.key});

  @override
  State<HistoricoPage> createState() => _HistoricoPageState();
}

class _HistoricoPageState extends State<HistoricoPage> {
  List<Map<String, dynamic>> vendas = [];
  bool carregando = true;

  @override
  void initState() {
    super.initState();
    carregarVendas();
  }

  Future<void> carregarVendas() async {
    final dados =
        await DatabaseHelper.instance.listarVendas();

    if (!mounted) return;

    setState(() {
      vendas = dados;
      carregando = false;
    });
  }

  String dinheiro(dynamic valor) {
    final numero = valor is num
        ? valor.toDouble()
        : double.tryParse(
              valor.toString().replaceAll(',', '.'),
            ) ??
            0;

    return 'R\$ ${numero.toStringAsFixed(2)}';
  }

  String dataFormatada(String data) {
    try {
      final date = DateTime.parse(data);

      final dia =
          date.day.toString().padLeft(2, '0');
      final mes =
          date.month.toString().padLeft(2, '0');
      final ano = date.year.toString();

      final hora =
          date.hour.toString().padLeft(2, '0');
      final minuto =
          date.minute.toString().padLeft(2, '0');

      return '$dia/$mes/$ano às $hora:$minuto';
    } catch (_) {
      return data;
    }
  }

  Future<String> nomeVendedor(int id) async {
    final vendedores =
        await DatabaseHelper.instance.listarVendedores();

    final encontrado = vendedores.where(
      (v) => v['id'] == id,
    );

    if (encontrado.isEmpty) {
      return 'Vendedor não encontrado';
    }

    return encontrado.first['nome'].toString();
  }

  Future<void> abrirDetalhes(
    Map<String, dynamic> venda,
  ) async {
    final vendaId = venda['id'] as int;

    final itens =
        await DatabaseHelper.instance
            .listarItensVenda(vendaId);

    final vendedor = await nomeVendedor(
      venda['vendedor_id'] as int,
    );

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            'Venda #$vendaId',
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    'Vendedor: $vendedor',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    'Data: ${dataFormatada(venda['data'].toString())}',
                  ),

                  if (venda['cliente'] != null &&
                      venda['cliente']
                          .toString()
                          .isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Cliente: ${venda['cliente']}',
                    ),
                  ],

                  const Divider(height: 24),

                  const Text(
                    'Produtos',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  if (itens.isEmpty)
                    const Text(
                      'Nenhum item encontrado.',
                    )
                  else
                    ...itens.map(
                      (item) {
                        final quantidade =
                            item['quantidade'];

                        final produto =
                            item['produto'];

                        final valorUnitario =
                            item['valor_unitario'];

                        final subtotal =
                            item['subtotal'];

                        return Card(
                          child: Padding(
                            padding:
                                const EdgeInsets.all(10),
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  produto.toString(),
                                  style:
                                      const TextStyle(
                                    fontWeight:
                                        FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '$quantidade x '
                                  '${dinheiro(valorUnitario)}',
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Subtotal: '
                                  '${dinheiro(subtotal)}',
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                  const Divider(height: 24),

                  _linha(
                    'Subtotal',
                    dinheiro(venda['valor']),
                  ),

                  if ((venda['desconto'] as num) > 0)
                    _linha(
                      'Desconto',
                      dinheiro(
                        venda['desconto'],
                      ),
                    ),

                  _linha(
                    'Total',
                    dinheiro(
                      venda['valor_final'],
                    ),
                    destaque: true,
                  ),

                  if ((venda['juros'] as num) > 0) ...[
                    _linha(
                      'Juros',
                      '${venda['juros']}%',
                    ),
                    _linha(
                      'Total com juros',
                      dinheiro(
                        venda['total_com_juros'],
                      ),
                      destaque: true,
                    ),
                  ],

                  const SizedBox(height: 6),

                  _linha(
                    'Pagamento',
                    venda['forma_pagamento']
                        .toString(),
                  ),

                  if ((venda['parcelas'] as int) > 1)
                    _linha(
                      'Parcelas',
                      '${venda['parcelas']}x de '
                      '${dinheiro(venda['valor_parcela'])}',
                    ),

                  const SizedBox(height: 6),

                  _linha(
                    'Comissão',
                    dinheiro(
                      venda['comissao_valor'],
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Fechar'),
            ),
          ],
        );
      },
    );
  }

  Widget _linha(
    String titulo,
    String valor, {
    bool destaque = false,
  }) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(vertical: 4),
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
            valor,
            style: TextStyle(
              fontWeight: destaque
                  ? FontWeight.bold
                  : FontWeight.normal,
              fontSize: destaque ? 16 : 14,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Histórico de Vendas',
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                carregando = true;
              });

              carregarVendas();
            },
            icon: const Icon(
              Icons.refresh,
            ),
          ),
        ],
      ),

      body: carregando
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : vendas.isEmpty
              ? const Center(
                  child: Text(
                    'Nenhuma venda registrada.',
                    style: TextStyle(
                      fontSize: 16,
                    ),
                  ),
                )
              : ListView.builder(
                  padding:
                      const EdgeInsets.all(12),
                  itemCount: vendas.length,
                  itemBuilder:
                      (context, index) {
                    final venda =
                        vendas[index];

                    final vendaId =
                        venda['id'];

                    final total =
                        venda['total_com_juros'] ??
                            venda['valor_final'];

                    return Card(
                      child: ListTile(
                        leading:
                            const CircleAvatar(
                          child: Icon(
                            Icons.receipt_long,
                          ),
                        ),

                        title: Text(
                          'Venda #$vendaId',
                          style:
                              const TextStyle(
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),

                        subtitle: Text(
                          '${venda['forma_pagamento']} • '
                          '${dataFormatada(venda['data'].toString())}',
                        ),

                        trailing: Text(
                          dinheiro(total),
                          style:
                              const TextStyle(
                            fontWeight:
                                FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),

                        onTap: () {
                          abrirDetalhes(
                            venda,
                          );
                        },
                      ),
                    );
                  },
                ),
    );
  }
}
