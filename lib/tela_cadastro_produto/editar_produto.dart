import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:typed_data';

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

  bool _carregando = true;
  List<String> _imagensUrls = [];
  List<XFile> _novasImagensSelecionadas = [];
  List<Uint8List> _imagensBytesWeb = [];

  final String supabaseUrl = 'https://gxpoabwzyshjovvmwgww.supabase.co';
  final String supabaseKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imd4cG9hYnd6eXNoam92dm13Z3d3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTM2NTA4NTYsImV4cCI6MjA2OTIyNjg1Nn0.8livV6b0iLySnhSOrtu4DdsicEQmEVYd83IsFRfla9U';
  final String bucket = 'produtos';

  @override
  void initState() {
    super.initState();
    _nomeController = TextEditingController();
    _precoController = TextEditingController();
    _descricaoController = TextEditingController();
    _carregarDadosProduto();
  }

  Future<void> _carregarDadosProduto() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('estoque')
          .doc(widget.produtoId)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        _nomeController.text = data['nome'] ?? '';
        _precoController.text = data['preco'].toString();
        _descricaoController.text = data['descricao'] ?? '';
        if (data['imagens'] != null) {
          _imagensUrls = List<String>.from(data['imagens']);
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar produto: $e')),
      );
    }
    setState(() => _carregando = false);
  }

  Future<void> _selecionarImagem() async {
    final picker = ImagePicker();
    final imagens = await picker.pickMultiImage();

    if (kIsWeb) {
      _imagensBytesWeb.clear();
      for (var img in imagens) {
        final bytes = await img.readAsBytes();
        _imagensBytesWeb.add(bytes);
      }
    } else {
      _novasImagensSelecionadas = imagens;
    }

    setState(() {});
  }

  Future<String?> _uploadImagemSupabase(XFile imagem) async {
    try {
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${imagem.name}';
      final storagePath = 'public/$fileName';

      final uri =
          Uri.parse('$supabaseUrl/storage/v1/object/$bucket/$storagePath');
      final request = http.MultipartRequest('POST', uri)
        ..headers['Authorization'] = 'Bearer $supabaseKey'
        ..files.add(await http.MultipartFile.fromPath('file', imagem.path));

      final response = await request.send();

      if (response.statusCode == 200) {
        return '$supabaseUrl/storage/v1/object/public/$bucket/$storagePath';
      } else {
        throw Exception('Erro no upload: ${response.statusCode}');
      }
    } catch (e) {
      print('Erro ao enviar imagem: $e');
      return null;
    }
  }

  Future<void> _excluirImagemSupabase(String imageUrl) async {
    try {
      final path = imageUrl.split('/object/public/').last;
      final uri = Uri.parse('$supabaseUrl/storage/v1/object/$bucket');

      final response = await http.delete(
        uri,
        headers: {
          'Authorization': 'Bearer $supabaseKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'prefixes': [path]
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Erro ao excluir imagem do Supabase: ${response.body}');
      }
    } catch (e) {
      print('Erro ao excluir imagem: $e');
    }
  }

  Future<void> _salvarAlteracoes() async {
    if (_formKey.currentState!.validate()) {
      try {
        List<String> novasUrls = List.from(_imagensUrls);

        for (var imagem in _novasImagensSelecionadas) {
          final url = await _uploadImagemSupabase(imagem);
          if (url != null) novasUrls.add(url);
        }

        await FirebaseFirestore.instance
            .collection('estoque')
            .doc(widget.produtoId)
            .update({
          'nome': _nomeController.text,
          'preco': double.parse(_precoController.text),
          'descricao': _descricaoController.text,
          'imagens': novasUrls,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Produto atualizado com sucesso!')),
        );

        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar alterações: $e')),
        );
      }
    }
  }

  void _removerImagem(String url) async {
    await _excluirImagemSupabase(url);
    setState(() => _imagensUrls.remove(url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            const Text('Editar Produto', style: TextStyle(color: Colors.white)),
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
                        if (double.tryParse(value) == null)
                          return 'Preço inválido';
                        return null;
                      },
                    ),
                    TextFormField(
                      controller: _descricaoController,
                      decoration: const InputDecoration(labelText: 'Descrição'),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 20),
                   
                    const SizedBox(height: 10),

                    // Exibir imagens existentes
                    // Mostrar novas imagens selecionadas
// Mostrar novas imagens selecionadas
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: kIsWeb
                          ? _imagensBytesWeb.map((bytes) {
                              return Stack(
                                children: [
                                  Image.memory(bytes,
                                      height: 150,
                                      width: 150,
                                      fit: BoxFit.cover),
                                  // botão para remover se quiser implementar
                                ],
                              );
                            }).toList()
                          : _novasImagensSelecionadas.map((xfile) {
                              return Stack(
                                children: [
                                  Image.file(
                                    File(xfile.path),
                                    height: 150,
                                    width: 150,
                                    fit: BoxFit.cover,
                                  ),
                                  // botão para remover se quiser implementar
                                ],
                              );
                            }).toList(),
                    ),

               

                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _salvarAlteracoes,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 0, 0, 0),
                      ),
                      child: const Text('Salvar Alterações',
                          style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
