import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class TelaGerenciamentoPedidos extends StatelessWidget {
  const TelaGerenciamentoPedidos({super.key});

  void excluirPedido(BuildContext context, String pedidoId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Excluir Pedido"),
        content: const Text("Tem certeza que deseja excluir este pedido?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar"),
          ),
          TextButton(
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('pedidos')
                  .doc(pedidoId)
                  .delete();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Pedido excluído com sucesso.")),
              );
            },
            child: const Text("Excluir", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> registrarNotificacao(
      DocumentSnapshot pedidoSnapshot, String emailDoCliente) async {
    try {
      final pedidoData = pedidoSnapshot.data() as Map<String, dynamic>? ?? {};
      final produtos = pedidoData['produtos'] as List<dynamic>? ?? [];
      final produto = produtos.isNotEmpty && produtos[0] is Map<String, dynamic>
          ? produtos[0] as Map<String, dynamic>
          : {};

      await FirebaseFirestore.instance.collection('notificacoes').add({
        'titulo': 'Seu pedido foi separado!',
        'mensagem': 'O produto ${produto['nome'] ?? 'Produto'} foi separado!',
        'nome': produto['nome'] ?? 'Produto',
        'data': Timestamp.now(),
        'pedidoId': pedidoSnapshot.id,
        'produtos': produtos,
        'endereco': pedidoData['endereco'] ?? {},
        'email': emailDoCliente.trim().toLowerCase(),
        'lido': false,
      });
    } catch (e) {
      print("Erro ao salvar notificação: $e");
    }
  }

  Future<void> marcarPedidoComoEnviado(String pedidoId) async {
    await FirebaseFirestore.instance
        .collection('pedidos')
        .doc(pedidoId)
        .update({'enviado': true});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Pedidos Realizados",
            style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      backgroundColor: const Color(0xFFFAF3E0),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('pedidos')
            .orderBy('data', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final pedidos = snapshot.data!.docs;

          if (pedidos.isEmpty) {
            return const Center(child: Text("Nenhum pedido encontrado."));
          }

          return ListView.builder(
            itemCount: pedidos.length,
            itemBuilder: (context, index) {
              final pedido = pedidos[index];
              return PedidoCard(
                pedido: pedido,
                index: index,
                onExcluir: () => excluirPedido(context, pedido.id),
                onNotificar: (email) => registrarNotificacao(pedido, email),
                onMarcarComoEnviado: marcarPedidoComoEnviado,
              );
            },
          );
        },
      ),
    );
  }
}

class PedidoCard extends StatefulWidget {
  final QueryDocumentSnapshot pedido;
  final int index;
  final VoidCallback onExcluir;
  final Future<void> Function(String email) onNotificar;
  final Future<void> Function(String pedidoId) onMarcarComoEnviado;
  

  const PedidoCard({
    super.key,
    required this.pedido,
    required this.index,
    required this.onExcluir,
    required this.onNotificar,
    required this.onMarcarComoEnviado,
  });

  @override
  State<PedidoCard> createState() => _PedidoCardState();
  
}

class _PedidoCardState extends State<PedidoCard> {
  late bool enviado;
  late bool cancelado;

  @override
  void initState() {
    super.initState();
    final data = widget.pedido.data() as Map<String, dynamic>;
    enviado = data['enviado'] == true;
    cancelado = data['cancelado'] == true;
  }

  Future<void> devolverProdutosAoEstoque(List<dynamic> produtos) async {
    final firestore = FirebaseFirestore.instance;

    for (var produto in produtos) {
      if (produto is! Map<String, dynamic>) continue;

      final produtoId = produto['id'];
      final quantidade = produto['quantidade'] ?? 0;
      final tamanho = produto['tamanho']?.toString();
      final cor = produto['cor']?.toString();

      if (produtoId == null || tamanho == null || cor == null) continue;

      final docRef = firestore.collection('estoque').doc(produtoId);
      final docSnap = await docRef.get();

      if (!docSnap.exists) continue;

      final dados = docSnap.data() as Map<String, dynamic>;
      final variacoes = Map<String, dynamic>.from(dados['variacoes'] ?? {});

      if (!variacoes.containsKey(cor)) continue;

      final tamanhosMap = Map<String, dynamic>.from(variacoes[cor]);
      final estoqueAtual = (tamanhosMap[tamanho] ?? 0) as int;
      tamanhosMap[tamanho] = estoqueAtual + quantidade;

      variacoes[cor] = tamanhosMap;

      await docRef.update({'variacoes': variacoes});
    }
  }

