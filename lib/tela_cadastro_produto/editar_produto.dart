import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditaProduto extends StatefulWidget {
  final String produtoId;

  const EditaProduto({super.key, required this.produtoId});

  @override
  State<EditaProduto> createState() => EditaProdutoState();
}

class EditaProdutoState extends State<EditaProduto> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nomeController;
  late TextEditingController _precoController;
  late TextEditingController _descricaoController;
  late TextEditingController _imagemUrlController;
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _nomeController = TextEditingController();
    _precoController = TextEditingController();
    _descricaoController = TextEditingController();
    _imagemUrlController = TextEditingController();
    _carregarDadosProduto();
  }

  Future<void> _carregarDadosProduto() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('produtos_hortifruti')
          .doc(widget.produtoId)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        _nomeController.text = data['nome'] ?? '';
        _precoController.text = data['preco'].toString();
        _descricaoController.text = data['descricao'] ?? '';
        _imagemUrlController.text = data['imagemUrl'] ?? '';
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar produto: $e')),
      );
    }

    setState(() {
      _carregando = false;
    });
  }

  Future<void> _salvarAlteracoes() async {
    if (_formKey.currentState!.validate()) {
      try {
        await FirebaseFirestore.instance
            .collection('produtos_hortifruti')
            .doc(widget.produtoId)
            .update({
          'nome': _nomeController.text,
          'preco': double.parse(_precoController.text),
          'descricao': _descricaoController.text,
          'imagemUrl': _imagemUrlController.text,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Produto atualizado com sucesso!')),
        );

        Navigator.pop(context); // Voltar após salvar
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar alterações: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Produto', style: TextStyle(color: Colors.white)),

        backgroundColor: const Color.fromARGB(255, 0, 0, 0),
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    TextFormField(
                      controller: _nomeController,
                      decoration: const InputDecoration(labelText: 'Nome'),
                      validator: (value) =>
                          value!.isEmpty ? 'Informe o nome' : null,
                    ),
                    TextFormField(
                      controller: _precoController,
                      decoration: const InputDecoration(labelText: 'Preço'),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value!.isEmpty) return 'Informe o preço';
                        if (double.tryParse(value) == null) {
                          return 'Preço inválido';
                        }
                        return null;
                      },
                    ),
                    TextFormField(
                      controller: _descricaoController,
                      decoration: const InputDecoration(labelText: 'Descrição'),
                      maxLines: 3,
                    ),
                    TextFormField(
                      controller: _imagemUrlController,
                      decoration: const InputDecoration(labelText: 'URL da Imagem'),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _salvarAlteracoes,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 0, 0, 0),
                      ),
                      child: const Text('Salvar Alterações', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
