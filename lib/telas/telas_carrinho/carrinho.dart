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
  Map<String, bool> expandirObservacao = {};
  Map<String, String> observacoes = {};

  Future<int> _obterEstoqueDisponivel(String produtoId, String cor, String tamanho) async {
    final docEstoque = await FirebaseFirestore.instance.collection('estoque').doc(produtoId).get();

    if (!docEstoque.exists) return 0;

    final data = docEstoque.data();
    if (data == null || data['variacoes'] == null) return 0;

    final Map<String, dynamic> variacoes = Map<String, dynamic>.from(data['variacoes']);

    if (!variacoes.containsKey(cor)) return 0;

    final Map<String, dynamic> tamanhos = Map<String, dynamic>.from(variacoes[cor]);
    final estoque = tamanhos[tamanho];

    if (estoque == null) return 0;

    return (estoque as num).toInt();
  }

  void aumentarQuantidade(DocumentSnapshot doc) async {
    final data = doc.data() as Map<String, dynamic>;
    final produtoId = data['id'] as String?;
    final cor = data['cor'] as String?;
    final tamanho = data['tamanho'] as String?;
    final quantidadeAtual = (data['quantidade'] as num?)?.toInt() ?? 1;

    if (produtoId == null || cor == null || tamanho == null) return;

    final estoqueDisponivel = await _obterEstoqueDisponivel(produtoId, cor, tamanho);

    if (quantidadeAtual < estoqueDisponivel) {
      await FirebaseFirestore.instance.collection('carrinho').doc(doc.id).update({'quantidade': quantidadeAtual + 1});
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Quantidade máxima em estoque atingida!")),
      );
    }
  }

  void diminuirQuantidade(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final quantidadeAtual = (data['quantidade'] as num?)?.toInt() ?? 1;

    if (quantidadeAtual > 1) {
      FirebaseFirestore.instance.collection('carrinho').doc(doc.id).update({'quantidade': quantidadeAtual - 1});
    }
  }

  void removerItem(DocumentSnapshot doc) {
    FirebaseFirestore.instance.collection('carrinho').doc(doc.id).delete();
  }

  double calcularTotal(List<QueryDocumentSnapshot> docs) {
    return docs.fold(0.0, (total, doc) {
      final data = doc.data() as Map<String, dynamic>;
      final preco = (data['preco'] as num?)?.toDouble() ?? 0.0;
      final quantidade = (data['quantidade'] as num?)?.toInt() ?? 0;
      return total + preco * quantidade;
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
              MaterialPageRoute(builder: (context) => MyHomePage(title: '')),
            );
          },
        ),
        centerTitle: true,
      ),
      backgroundColor: const Color(0xFFFAF3E0),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('carrinho').where('uid', isEqualTo: user!.uid).snapshots(),
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
                      child: Column(
                        children: [
                          ListTile(
                            leading: Image.network(
                              data['imagem'] ?? '',
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(Icons.image),
                            ),
                            title: Text(data['nome'] ?? ''),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("R\$ ${((data['preco'] as num?)?.toDouble() ?? 0.0).toStringAsFixed(2)}"),
                                Text("Cor: ${data['cor'] ?? '-'}"),
                                Text("Tamanho: ${data['tamanho'] ?? '-'}"),
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
                          ExpansionTile(
                            title: const Text("Adicionar Observação"),
                            leading: const Icon(Icons.edit_note),
                            initiallyExpanded: expandirObservacao[doc.id] ?? false,
                            onExpansionChanged: (expanded) {
                              setState(() {
                                expandirObservacao[doc.id] = expanded;
                              });
                            },
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                child: TextField(
                                  onChanged: (value) {
                                    observacoes[doc.id] = value;
                                  },
                                  controller: TextEditingController(text: observacoes[doc.id] ?? ''),
                                  maxLines: 3,
                                  decoration: const InputDecoration(
                                    hintText: 'Ex: camisa azul com botão preto',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
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

                        // Verificação de estoque para cada item
                        bool estoqueOk = true;
                        List<String> errosEstoque = [];

                        for (var doc in carrinhoSnapshot.docs) {
                          final data = doc.data();
                          final produtoId = data['id'] as String?;
                          final cor = data['cor'] as String?;
                          final tamanho = data['tamanho'] as String?;
                          final quantidade = (data['quantidade'] as num?)?.toInt() ?? 0;

                          if (produtoId == null || cor == null || tamanho == null) {
                            errosEstoque.add("${data['nome']} (dados incompletos)");
                            estoqueOk = false;
                            continue;
                          }

                          final disponivel = await _obterEstoqueDisponivel(produtoId, cor, tamanho);

                          if (disponivel < quantidade) {
                            errosEstoque.add("${data['nome']} (estoque: $disponivel, solicitado: $quantidade)");
                            estoqueOk = false;
                          }
                        }

                        if (!estoqueOk) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                "Produtos com estoque insuficiente:\n${errosEstoque.join('\n')}",
                              ),
                              backgroundColor: Colors.redAccent,
                              duration: const Duration(seconds: 6),
                            ),
                          );
                          return;
                        }

                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text("Confirmar Pedido"),
                            content: const Text(
                                "Seu pedido será separado e estará disponível para retirada na loja. Deseja continuar?"),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text("Cancelar"),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text("Continuar"),
                              ),
                            ],
                          ),
                        );

                        if (confirm != true) return;

                        final produtos = carrinhoSnapshot.docs.map((doc) {
                          final data = doc.data();
                          return {
                            'id': data['id'],
                            'nome': data['nome'],
                            'imagem': data['imagem'],
                            'preco': data['preco'],
                            'quantidade': data['quantidade'],
                            'cor': data['cor'],
                            'tamanho': data['tamanho'],
                            'observacao': observacoes[doc.id] ?? '',
                            'retirante': retirante,
                          };
                        }).toList();

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TelaPagamentos(
                              produtos: produtos,
                              retirante: retirante!,
                              endereco: {},
                              formaPagamento: '',
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.shopping_cart_checkout),
                      label: const Text("Confirmar Compra"),
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
