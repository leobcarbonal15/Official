import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EstoqueHortifrutiPage extends StatelessWidget {
  final produtosRef = FirebaseFirestore.instance.collection('estoque');

  // Método para alterar estoque de um tamanho específico (incrementar/decrementar)
  Future<void> alterarEstoquePorTamanho(
      String id, String tamanho, int delta) async {
    final doc = await produtosRef.doc(id).get();
    final data = doc.data() as Map<String, dynamic>?;

    if (data == null) return;

    final Map<String, dynamic> tamanhosMap =
        Map<String, dynamic>.from(data['tamanhosComEstoque'] ?? {});
    final estoqueAtual = (tamanhosMap[tamanho] ?? 0) as int;
    final novoEstoque = estoqueAtual + delta;

    if (novoEstoque >= 0) {
      tamanhosMap[tamanho] = novoEstoque;
      await produtosRef.doc(id).update({'tamanhosComEstoque': tamanhosMap});
    }
  }

  // Diálogo para editar manualmente todos os estoques por tamanho
  Future<void> editarEstoqueManual(
      BuildContext context, String id, Map<String, dynamic> tamanhosEstoque) async {
    final controllers = <String, TextEditingController>{};
    tamanhosEstoque.forEach((tamanho, estoque) {
      controllers[tamanho] = TextEditingController(text: estoque.toString());
    });

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Editar Estoque por Tamanho'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: controllers.entries.map((entry) {
              final tamanho = entry.key;
              final controller = entry.value;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: 'Estoque para tamanho $tamanho'),
                ),
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              final novoEstoqueMap = <String, int>{};
              bool valido = true;

              for (var entry in controllers.entries) {
                final valor = int.tryParse(entry.value.text);
                if (valor == null || valor < 0) {
                  valido = false;
                  break;
                }
                novoEstoqueMap[entry.key] = valor;
              }

              if (valido) {
                await produtosRef.doc(id).update({'tamanhosComEstoque': novoEstoqueMap});
                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Valores inválidos!')),
                );
              }
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  // Diálogo para adicionar novo produto
  Future<void> adicionarProduto(BuildContext context) async {
    final nomeController = TextEditingController();
    final imagemController = TextEditingController();
    final tamanhosController = TextEditingController(); // tamanhos separados por vírgula

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Novo Produto'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nomeController, decoration: const InputDecoration(labelText: 'Nome')),
              TextField(
                controller: tamanhosController,
                decoration: const InputDecoration(
                  labelText: 'Tamanhos (ex: P,M,G) - inicialmente estoque zero',
                ),
              ),
              TextField(
                controller: imagemController,
                decoration: const InputDecoration(labelText: 'URL da Imagem'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              final nome = nomeController.text.trim();
              final imagemUrl = imagemController.text.trim();
              final tamanhosTexto = tamanhosController.text.trim();

              if (nome.isNotEmpty) {
                Map<String, int> tamanhosMap = {};
                if (tamanhosTexto.isNotEmpty) {
                  final tamanhos = tamanhosTexto.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty);
                  for (var t in tamanhos) {
                    tamanhosMap[t] = 0;
                  }
                }

                await produtosRef.add({
                  'nome': nome,
                  'imagemUrl': imagemUrl,
                  'tamanhosComEstoque': tamanhosMap,
                });
                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Nome do produto não pode ficar vazio!')),
                );
              }
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('estoque', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color.fromARGB(255, 0, 0, 0),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => adicionarProduto(context),
            tooltip: 'Adicionar Produto',
          )
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: produtosRef.orderBy('nome').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(child: Text('Nenhum produto no estoque.'));
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final nome = data['nome'] ?? 'Sem nome';
          final rawTamanhosEstoque = data['tamanhosComEstoque'] ?? {};
final Map<String, dynamic> tamanhosEstoque = {};
rawTamanhosEstoque.forEach((key, value) {
  tamanhosEstoque[key.toString()] = value;
});

final imagemUrl = data['imagemUrl1'] ?? ''; // ajuste aqui

return Card(
  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
  child: ListTile(
    leading: imagemUrl.isNotEmpty
        ? Image.network(imagemUrl, width: 50, height: 50, fit: BoxFit.cover)
        : const Icon(Icons.image_not_supported, size: 40),
    title: Text(nome),
    subtitle: tamanhosEstoque.isEmpty
        ? const Text('Sem estoque por tamanho')
        : Wrap(
            spacing: 8,
            children: tamanhosEstoque.entries.map((entry) {
              final tamanho = entry.key;
              final estoque = entry.value;
              return Chip(label: Text('$tamanho: $estoque'));
            }).toList(),
          ),
    onTap: () => editarEstoqueManual(context, doc.id, tamanhosEstoque),
  ),
);

            },
          );
        },
      ),
    );
  }
}
