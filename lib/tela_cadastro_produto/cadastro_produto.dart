import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:myapp/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MaterialApp(home: CadastroProduto()));
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

  String tipoTamanho = 'numerico'; // ou 'pmg'

  final Map<String, TextEditingController> tamanhosNumericos = {};
  final Map<String, TextEditingController> tamanhosPMG = {
    'P': TextEditingController(),
    'M': TextEditingController(),
    'G': TextEditingController(),
  };
  final TextEditingController tamanhosNumericosController = TextEditingController();

  Future<void> _salvarProduto() async {
    final nome = nomeController.text.trim();
    final descricao = descricaoController.text.trim();
    final precoStr = precoController.text.trim();
    final imagemUrl = imagemUrlController.text.trim();

    if (nome.isEmpty || descricao.isEmpty || precoStr.isEmpty || imagemUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Preencha todos os campos obrigatórios.")),
      );
      return;
    }

    double preco;
    try {
      preco = double.parse(precoStr);
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Preço inválido.")),
      );
      return;
    }

    Map<String, int> tamanhosComEstoque = {};

    if (tipoTamanho == 'numerico') {
      for (final entry in tamanhosNumericos.entries) {
        final tamanho = entry.key;
        final quantidadeStr = entry.value.text.trim();
        if (quantidadeStr.isNotEmpty) {
          final quantidade = int.tryParse(quantidadeStr) ?? 0;
          tamanhosComEstoque[tamanho] = quantidade;
        }
      }
    } else {
      for (final entry in tamanhosPMG.entries) {
        final quantidadeStr = entry.value.text.trim();
        if (quantidadeStr.isNotEmpty) {
          final quantidade = int.tryParse(quantidadeStr) ?? 0;
          tamanhosComEstoque[entry.key] = quantidade;
        }
      }
    }

    try {
      await FirebaseFirestore.instance.collection('estoque').add({
        'nome': nome,
        'descricao': descricao,
        'preco': preco,
        'imagemUrl': imagemUrl,
        'tipoTamanho': tipoTamanho,
        'tamanhosComEstoque': tamanhosComEstoque,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Produto cadastrado com sucesso!")),
      );

      nomeController.clear();
      descricaoController.clear();
      precoController.clear();
      imagemUrlController.clear();
      tamanhosNumericosController.clear();
      tamanhosNumericos.clear();
      tamanhosPMG.values.forEach((controller) => controller.clear());

      setState(() {
        tipoTamanho = 'numerico';
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erro ao cadastrar produto: $e")),
      );
    }
  }

  void _gerarCamposTamanhosNumericos() {
    tamanhosNumericos.clear();
    final tamanhos = tamanhosNumericosController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty);
    for (var tamanho in tamanhos) {
      tamanhosNumericos[tamanho] = TextEditingController();
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cadastro de Produto', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      backgroundColor: const Color(0xFFFAF3E0),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            TextField(controller: nomeController, decoration: const InputDecoration(labelText: 'Nome')),
            const SizedBox(height: 10),
            TextField(controller: descricaoController, decoration: const InputDecoration(labelText: 'Descrição')),
            const SizedBox(height: 10),
            TextField(
              controller: precoController,
              decoration: const InputDecoration(labelText: 'Preço'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: imagemUrlController,
              decoration: const InputDecoration(labelText: 'URL da Imagem'),
            ),
            const SizedBox(height: 20),
            const Text("Tipo de Tamanho:", style: TextStyle(fontWeight: FontWeight.bold)),
            Row(
              children: [
                Radio(
                  value: 'numerico',
                  groupValue: tipoTamanho,
                  onChanged: (value) => setState(() => tipoTamanho = value.toString()),
                ),
                const Text('Numérico'),
                Radio(
                  value: 'pmg',
                  groupValue: tipoTamanho,
                  onChanged: (value) => setState(() => tipoTamanho = value.toString()),
                ),
                const Text('P / M / G'),
              ],
            ),
            if (tipoTamanho == 'numerico') ...[
              TextField(
                controller: tamanhosNumericosController,
                decoration: const InputDecoration(labelText: 'Tamanhos (ex: 36, 38, 40)'),
                onChanged: (_) => _gerarCamposTamanhosNumericos(),
              ),
              const SizedBox(height: 10),
              ...tamanhosNumericos.entries.map((entry) => TextField(
                    controller: entry.value,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: 'Quantidade tamanho ${entry.key}'),
                  )),
            ],
            if (tipoTamanho == 'pmg')
              ...tamanhosPMG.entries.map((entry) => TextField(
                    controller: entry.value,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: 'Quantidade tamanho ${entry.key}'),
                  )),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _salvarProduto,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Cadastrar Produto', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
