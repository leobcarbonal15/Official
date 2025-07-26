import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // necessário

class TelaProduto extends StatefulWidget {
  final String idEstoque;
  final String nome;
  final double preco;
  final String descricao;
  final String imagemUrl;

  const TelaProduto({
    super.key,
    required this.idEstoque,
    required this.nome,
    required this.preco,
    required this.descricao,
    required this.imagemUrl,
  });

  @override
  State<TelaProduto> createState() => _TelaProdutoState();
}

class _TelaProdutoState extends State<TelaProduto> {
  Map<String, int> tamanhosEstoque = {};
  String tipoTamanho = '';
  bool carregandoEstoque = true;
  String? tamanhoSelecionado;

  @override
  void initState() {
    super.initState();
    carregarEstoque();
  }

  Future<void> carregarEstoque() async {
  try {
    final docRef = FirebaseFirestore.instance.collection('estoque').doc(widget.idEstoque);
    final snapshot = await docRef.get();

    if (!snapshot.exists) {
      setState(() {
        carregandoEstoque = false;
      });
      return;
    }

    final data = snapshot.data();
    if (data == null || data['tamanhosComEstoque'] == null) {
      setState(() {
        tamanhosEstoque = {};
        carregandoEstoque = false;
      });
      return;
    }

    final rawMap = Map<String, dynamic>.from(data['tamanhosComEstoque']);
    final estoqueMap = {
      for (var entry in rawMap.entries) entry.key: (entry.value as num).toInt()
    };

    setState(() {
      tipoTamanho = data['tipoTamanho'] ?? '';
      tamanhosEstoque = estoqueMap;
      carregandoEstoque = false;
    });
  } catch (e) {
    print("Erro ao carregar estoque: $e");
    setState(() {
      tamanhosEstoque = {};
      carregandoEstoque = false;
    });
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar estoque: $e')),
      );
    }
  }
}


void _adicionarAoCarrinho(BuildContext context) async {
  final user = FirebaseAuth.instance.currentUser;

  if (user == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Você precisa estar logado.")),
    );
    return;
  }

  if (tamanhoSelecionado == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Selecione um tamanho antes de adicionar.")),
    );
    return;
  }

  if (tamanhosEstoque[tamanhoSelecionado]! <= 0) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Estoque esgotado para esse tamanho.")),
    );
    return;
  }

  try {
    final carrinhoRef = FirebaseFirestore.instance.collection('carrinho');

    // Verifica se já existe esse item no carrinho
    final existing = await carrinhoRef
        .where('uid', isEqualTo: user.uid)
        .where('id', isEqualTo: widget.idEstoque)
        .where('tamanho', isEqualTo: tamanhoSelecionado)
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) {
      // Já existe, então só aumenta a quantidade
      final docId = existing.docs.first.id;
      final currentQty = existing.docs.first['quantidade'] ?? 1;
      await carrinhoRef.doc(docId).update({'quantidade': currentQty + 1});
    } else {
      // Não existe, cria novo item
      await carrinhoRef.add({
        'uid': user.uid,
        'id': widget.idEstoque,
        'nome': widget.nome,
        'imagem': widget.imagemUrl,
        'preco': widget.preco,
        'quantidade': 1,
        'tamanho': tamanhoSelecionado.toString(),
      });
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Produto adicionado ao carrinho!")),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Erro ao adicionar: $e")),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF3E0),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 0, 0, 0),
        title: Text(
          widget.nome,
          style: const TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        color: const Color(0xFFFAF3E0),
        child: Center(
          child: Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16.0),
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: const Color.fromARGB(255, 0, 0, 0).withOpacity(0.2),
                  spreadRadius: 2,
                  blurRadius: 5,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Image.network(
                          widget.imagemUrl,
                          width: double.infinity,
                          height: 250,
                          fit: BoxFit.cover,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          widget.nome,
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Color.fromARGB(255, 0, 0, 0),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'R\$ ${widget.preco.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 22,
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          widget.descricao,
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Tamanhos Disponíveis:',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        carregandoEstoque
                            ? const Center(child: CircularProgressIndicator())
                            : tamanhosEstoque.isEmpty
                                ? const Text("Sem informações de estoque.")
                                :Wrap(
  spacing: 8,
  children: tamanhosEstoque.entries.map((entry) {
    final tamanho = entry.key;
    final estoque = entry.value;
    final bool selecionado = tamanhoSelecionado == tamanho;

    return ChoiceChip(
      label: Text(
        estoque > 0 ? "$tamanho - $estoque unid" : "$tamanho - Esgotado",
      ),
      selected: selecionado,
      onSelected: estoque > 0
          ? (_) {
              setState(() {
                tamanhoSelecionado = tamanho;
              });
            }
          : null,
      selectedColor: Colors.black,
      backgroundColor: estoque > 0 ? Colors.grey[300] : Colors.grey[200],
      labelStyle: TextStyle(
        color: estoque > 0
            ? (selecionado ? Colors.white : Colors.black)
            : Colors.grey,
        fontWeight: FontWeight.bold,
      ),
      shape: StadiumBorder(
        side: BorderSide(
          color: estoque > 0 ? Colors.black : Colors.grey,
        ),
      ),
    );
  }).toList(),
),

                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 5, 5, 5),
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                    ),
                    onPressed: () {
                      _adicionarAoCarrinho(context);
                    },
                    icon: const Icon(Icons.add_shopping_cart, color: Colors.white),
                    label: const Text(
                      "Adicionar ao Carrinho",
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
