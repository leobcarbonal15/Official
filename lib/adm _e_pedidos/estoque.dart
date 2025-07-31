import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EstoqueHortifrutiPage extends StatelessWidget {
  final produtosRef = FirebaseFirestore.instance.collection('estoque');

  // Diálogo para editar manualmente todos os estoques por cor e tamanho
  Future<void> editarEstoqueVariacoes(
    BuildContext context,
    String id,
    Map<String, Map<String, int>> variacoes,
  ) async {
    final controllers = <String, TextEditingController>{};

    variacoes.forEach((cor, tamanhos) {
      tamanhos.forEach((tam, qtd) {
        final chave = '$cor|$tam';
        controllers[chave] = TextEditingController(text: qtd.toString());
      });
    });

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Editar Estoque por Variações'),
        content: SingleChildScrollView(
          child: Column(
            children: controllers.entries.map((entry) {
              final partes = entry.key.split('|');
              final cor = partes[0];
              final tam = partes[1];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: TextField(
                  controller: entry.value,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Cor: $cor, Tamanho: $tam',
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              final novoMapa = <String, Map<String, int>>{};
              bool valido = true;

              controllers.forEach((key, controller) {
                final partes = key.split('|');
                final cor = partes[0];
                final tam = partes[1];
                final valor = int.tryParse(controller.text);

                if (valor == null || valor < 0) {
                  valido = false;
                } else {
                  novoMapa.putIfAbsent(cor, () => {})[tam] = valor;
                }
              });

              if (!valido) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Alguns valores são inválidos.')),
                );
                return;
              }

              await produtosRef.doc(id).update({'variacoes': novoMapa});
              Navigator.pop(context);
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
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: produtosRef.orderBy('nome').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final docs = snapshot.data!.docs;
          if (docs.isEmpty) return const Center(child: Text('Nenhum produto no estoque.'));

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final nome = data['nome'] ?? 'Sem nome';

              final rawVariacoes = data['variacoes'] ?? {};
              final Map<String, Map<String, int>> variacoes = {};

              (rawVariacoes as Map<String, dynamic>).forEach((cor, tamanhos) {
                final mapTamanhos = Map<String, int>.from((tamanhos as Map).map(
                  (key, value) => MapEntry(key.toString(), value is int ? value : int.tryParse(value.toString()) ?? 0),
                ));
                variacoes[cor] = mapTamanhos;
              });

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  leading: (data['imagens'] != null && data['imagens'].isNotEmpty)
                      ? Image.network(data['imagens'][0], width: 50, height: 50, fit: BoxFit.cover)
                      : const Icon(Icons.image_not_supported, size: 40),
                  title: Text(nome),
                  subtitle: variacoes.isEmpty
                      ? const Text('Sem estoque')
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: variacoes.entries.map((corEntry) {
                            final cor = corEntry.key;
                            final tamanhos = corEntry.value;
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Cor: $cor'),
                                Wrap(
                                  spacing: 8,
                                  children: tamanhos.entries.map((entry) {
                                    return Chip(label: Text('${entry.key}: ${entry.value}'));
                                  }).toList(),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                  onTap: () => editarEstoqueVariacoes(context, doc.id, variacoes),
                ),
              );
            },
          );
        },
      ),
    );
  }
}