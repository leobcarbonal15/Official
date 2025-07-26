import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // Isso é essencial!
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pagamento',
      home: Scaffold(body: Center(child: Text('Tela inicial'))),
    );
  }
}

class TelaPagamentos extends StatefulWidget {
  final List<dynamic> produtos;
  final Map<String, dynamic> endereco;
  final String formaPagamento;

  TelaPagamentos({
    Key? key,
    required this.produtos,
    required this.endereco,
    required this.formaPagamento, required String retirante,
  }) : super(key: key);

  @override
  _TelaPagamentosState createState() => _TelaPagamentosState();
}

class _TelaPagamentosState extends State<TelaPagamentos> {
  Future<Map<String, dynamic>?> _getChavePix() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('chaves_pix')
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs.first.data();
      } else {
        print("Nenhuma chave PIX encontrada.");
        return null;
      }
    } catch (e) {
      print("Erro ao buscar a chave PIX: $e");
      return null;
    }
  }

  Future<void> limparCarrinho() async {
    try {
      final carrinhoRef = FirebaseFirestore.instance.collection('carrinho');
      final snapshot = await carrinhoRef.get();

      for (var doc in snapshot.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      print("Erro ao limpar o carrinho: $e");
    }
  }

  Future<void> salvarPedido(BuildContext context) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final email = user.email?.trim().toLowerCase();
      if (email == null || email.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Erro: Email do usuário não encontrado.")),
        );
        return;
      }

     final pedido = {
  'uid': user.uid,
  'email': email,
  'produtos': widget.produtos,
  'forma_pagamento': widget.formaPagamento,
  'data': Timestamp.now(),
  'enviado': false,
  'cancelado': false,
  'endereco': widget.endereco,
};

      await FirebaseFirestore.instance.collection('pedidos').add(pedido);

      // Atualizar o estoque
      for (var produto in widget.produtos) {
  final produtoId = produto['id'];
  final quantidadeComprada = (produto['quantidade'] ?? 0) as int;
  final tamanhoSelecionado = produto['tamanho'];

  if (produtoId == null || tamanhoSelecionado == null || quantidadeComprada <= 0) {
    print("Dados insuficientes para atualizar o estoque: $produto");
    continue;
  }

  final tamanho = tamanhoSelecionado.toString();
  final docRef = FirebaseFirestore.instance.collection('estoque').doc(produtoId);
  final docSnap = await docRef.get();

  if (docSnap.exists) {
    final data = docSnap.data() as Map<String, dynamic>;
    final estoqueMap = Map<String, dynamic>.from(data['tamanhosComEstoque'] ?? {});

    if (!estoqueMap.containsKey(tamanho)) {
      print("Tamanho $tamanho não encontrado no produto $produtoId.");
      continue;
    }

    final estoqueAtual = (estoqueMap[tamanho] ?? 0) as int;
    final novoEstoque = (estoqueAtual - quantidadeComprada).clamp(0, double.infinity).toInt();

    estoqueMap[tamanho] = novoEstoque;

    print('Atualizando estoque: Produto $produtoId | Tamanho $tamanho | De $estoqueAtual para $novoEstoque');

    await docRef.update({'tamanhosComEstoque': estoqueMap});
  } else {
    print("Documento de estoque $produtoId não encontrado.");
  }
}


      // Criar notificação
      await FirebaseFirestore.instance.collection('notificacoes').add({
        'titulo': 'Pedido realizado',
        'mensagem': 'Seu pedido foi feito com sucesso!',
        'email': email,
        'data': Timestamp.now(),
        'lido': false,
        
      });

      await limparCarrinho();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Pedido salvo e estoque atualizado!")),
      );

      _exibirChavePix(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erro ao salvar o pedido: $e")),
      );
    }
  }

  Future<void> _exibirChavePix(BuildContext context) async {
    Map<String, dynamic>? chaveData = await _getChavePix();

    if (chaveData != null) {
      final chavePix = chaveData['chave'];

      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Chave PIX'),
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("Chave PIX:"),
                const SizedBox(height: 5),
                SelectableText(
                  chavePix,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: chavePix));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text("Chave PIX copiada para a área de transferência!")),
                    );
                  },
                  icon: const Icon(Icons.copy),
                  label: const Text("Copiar chave"),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                ),
              ],
            ),
          );
        },
      );
    } else {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Chave PIX'),
            content: const Text('Chave PIX não cadastrada ou erro ao buscar'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Fechar'),
              ),
            ],
          );
        },
      );
    }
  }
@override
Widget build(BuildContext context) {
  double total = widget.produtos.fold(0.0, (soma, p) {
    return soma + ((p['preco'] ?? 0) * (p['quantidade'] ?? 1));
  });

  return Scaffold(
    appBar: AppBar(
      title: const Text("Pagamento"),
      backgroundColor: Colors.amber.shade700,
    ),
    body: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Forma de Pagamento: ${widget.formaPagamento}",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),

          const Text("Resumo da Compra:",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),

          const SizedBox(height: 10),
          Expanded(
            child: ListView.builder(
              itemCount: widget.produtos.length,
              itemBuilder: (context, index) {
                final p = widget.produtos[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  child: ListTile(
                    leading: p['imagem'] != null
                        ? Image.network(p['imagem'], width: 50, height: 50, fit: BoxFit.cover)
                        : const Icon(Icons.image),
                    title: Text(p['nome'] ?? ''),
                    subtitle: Text("Tamanho: ${p['tamanho']} | Quantidade: ${p['quantidade']}"),
                    trailing: Text("R\$ ${(p['preco'] * p['quantidade']).toStringAsFixed(2)}"),
                  ),
                );
              },
            ),
          ),

          const Divider(thickness: 1.5),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Total:",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text("R\$ ${total.toStringAsFixed(2)}",
                  style: const TextStyle(fontSize: 20, color: Colors.green, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 20),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.yellow.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              "⚠ Após o pagamento via Pix, envie o comprovante pelo WhatsApp para que possamos separar os produtos para retirada!",
              style: TextStyle(fontSize: 16),
            ),
          ),
          const SizedBox(height: 12),

          ElevatedButton.icon(
            onPressed: () => salvarPedido(context),
            icon: const Icon(Icons.check_circle_outline),
            label: const Text("Confirmar Pagamento"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              minimumSize: const Size(double.infinity, 50),
            ),
          ),

          const SizedBox(height: 10),

       
        ],
      ),
    ),
  );
}

}
