import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:myapp/adm%20_e_pedidos/gerenciamento_produtos.dart';
import 'package:firebase_auth/firebase_auth.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // Isso é essencial!
  runApp(MyApp());
}

class TelaPagamentos extends StatefulWidget {
  final List<dynamic> produtos;
  final Map<String, dynamic> endereco;
  final String formaPagamento;

  TelaPagamentos({
    Key? key,
    required this.produtos,
    required this.endereco,
    required this.formaPagamento,
  }) : super(key: key);

  @override
  _TelaPagamentosState createState() => _TelaPagamentosState();
}

class _TelaPagamentosState extends State<TelaPagamentos> {
  // Buscar a chave PIX
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

  // Limpar a coleção 'carrinho'
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

  // Salvar pedido e limpar carrinho
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
      'email': email, // ✅ Adicionado aqui
      'produtos': widget.produtos,
      'endereco': widget.endereco,
      'forma_pagamento': widget.formaPagamento,
      'data': Timestamp.now(),
    };

    await FirebaseFirestore.instance.collection('pedidos').add(pedido);

    // ✅ Notificação salva com email do usuário
    await FirebaseFirestore.instance.collection('notificacoes').add({
      'titulo': 'Pedido realizado',
      'mensagem': 'Seu pedido foi feito com sucesso!',
      'email': email, // ✅ Usar email ao invés de uid
      'data': Timestamp.now(),
      'lido': false,
    });

    await limparCarrinho();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Pagamento confirmado, pedido salvo e carrinho limpo!"),
      ),
    );

    _exibirChavePix(context);
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Erro ao salvar o pedido: $e")),
    );
  }
}

  // Exibe chave PIX
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
                style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 20),
            Text(
                "Endereço: ${widget.endereco['logradouro']}, ${widget.endereco['cidade']}",
                style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 20),
            const Text("Produtos:", style: TextStyle(fontSize: 18)),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: widget.produtos.length,
                itemBuilder: (context, index) {
                  final produto = widget.produtos[index];
                  return ListTile(
                    title: Text(produto['nome']),
                    subtitle: Text(
                        "R\$ ${produto['preco'].toStringAsFixed(2)} x ${produto['quantidade']}"),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => salvarPedido(context),
              child: const Text("Confirmar Pagamento"),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor: Colors.green,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
