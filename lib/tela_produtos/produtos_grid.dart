import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:myapp/tela_produtos/produto.dart'; // ajuste conforme seu projeto

class ProdutosGrid extends StatelessWidget {
  final String searchQuery;

  const ProdutosGrid({super.key, this.searchQuery = ''});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('produtos_hortifruti')
          .snapshots(), // removido filtro direto no Firestore
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('Nenhum produto encontrado.'));
        }

        // Filtragem no Flutter (emEstoque e nome)
        final produtos = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final nome = (data['nome'] ?? '').toString().toLowerCase();
          final emEstoque = data['emEstoque'] == true;

          final correspondeBusca = searchQuery.isEmpty ||
              nome.contains(searchQuery.toLowerCase());

          return emEstoque && correspondeBusca;
        }).toList();

        if (produtos.isEmpty) {
          return const Center(child: Text('Nenhum produto encontrado.'));
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            double aspectRatio = constraints.maxWidth > 600 ? 0.55 : 0.6;

            return GridView.builder(
              padding: const EdgeInsets.all(10),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 25,
                crossAxisSpacing: 15,
                childAspectRatio: aspectRatio,
              ),
              itemCount: produtos.length,
              itemBuilder: (context, index) {
                final produto = produtos[index].data() as Map<String, dynamic>;

                final nome = produto['nome'] ?? 'Sem nome';
                final preco = (produto['preco'] ?? 0).toDouble();
                final descricao = produto['descricao'] ?? '';
                final imagemUrl = produto['imagemUrl'] ??
                    'https://via.placeholder.com/150'; // imagem padrão
                final emPromocao = produto['emPromocao'] ?? false;

                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TelaProduto(
                          nome: nome,
                          preco: preco,
                          descricao: descricao,
                          imagemUrl: imagemUrl,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.5),
                          spreadRadius: 1,
                          blurRadius: 3,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(5.0),
                                child: Container(
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    image: DecorationImage(
                                      image: NetworkImage(imagemUrl),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8.0),
                              child: Text(
                                nome,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 10.0, top: 4),
                              child: Text(
                                'R\$ ${preco.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (emPromocao)
                          Positioned(
                            top: 8,
                            left: 8,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'Promoção',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
