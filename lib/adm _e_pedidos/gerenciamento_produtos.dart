import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:myapp/firebase_options.dart';
import 'package:myapp/tela_cadastro_produto/editar_produto.dart';
import 'package:diacritic/diacritic.dart';  // Pacote para remoção de acentos

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gerenciar Produtos',
      home: const GerenciarProdutos(),
    );
  }
}

class GerenciarProdutos extends StatefulWidget {
  const GerenciarProdutos({super.key});

  @override
  _GerenciarProdutosState createState() => _GerenciarProdutosState();
}

class _GerenciarProdutosState extends State<GerenciarProdutos> {
  String searchQuery = ""; // Variável para armazenar a pesquisa

  // Função de exclusão do produto
  void _excluirProduto(String id, BuildContext context) async {
    try {
      await FirebaseFirestore.instance
          .collection('produtos_hortifruti')
          .doc(id)
          .delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Produto excluído com sucesso')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao excluir: $e')),
      );
    }
  }

  // Função para alternar o status de estoque
  void _alternarEstoque(String id, bool emEstoque) {
    FirebaseFirestore.instance
        .collection('produtos_hortifruti')
        .doc(id)
        .update({'emEstoque': !emEstoque});
  }

  // Função para alternar o status de promoção
  void _alternarPromocao(String id, bool emPromocao) {
    FirebaseFirestore.instance
        .collection('produtos_hortifruti')
        .doc(id)
        .update({'emPromocao': !emPromocao});
  }

  // Função para mostrar os detalhes do produto
  void _mostrarDetalhesProduto(BuildContext context, Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(data['nome'] ?? 'Sem nome'),
          content: SingleChildScrollView(
            child: ListBody(
              children: [
                Text('Descrição: ${data['descricao'] ?? 'Não disponível'}'),
                Text('Preço: R\$ ${data['preco']}'),
                Text('Em estoque: ${data['emEstoque'] ? "Sim" : "Não"}'),
                Text('Em promoção: ${data['emPromocao'] ? "Sim" : "Não"}'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Fechar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // Função para normalizar as strings (remover acentos e colocar em minúsculo)
  String normalizeString(String input) {
    return removeDiacritics(input.toLowerCase());
  }

  @override
  Widget build(BuildContext context) {
    double larguraTela = MediaQuery.of(context).size.width;
    bool isSmallScreen = larguraTela < 600; // Dispositivos com tela menor que 600px

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Gerenciar Produtos',
          style: TextStyle(
            color: Colors.white,
          ),
        ),
        iconTheme: IconThemeData(color: Colors.white),
        backgroundColor: const Color.fromARGB(255, 0, 0, 0),
      ),
      body: Column(
        children: [
          // Barra de pesquisa
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: SizedBox(
              height: 40,
              child: TextField(
                cursorColor: const Color.fromARGB(255, 0, 0, 0),
                style: const TextStyle(fontSize: 14),
                onChanged: (query) {
                  setState(() {
                    searchQuery = query; // Atualiza a consulta de pesquisa
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Busque por nome do produto',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  prefixIcon: const Icon(Icons.search),
                ),
              ),
            ),
          ),
          // StreamBuilder para buscar os produtos com base na pesquisa
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('produtos_hortifruti')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('Nenhum produto encontrado.'));
                }

                final produtos = snapshot.data!.docs;

                // Filtra os produtos com base na pesquisa
                final filteredProdutos = produtos.where((produto) {
                  final data = produto.data() as Map<String, dynamic>;
                  final nomeProduto = data['nome'] ?? '';

                  // Normaliza a string e compara
                  return normalizeString(nomeProduto)
                      .contains(normalizeString(searchQuery));
                }).toList();

                return ListView.builder(
                  itemCount: filteredProdutos.length,
                  itemBuilder: (context, index) {
                    final produto = filteredProdutos[index];
                    final data = produto.data() as Map<String, dynamic>;
                    final String id = produto.id;

                    final String? imagemUrl = data['imagemUrl'];

                    return Card(
                      margin: EdgeInsets.symmetric(
                        horizontal: isSmallScreen ? 8 : 16,
                        vertical: isSmallScreen ? 4 : 8,
                      ),
                      child: ListTile(
                        leading: SizedBox(
                          width: isSmallScreen ? 40 : 50,
                          height: isSmallScreen ? 40 : 50,
                          child: imagemUrl != null && imagemUrl.isNotEmpty
                              ? Image.network(
                                  imagemUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (BuildContext context,
                                      Object exception, StackTrace? stackTrace) {
                                    debugPrint('Erro ao carregar imagem: $imagemUrl');
                                    return const Icon(Icons.broken_image, size: 40);
                                  },
                                )
                              : const Icon(Icons.local_florist_outlined, size: 40),
                        ),
                        title: Text(
                          data['nome'] ?? 'Sem nome',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 14 : 16,
                            overflow: TextOverflow.ellipsis,
                          ),
                          maxLines: 1,
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'R\$ ${data['preco'].toString()}',
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              data['descricao'] ?? '',
                              style: TextStyle(fontSize: isSmallScreen ? 12 : 14),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 2,
                            ),
                          ],
                        ),
                        onTap: () => _mostrarDetalhesProduto(context, data),
                        trailing: Wrap(
                          spacing: isSmallScreen ? 6 : 8,
                          children: [
                            IconButton(
                              icon: Icon(
                                data['emPromocao'] == true
                                    ? Icons.local_offer
                                    : Icons.loyalty,
                                color: data['emPromocao'] == true
                                    ? Colors.orange
                                    : Colors.grey,
                                size: isSmallScreen ? 20 : 24,
                              ),
                              onPressed: () => _alternarPromocao(id, data['emPromocao'] == true),
                              tooltip: data['emPromocao'] == true
                                  ? 'Remover da promoção'
                                  : 'Adicionar à promoção',
                            ),
                            IconButton(
                              icon: Icon(
                                data['emEstoque'] == true
                                    ? Icons.inventory
                                    : Icons.remove_shopping_cart,
                                color: data['emEstoque'] == true
                                    ? Colors.green
                                    : Colors.red,
                                size: isSmallScreen ? 20 : 24,
                              ),
                              onPressed: () => _alternarEstoque(id, data['emEstoque'] == true),
                              tooltip: data['emEstoque'] == true
                                  ? 'Marcar como fora de estoque'
                                  : 'Marcar como em estoque',
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.edit,
                                color: Colors.blue,
                                size: isSmallScreen ? 20 : 24,
                              ),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => EditaProduto(produtoId: id),
                                  ),
                                );
                              },
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.delete,
                                color: Colors.red,
                                size: isSmallScreen ? 20 : 24,
                              ),
                              onPressed: () => _excluirProduto(id, context),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
