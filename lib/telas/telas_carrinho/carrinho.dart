// ... suas importações continuam iguais
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:myapp/main.dart';
import 'package:myapp/pagamen/tela_pagamentos.dart';

class CarrinhoMLApp extends StatelessWidget {
  const CarrinhoMLApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Carrinho ML',
      theme: ThemeData(primarySwatch: Colors.amber),
      home: const CarrinhoMLPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class CarrinhoMLPage extends StatefulWidget {
  const CarrinhoMLPage({super.key});

  @override
  State<CarrinhoMLPage> createState() => _CarrinhoMLPageState();
}

class _CarrinhoMLPageState extends State<CarrinhoMLPage> {
  String? retirante;

  void aumentarQuantidade(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    FirebaseFirestore.instance
        .collection('carrinho')
        .doc(doc.id)
        .update({'quantidade': data['quantidade'] + 1});
  }

  void diminuirQuantidade(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    if (data['quantidade'] > 1) {
      FirebaseFirestore.instance
          .collection('carrinho')
          .doc(doc.id)
          .update({'quantidade': data['quantidade'] - 1});
    }
  }

  void removerItem(DocumentSnapshot doc) {
    FirebaseFirestore.instance.collection('carrinho').doc(doc.id).delete();
  }

  Future<void> finalizarCompra(BuildContext context) async {
    final carrinhoSnapshot =
        await FirebaseFirestore.instance.collection('carrinho').get();

    if (carrinhoSnapshot.docs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Carrinho está vazio!")),
      );
      return;
    }

    if (retirante == null || retirante!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Informe quem vai retirar o pedido!")),
      );
      return;
    }

    final produtos = carrinhoSnapshot.docs.map((doc) => doc.data()).toList();
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Usuário não autenticado!")),
      );
      return;
    }

    final emailUsuario = user.email;

    // ✅ Atualizar estatísticas
    for (var produto in produtos) {
      final nomeProduto = produto['nome'];
      final quantidadeVendida = produto['quantidade'];

      final statRef =
          FirebaseFirestore.instance.collection('estatisticas').doc(nomeProduto);

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final statSnapshot = await transaction.get(statRef);

        if (statSnapshot.exists) {
          final data = statSnapshot.data()!;
          final novaQuantidade = (data['quantidade_total'] ?? 0) + quantidadeVendida;

          transaction.update(statRef, {
            'quantidade_total': novaQuantidade,
            'ultima_venda': Timestamp.now(),
          });
        } else {
          transaction.set(statRef, {
            'nome': nomeProduto,
            'quantidade_total': quantidadeVendida,
            'ultima_venda': Timestamp.now(),
          });
        }
      });
    }

    await FirebaseFirestore.instance.collection('pedidos').add({
      'data': Timestamp.now(),
      'produtos': produtos,
      'retirante': retirante,
      'email': emailUsuario,
    });

    for (var doc in carrinhoSnapshot.docs) {
      await doc.reference.delete();
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Compra finalizada com sucesso!")),
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TelaPagamentos(
          produtos: produtos,
          endereco: {'retirante': retirante},
          formaPagamento: "Retirada",
        ),
      ),
    );
  }

  double calcularTotal(List<QueryDocumentSnapshot> docs) {
    return docs.fold(0.0, (total, doc) {
      final data = doc.data() as Map<String, dynamic>;
      return total + (data['preco'] * data['quantidade']);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meu Carrinho', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black, // 🟩 Cor preta
        leading: BackButton(
          color: Colors.white,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => MyApp()),
            );
          },
        ),
        centerTitle: true,
      ),
      backgroundColor: const Color(0xFFFAF3E0),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('carrinho').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data() as Map<String, dynamic>;

                    return Card(
                      margin: const EdgeInsets.all(10),
                      child: ListTile(
                        leading: Image.network(data['imagem'],
                            width: 60, height: 60, fit: BoxFit.cover),
                        title: Text(data['nome']),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("R\$ ${data['preco'].toStringAsFixed(2)}"),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove_circle_outline),
                                  onPressed: () => diminuirQuantidade(doc),
                                ),
                                Text('${data['quantidade']}'),
                                IconButton(
                                  icon: const Icon(Icons.add_circle_outline),
                                  onPressed: () => aumentarQuantidade(doc),
                                ),
                              ],
                            ),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => removerItem(doc),
                        ),
                      ),
                    );
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  border: Border(top: BorderSide(color: Colors.grey.shade300)),
                ),
                child: Column(
                  children: [
                    // Campo de retirada
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'Nome de quem vai retirar o pedido',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        setState(() {
                          retirante = value;
                        });
                      },
                    ),
                    const SizedBox(height: 12),

                    // Total
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Total: ",
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        Text(
                          "R\$ ${calcularTotal(docs).toStringAsFixed(2)}",
                          style: const TextStyle(
                              fontSize: 18, color: Colors.green),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Botão Finalizar
                 ElevatedButton.icon(
  onPressed: () {
    if (retirante == null || retirante!.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Informe quem vai retirar o pedido!")),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Pedido'),
        content: Text(
          'Deseja realmente finalizar o pedido? Iremos separar seu pedido para pagamento e retirada na loja',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.check),
            label: const Text('Confirmar'),
            onPressed: () {
              Navigator.of(context).pop(); // Fecha o diálogo
              finalizarCompra(context);   // Chama a função
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
          ),
        ],
      ),
    );
  },
  icon: const Icon(Icons.shopping_cart_checkout),
  label: const Text("Finalizar Compra"),
  style: ElevatedButton.styleFrom(
    minimumSize: const Size(double.infinity, 50),
    backgroundColor: Colors.amber.shade700,
    textStyle: const TextStyle(fontSize: 16),
  ),
),

                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}