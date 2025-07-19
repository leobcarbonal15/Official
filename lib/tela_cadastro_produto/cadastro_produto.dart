// Suggested code may be subject to a license. Learn more: ~LicenseLog:1047523645.
// Suggested code may be subject to a license. Learn more: ~LicenseLog:1597158610.
// Suggested code may be subject to a license. Learn more: ~LicenseLog:3735790024.
// Suggested code may be subject to a license. Learn more: ~LicenseLog:2835191698.
// Suggested code may be subject to a license. Learn more: ~LicenseLog:142600956.
// Import the functions you need from the SDKs you need
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:myapp/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const CadastroProduto());

  
}

class CadastroProduto extends StatefulWidget {
  const CadastroProduto({super.key});

  @override
  State<CadastroProduto> createState() => _CadastroProdutoState();
}

class _CadastroProdutoState extends State<CadastroProduto> {
  final nomeController = TextEditingController();
  final descricaoController = TextEditingController();
  final precoController = TextEditingController();
  final imagemUrlController = TextEditingController();

bool temAcesso = false; // Flag de acesso

  @override
  void initState() {
    super.initState();

  }


  Future<void> _salvarProduto() async {
    String nome = nomeController.text;
    String descricao = descricaoController.text;
    String precoStr = precoController.text;
    String imagemUrl = imagemUrlController.text;

    if (nome.isEmpty ||
        descricao.isEmpty ||
        precoStr.isEmpty ||
        imagemUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Preencha todos os campos")));
      return;
    }

    double preco;
    try {
      preco = double.parse(precoStr);
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Preço inválido")));
      return;
    }

    try {
      CollectionReference collRef =
          FirebaseFirestore.instance.collection('produtos_hortifruti');
      await collRef.add({
        'nome': nome,
        'descricao': descricao,
        'preco': preco,
        'imagemUrl': imagemUrl,
      });
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Produto cadastrado com sucesso! Ative seu estoque em gerenciar produtos")));
      // Clear the fields after successful submission
      nomeController.clear();
      descricaoController.clear();
      precoController.clear();
      imagemUrlController.clear();
    } on FirebaseException catch (e) {
      // Handle specific Firebase errors
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao cadastrar produto: ${e.message}')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao cadastrar produto: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
 leading: const BackButton(color: Colors.white), // Adiciona a seta branca
        title: const Text('Cadastro de Produto', style: TextStyle(color: Colors.white)),

        backgroundColor: const Color.fromARGB(255, 0, 0, 0),
      ),
      backgroundColor: const Color(0xFFFAF3E0),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            TextField(
              controller: nomeController,
              decoration: const InputDecoration(labelText: 'Nome do Produto'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descricaoController,
              decoration: const InputDecoration(labelText: 'Descrição'),
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: precoController,
              decoration: const InputDecoration(labelText: 'Preço'),
              keyboardType: TextInputType.numberWithOptions(
                  decimal: true), //Improved keyboard type
            ),
            const SizedBox(height: 12),
            TextField(
              controller: imagemUrlController,
              decoration: const InputDecoration(labelText: 'URL da Imagem'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _salvarProduto, //Directly call the function
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 0, 0, 0),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Cadastrar Produto',
                  style: TextStyle(fontSize: 16, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
