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
  final user = FirebaseAuth.instance.currentUser;

  void aumentarQuantidade(DocumentSnapshot doc) async {
    final data = doc.data() as Map<String, dynamic>;
    final produtoId = data['id'];
    final tamanho = data['tamanho']?.toString();
    final quantidadeAtual = data['quantidade'];

    if (produtoId == null || tamanho == null) return;

    final docEstoque = await FirebaseFirestore.instance
        .collection('estoque')
        .doc(produtoId)
        .get();

    if (!docEstoque.exists) return;

    final estoqueData = docEstoque.data();
    final estoquePorTamanho = estoqueData?['tamanhosComEstoque'] ?? {};

    final estoqueDisponivel = estoquePorTamanho[tamanho];

    if (estoqueDisponivel != null && quantidadeAtual < estoqueDisponivel) {
      await FirebaseFirestore.instance
          .collection('carrinho')
          .doc(doc.id)
          .update({'quantidade': quantidadeAtual + 1});
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Quantidade máxima em estoque atingida!")),
      );
    }
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

  double calcularTotal(List<QueryDocumentSnapshot> docs) {
    return docs.fold(0.0, (total, doc) {
      final data = doc.data() as Map<String, dynamic>;
      return total + (data['preco'] * data['quantidade']);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text("Usuário não autenticado.")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meu Carrinho', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        leading: BackButton(
          color: Colors.white,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => MyHomePage(title: '',)),
            );
          },
        ),
        centerTitle: true,
      ),
      backgroundColor: const Color(0xFFFAF3E0),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('carrinho')
            .where('uid', isEqualTo: user!.uid)
            .snapshots(),
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
                        leading: Image.network(
                          data['imagem'],
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(Icons.image),
                        ),
                        title: Text(data['nome'] ?? ''),
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Total:",
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        Text(
                          "R\$ ${calcularTotal(docs).toStringAsFixed(2)}",
                          style: const TextStyle(fontSize: 18, color: Colors.green),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () async {
                        if (retirante == null || retirante!.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Informe quem vai retirar o pedido!")),
                          );
                          return;
                        }

                        final carrinhoSnapshot = await FirebaseFirestore.instance
                            .collection('carrinho')
                            .where('uid', isEqualTo: user!.uid)
                            .get();

                        if (carrinhoSnapshot.docs.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Carrinho está vazio!")),
                          );
                          return;
                        }

                        final produtos = carrinhoSnapshot.docs.map((doc) {
                          final data = doc.data();
                          return data;
                        }).toList();

                        for (final doc in carrinhoSnapshot.docs) {
                          final data = doc.data();
                          final produtoId = data['id'];
                          final tamanho = data['tamanho'];
                          final quantidade = data['quantidade'];

                          // Atualiza estoque
                          final estoqueRef = FirebaseFirestore.instance.collection('estoque').doc(produtoId);
                          await FirebaseFirestore.instance.runTransaction((transaction) async {
                            final snapshot = await transaction.get(estoqueRef);
                            final estoqueData = snapshot.data() as Map<String, dynamic>;
                            final tamanhos = Map<String, dynamic>.from(estoqueData['tamanhosComEstoque'] ?? {});

                            if (tamanhos.containsKey(tamanho)) {
                              tamanhos[tamanho] = (tamanhos[tamanho] - quantidade).clamp(0, double.infinity);
                              transaction.update(estoqueRef, {'tamanhosComEstoque': tamanhos});
                            }
                          });

                          // Salva em pedidos
                          await FirebaseFirestore.instance.collection('pedidos').add({
                            'retirante': retirante,
                            'nome': data['nome'],
                            'imagem': data['imagem'],
                            'preco': data['preco'],
                            'quantidade': quantidade,
                            'tamanho': tamanho,
                            'timestamp': FieldValue.serverTimestamp(),
                          });

                          // Remove do carrinho
                          await FirebaseFirestore.instance.collection('carrinho').doc(doc.id).delete();
                        }

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Pedido finalizado com sucesso!")),
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
