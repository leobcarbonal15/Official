// Suggested code may be subject to a license. Learn more: ~LicenseLog:2567292558.
// Suggested code may be subject to a license. Learn more: ~LicenseLog:3105867724.
// Suggested code may be subject to a license. Learn more: ~LicenseLog:1830487194.
// Suggested code may be subject to a license. Learn more: ~LicenseLog:3823162991.
// Suggested code may be subject to a license. Learn more: ~LicenseLog:1115933080.
// Suggested code may be subject to a license. Learn more: ~LicenseLog:3493806306.
// Suggested code may be subject to a license. Learn more: ~LicenseLog:1580007321.
// Suggested code may be subject to a license. Learn more: ~LicenseLog:3864776400.
// Suggested code may be subject to a license. Learn more: ~LicenseLog:478334793.
// Suggested code may be subject to a license. Learn more: ~LicenseLog:1879788821.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:myapp/firebase_options.dart';
import 'package:myapp/tela_cadastro_produto/cadastro_produto.dart';


class TelaProduto extends StatelessWidget {
  final String nome;
  final double preco;
  final String descricao;
  final String imagemUrl;

  const TelaProduto({
    super.key,
    required this.nome,
    required this.preco,
    required this.descricao,
    required this.imagemUrl,
  });

 void _adicionarAoCarrinho(BuildContext context) async {
  try {
    await FirebaseFirestore.instance.collection('carrinho').add({
      'nome': nome,
      'imagem': imagemUrl,
      'preco': preco,
      'quantidade': 1,
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          "Produto adicionado ao carrinho!",
          style: TextStyle(color: Colors.white)),
      ),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Erro ao adicionar: $e")),
    );
  }
}

  void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const CadastroProduto());

  
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF3E0),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 0, 0, 0),
        title: Text(
          nome,
          style: const TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
     body: Container(
  color: const Color(0xFFFAF3E0), // Fundo bege
  child: Center(
    child: Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16.0), // Espaço para a "borda bege"
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white, // Fundo branco
        borderRadius: BorderRadius.circular(12), // Bordas arredondadas (opcional)
        boxShadow: [
          BoxShadow(
            color: const Color.fromARGB(255, 0, 0, 0).withOpacity(0.2), // sombra leve
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
                    imagemUrl,
                    width: double.infinity,
                    height: 250,
                    fit: BoxFit.cover,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    nome,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Color.fromARGB(255, 0, 0, 0),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'R\$ ${preco.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 22,
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    descricao,
                    style: const TextStyle(fontSize: 16),
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
              label: const Text("Adicionar ao Carrinho",
                  style: TextStyle(fontSize: 16, color: Colors.white)),
            ),
          ),
        ],
      ),
    ),
  ),
));
  }}