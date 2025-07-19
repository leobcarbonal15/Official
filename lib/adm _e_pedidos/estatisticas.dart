import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EstatisticasPage extends StatelessWidget {
  const EstatisticasPage({super.key});

  Future<List<Map<String, dynamic>>> _buscarEstatisticas() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('estatisticas')
        .orderBy('quantidade_total', descending: true)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'id': doc.id,
        'nome': data['nome'],
        'quantidade_total': data['quantidade_total'],
        'ultima_venda': (data['ultima_venda'] as Timestamp).toDate(),
      };
    }).toList();
  }

  Future<void> _limparEstatisticas(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Confirmar limpeza"),
        content: const Text("Tem certeza que deseja apagar todas as estatísticas?"),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text("Cancelar")),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text("Apagar")),
        ],
      ),
    );

    if (confirm == true) {
      final snapshot = await FirebaseFirestore.instance.collection('estatisticas').get();
      for (final doc in snapshot.docs) {
        await doc.reference.delete();
      }

      // Feedback
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Estatísticas apagadas com sucesso!")),
      );
    }
  }

  String _formatarData(DateTime data) {
    return "${data.day.toString().padLeft(2, '0')}/"
        "${data.month.toString().padLeft(2, '0')}/"
        "${data.year}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(color: Colors.white, fontSize: 20),
        title: const Text('Estatísticas de Vendas'),
        backgroundColor: const Color.fromARGB(255, 0, 0, 0),
      ),
      backgroundColor: const Color(0xFFFAF3E0),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _buscarEstatisticas(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("Nenhum dado de estatística disponível."));
          }

          final produtos = snapshot.data!;

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: produtos.length,
                  itemBuilder: (context, index) {
                    final produto = produtos[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 4,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.brown.shade100,
                          child: Text('${index + 1}'),
                        ),
                        title: Text(produto['nome']),
                        subtitle: Text('Vendidos: ${produto['quantidade_total']}'),
                        trailing: Text(
                          'Última venda:\n${_formatarData(produto['ultima_venda'])}',
                          textAlign: TextAlign.right,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.delete_forever),
                  label: const Text("Limpar Estatísticas"),
                  onPressed: () => _limparEstatisticas(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color.fromARGB(255, 0, 0, 0),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
