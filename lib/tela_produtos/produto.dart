import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TelaProduto extends StatefulWidget {
  final String idEstoque;
  final String nome;
  final double preco;
  final String descricao;
  final List<String> imagens;

  const TelaProduto({
    super.key,
    required this.idEstoque,
    required this.nome,
    required this.preco,
    required this.descricao,
    required this.imagens,
  });

  @override
  State<TelaProduto> createState() => _TelaProdutoState();
}

class _TelaProdutoState extends State<TelaProduto> {
 Map<String, Map<String, int>> variacoesEstoque = {}; // cor → tamanhos → estoque
String? corSelecionada;
String? tamanhoSelecionado;

  bool carregandoEstoque = true;

  int _paginaAtual = 0;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    carregarEstoque();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

 Future<void> carregarEstoque() async {
  try {
    final docRef = FirebaseFirestore.instance.collection('estoque').doc(widget.idEstoque);
    final snapshot = await docRef.get();

    if (!snapshot.exists) return;

    final data = snapshot.data();
    if (data == null || data['variacoes'] == null) return;

    final rawVariacoes = Map<String, dynamic>.from(data['variacoes']);
    final result = <String, Map<String, int>>{};

    for (var cor in rawVariacoes.keys) {
      final tamanhos = Map<String, dynamic>.from(rawVariacoes[cor]);
      result[cor] = {
        for (var t in tamanhos.keys) t: (tamanhos[t] as num).toInt()
      };
    }

    setState(() {
      variacoesEstoque = result;
      carregandoEstoque = false;
    });
  } catch (e) {
    print("Erro ao carregar estoque: $e");
    setState(() => carregandoEstoque = false);
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

  if (corSelecionada == null || tamanhoSelecionado == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Selecione uma cor e um tamanho.")),
    );
    return;
  }

  final estoque = variacoesEstoque[corSelecionada]?[tamanhoSelecionado] ?? 0;
  if (estoque <= 0) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Estoque esgotado para essa variação.")),
    );
    return;
  }

  try {
    final carrinhoRef = FirebaseFirestore.instance.collection('carrinho');

    final existing = await carrinhoRef
        .where('uid', isEqualTo: user.uid)
        .where('id', isEqualTo: widget.idEstoque)
        .where('cor', isEqualTo: corSelecionada)
        .where('tamanho', isEqualTo: tamanhoSelecionado)
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) {
      final docId = existing.docs.first.id;
      final currentQty = existing.docs.first['quantidade'] ?? 1;
      await carrinhoRef.doc(docId).update({'quantidade': currentQty + 1});
    } else {
      await carrinhoRef.add({
        'uid': user.uid,
        'id': widget.idEstoque,
        'nome': widget.nome,
        'imagem': widget.imagens.isNotEmpty ? widget.imagens.first : '',
        'preco': widget.preco,
        'quantidade': 1,
        'cor': corSelecionada,
        'tamanho': tamanhoSelecionado,
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
        title: Text(widget.nome, style: const TextStyle(color: Colors.white)),
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
                        SizedBox(
                          height: 250,
                          child: PageView.builder(
                            controller: _pageController,
                            itemCount: widget.imagens.length,
                            onPageChanged: (index) {
                              setState(() => _paginaAtual = index);
                            },
                            itemBuilder: (context, index) {
                              return Image.network(
                                widget.imagens[index],
                                fit: BoxFit.cover,
                                width: double.infinity,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(Icons.broken_image, size: 100, color: Colors.grey),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            widget.imagens.length,
                            (index) => Container(
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              width: _paginaAtual == index ? 12 : 8,
                              height: _paginaAtual == index ? 12 : 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _paginaAtual == index ? Colors.black : Colors.grey,
                              ),
                            ),
                          ),
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
                     Text(widget.descricao, style: const TextStyle(fontSize: 16)),
const SizedBox(height: 20),

const Text('Selecione a Cor:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
const SizedBox(height: 10),
carregandoEstoque
    ? const Center(child: CircularProgressIndicator())
    : Wrap(
        spacing: 8,
        children: variacoesEstoque.keys.map((cor) {
          final selecionada = cor == corSelecionada;
          return ChoiceChip(
            label: Text(cor),
            selected: selecionada,
            onSelected: (_) {
              setState(() {
                corSelecionada = cor;
                tamanhoSelecionado = null; // resetar tamanho ao mudar cor
              });
            },
            selectedColor: Colors.black,
            backgroundColor: Colors.grey[200],
            labelStyle: TextStyle(
              color: selecionada ? Colors.white : Colors.black,
              fontWeight: FontWeight.bold,
            ),
          );
        }).toList(),
      ),
const SizedBox(height: 20),

if (corSelecionada != null) ...[
  const Text('Tamanhos Disponíveis:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
  const SizedBox(height: 10),
  Wrap(
    spacing: 8,
    children: variacoesEstoque[corSelecionada]!.entries.map((entry) {
      final tamanho = entry.key;
      final estoque = entry.value;
      final selecionado = tamanhoSelecionado == tamanho;

      return ChoiceChip(
        label: Text(estoque > 0 ? "$tamanho - $estoque unid" : "$tamanho - Esgotado"),
        selected: selecionado,
        onSelected: estoque > 0 ? (_) => setState(() => tamanhoSelecionado = tamanho) : null,
        selectedColor: Colors.black,
        backgroundColor: estoque > 0 ? Colors.grey[300] : Colors.grey[200],
        labelStyle: TextStyle(
          color: estoque > 0
              ? (selecionado ? Colors.white : Colors.black)
              : Colors.grey,
          fontWeight: FontWeight.bold,
        ),
        shape: const StadiumBorder(),
      );
    }).toList(),
  ),
],
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
                    onPressed: () => _adicionarAoCarrinho(context),
                    icon: const Icon(Icons.add_shopping_cart, color: Colors.white),
                    label: const Text("Adicionar ao Carrinho", style: TextStyle(fontSize: 16, color: Colors.white)),
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