  Future<void> cancelarPedido(DocumentSnapshot pedido) async {
    final pedidoId = pedido.id;
    final pedidoData = widget.pedido.data() as Map<String, dynamic>;
    final produtos = pedidoData['produtos'] as List<dynamic>? ?? [];

    await FirebaseFirestore.instance
        .collection('pedidos')
        .doc(pedidoId)
        .update({'cancelado': true});

    await devolverProdutosAoEstoque(produtos);
  }

 @override
Widget build(BuildContext context) {
  final pedido = widget.pedido;
  final pedidoData = pedido.data() as Map<String, dynamic>;
  final data = pedido['data'] as Timestamp;
  final produtos = List<Map<String, dynamic>>.from(pedido['produtos']);
final retirante = produtos.isNotEmpty
    ? (produtos[0]['retirante']?.toString().trim() ?? 'Não informado')
    : 'Não informado';


  return Card(
    margin: const EdgeInsets.all(12),
    child: ExpansionTile(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              "Pedido ${widget.index + 1} - ${data.toDate().toString().substring(0, 16)}",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: widget.onExcluir,
          ),
        ],
      ),
      children: [
       ListTile(
  leading: const Icon(Icons.person_pin_circle_outlined),
  title: const Text('Quem vai retirar:'),
  subtitle: Text(retirante),
),



          ...produtos.map((produto) {
            final nome = produto['nome'] ?? 'Produto';
            final quantidade = produto['quantidade'] ?? 0;
            final preco = produto['preco'] ?? 0.0;
            final imagem = produto['imagem'] ?? '';
            final tamanho = produto['tamanho']?.toString() ?? 'N/A';
            final cor = produto['cor']?.toString() ?? '';
            final observacao = produto['observacao']?.toString()?.trim();

            return ListTile(
              leading: imagem.isNotEmpty
                  ? Image.network(imagem,
                      width: 50, height: 50, fit: BoxFit.cover)
                  : const Icon(Icons.image_not_supported),
              title: Text(nome),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Quantidade: $quantidade"),
                  Text(
                      "Tamanho: $tamanho ${cor.isNotEmpty ? ' | Cor: $cor' : ''}"),
                  if (observacao != null && observacao.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        "Observação: $observacao",
                        style: const TextStyle(fontStyle: FontStyle.italic),
                      ),
                    ),
                ],
              ),
              trailing: Text("R\$ ${preco.toStringAsFixed(2)}"),
            );
          }).toList(),
          CheckboxListTile(
            title: Text(
              enviado ? "Produto Separado ✔" : "Produto Separado",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: enviado ? Colors.green : Colors.black,
              ),
            ),
            value: enviado,
            activeColor: Colors.green,
            checkColor: Colors.white,
            onChanged: enviado
                ? null
                : (value) async {
                    final email = pedido.data().toString().contains('email')
                        ? pedido['email']
                        : null;

                    if (email != null) {
                      await widget.onMarcarComoEnviado(pedido.id);
                      await widget.onNotificar(email);
                      setState(() {
                        enviado = true;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text("Produto marcado como separado!")),
                      );
                    }
                  },
            secondary: enviado
                ? const Icon(Icons.check_circle, color: Colors.green)
                : const Icon(Icons.notifications),
            controlAffinity: ListTileControlAffinity.leading,
          ),
          CheckboxListTile(
            title: Text(
              cancelado ? "Pedido Cancelado ✔" : "Cancelar Pedido",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: cancelado ? Colors.red : Colors.black,
              ),
            ),
            value: cancelado,
            activeColor: Colors.red,
            checkColor: Colors.white,
            onChanged: cancelado
                ? null
                : (value) async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text("Confirmar Cancelamento"),
                        content: const Text(
                            "Tem certeza que deseja cancelar este pedido? Isso devolverá os produtos ao estoque."),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text("Cancelar"),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text(
                              "Confirmar",
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true) {
                      await cancelarPedido(pedido);
                      setState(() {
                        cancelado = true;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text(
                                "Pedido cancelado e produtos devolvidos ao estoque.")),
                      );
                    }
                  },
            secondary: cancelado
                ? const Icon(Icons.cancel, color: Colors.red)
                : const Icon(Icons.cancel_outlined),
            controlAffinity: ListTileControlAffinity.leading,
          ),
        ],
      ),
    );
  }
}
