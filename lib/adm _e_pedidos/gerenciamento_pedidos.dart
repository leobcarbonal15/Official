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
      print("🔔 Salvando notificação para ${emailDoCliente.trim().toLowerCase()}");

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
        // 'forma_pagamento': pedidoData['forma_pagamento'] ?? 'Não informado', // removido
        'email': emailDoCliente.toString().trim().toLowerCase(),
        'lido': false,
      });

      print("✅ Notificação salva com sucesso.");
    } catch (e, stacktrace) {
      print("❌ Erro ao salvar notificação: $e");
      print("📌 Stacktrace: $stacktrace");
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
        title: const Text("Pedidos Realizados", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black, // cor preta no appbar
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

  @override
  void initState() {
    super.initState();
    enviado = widget.pedido.data().toString().contains('enviado') &&
        widget.pedido['enviado'] == true;
  }

  @override
  Widget build(BuildContext context) {
    final pedido = widget.pedido;
    final data = pedido['data'] as Timestamp;
    final produtos = List<Map<String, dynamic>>.from(pedido['produtos']);
    final endereco = pedido.data().toString().contains('endereco')
        ? pedido['endereco'] as Map<String, dynamic>
        : null;

    // NOVO: Pega quem vai retirar o pedido, campo "retirador"
    final retirador = pedido.data().toString().contains('retirante')
        ? pedido['retirante'] as String
        : null;

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
          if (endereco != null)
            ListTile(
              title: Text("Endereço de ${endereco['nomeUsuario'] ?? 'Usuário'}"),
              subtitle: Text(
                '${endereco['logradouro']}, ${endereco['cidade']}, ${endereco['estado']} - ${endereco['cep']}',
              ),
            ),
          // Retirador aparece aqui, se existir
          if (retirador != null)
            ListTile(
              leading: const Icon(Icons.person_pin_circle_outlined),
              title: const Text('Quem vai retirar:'),
              subtitle: Text(retirador),
            ),
          // Forma de pagamento removida

          ...produtos.map((produto) {
            return ListTile(
              leading: Image.network(produto['imagem'], width: 50, height: 50),
              title: Text(produto['nome']),
              subtitle: Text("Quantidade: ${produto['quantidade']}"),
              trailing: Text("R\$ ${produto['preco'].toStringAsFixed(2)}"),
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
                    final email = widget.pedido.data().toString().contains('email')
                        ? widget.pedido['email']
                        : null;

                    if (email != null) {
                      await widget.onMarcarComoEnviado(widget.pedido.id);
                      await widget.onNotificar(email);
                      setState(() {
                        enviado = true;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Produto marcado como separado!")),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Erro: e-mail do cliente não encontrado.")),
                      );
                    }
                  },
            secondary: enviado
                ? const Icon(Icons.check_circle, color: Colors.green)
                : const Icon(Icons.notifications), // troquei para sino
            controlAffinity: ListTileControlAffinity.leading,
          ),
        ],
      ),
    );
  }
}
