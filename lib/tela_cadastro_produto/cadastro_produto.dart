// ... [importações continuam iguais]
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as p;
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await Supabase.initialize(
    url: 'https://gxpoabwzyshjovvmwgww.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imd4cG9hYnd6eXNoam92dm13Z3d3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTM2NTA4NTYsImV4cCI6MjA2OTIyNjg1Nn0.8livV6b0iLySnhSOrtu4DdsicEQmEVYd83IsFRfla9U',
  );

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

  List<XFile> imagensSelecionadas = [];

  String tipoTamanho = 'numerico';

  final Map<String, TextEditingController> tamanhosNumericos = {};
  List<Map<String, dynamic>> variacoes =
      []; // cada item: {'cor': 'Preto', 'tamanhos': {'P': 10, 'M': 5}}

  void adicionarVariacao() {
    setState(() {
      variacoes.add({'cor': '', 'tamanhos': <String, TextEditingController>{}});
    });
  }

  void removerVariacao(int index) {
    setState(() {
      variacoes.removeAt(index);
    });
  }

  final Map<String, TextEditingController> tamanhosPMG = {
    'P': TextEditingController(),
    'M': TextEditingController(),
    'G': TextEditingController(),
  };

  final TextEditingController tamanhosNumericosController =
      TextEditingController();

  bool possuiVariacoesCor = false;
  final TextEditingController coresController = TextEditingController();

  Future<void> _selecionarImagens() async {
    final picker = ImagePicker();
    final novasImagens = await picker.pickMultiImage();
    if (novasImagens.isNotEmpty) {
      setState(() {
        imagensSelecionadas.addAll(novasImagens);
      });
    }
  }

  Future<List<String>> _uploadImagensParaSupabase() async {
    final supabase = Supabase.instance.client;
    List<String> urls = [];

    for (final imagem in imagensSelecionadas) {
      final fileBytes = await imagem.readAsBytes();
      final extension = p.extension(imagem.path).toLowerCase();
      final contentType = extension == '.png' ? 'image/png' : 'image/jpeg';
      final fileName =
          'public/${DateTime.now().millisecondsSinceEpoch}_${p.basename(imagem.path)}';

      try {
        await supabase.storage.from('produtos').uploadBinary(
            fileName, fileBytes,
            fileOptions: FileOptions(contentType: contentType));
        final publicUrl =
            supabase.storage.from('produtos').getPublicUrl(fileName);
        urls.add(publicUrl);
      } catch (e) {
        throw Exception('Erro ao enviar imagem: $e');
      }
    }

    return urls;
  }

  Future<void> _salvarProduto() async {
    final nome = nomeController.text.trim();
    final descricao = descricaoController.text.trim();
    final precoStr = precoController.text.trim();

    if (nome.isEmpty ||
        descricao.isEmpty ||
        precoStr.isEmpty ||
        imagensSelecionadas.isEmpty) {
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

    final urlsDasImagens = await _uploadImagensParaSupabase();

    Map<String, dynamic> variacoesMap = {};

    if (possuiVariacoesCor) {
      for (final corData in variacoes) {
        final cor = corData['cor'];
        if (cor == null || cor.isEmpty) continue;

        final tamanhos =
            corData['tamanhos'] as Map<String, TextEditingController>;
        final estoquePorTamanho = <String, int>{};

        tamanhos.forEach((tamanho, controller) {
          final qtdStr = controller.text.trim();
          if (qtdStr.isNotEmpty) {
            final qtd = int.tryParse(qtdStr) ?? 0;
            if (qtd > 0) {
              estoquePorTamanho[tamanho] = qtd;
            }
          }
        });

        if (estoquePorTamanho.isNotEmpty) {
          variacoesMap[cor] = estoquePorTamanho;
        }
      }

      if (variacoesMap.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  "Adicione pelo menos uma variação de cor e tamanho com estoque.")),
        );
        return;
      }
    }

    try {
      await FirebaseFirestore.instance.collection('estoque').add({
        'nome': nome,
        'descricao': descricao,
        'preco': preco,
        'imagens': urlsDasImagens,
        'variacoes': possuiVariacoesCor ? variacoesMap : {},
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Produto cadastrado com sucesso!")),
      );

      nomeController.clear();
      descricaoController.clear();
      precoController.clear();
      imagensSelecionadas.clear();
      coresController.clear();
      tamanhosNumericos.clear();
      tamanhosPMG.values.forEach((c) => c.clear());
      variacoes.clear();

      setState(() {
        tipoTamanho = 'numerico';
        possuiVariacoesCor = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erro ao cadastrar produto: $e")),
      );
    }
  }

  void _gerarCamposTamanhosNumericos() {
    tamanhosNumericos.clear();
    final tamanhos = tamanhosNumericosController.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty);
    for (var tamanho in tamanhos) {
      tamanhosNumericos[tamanho] = TextEditingController();
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Cadastro de Produto',
              style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.black,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        backgroundColor: const Color(0xFFFAF3E0),
        body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListView(children: [
              TextField(
                  controller: nomeController,
                  decoration: const InputDecoration(labelText: 'Nome')),
              const SizedBox(height: 10),
              TextField(
                  controller: descricaoController,
                  decoration: const InputDecoration(labelText: 'Descrição')),
              const SizedBox(height: 10),
              TextField(
                controller: precoController,
                decoration: const InputDecoration(labelText: 'Preço'),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                  onPressed: _selecionarImagens,
                  child: const Text('Selecionar Imagens')),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: imagensSelecionadas.map((img) {
                  final index = imagensSelecionadas.indexOf(img);
                  return Stack(
                    children: [
                      kIsWeb
                          ? Image.network(img.path,
                              width: 100, height: 100, fit: BoxFit.cover)
                          : Image.file(File(img.path),
                              width: 100, height: 100, fit: BoxFit.cover),
                      Positioned(
                        top: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              imagensSelecionadas.removeAt(index);
                            });
                          },
                          child: Container(
                            color: Colors.black54,
                            padding: const EdgeInsets.all(4),
                            child: const Icon(Icons.close,
                                color: Colors.white, size: 18),
                          ),
                        ),
                      )
                    ],
                  );
                }).toList(),
              ),
           const SizedBox(height: 20),


              Row(
                children: [
                  Switch(
                    value: possuiVariacoesCor,
                    onChanged: (value) =>
                        setState(() => possuiVariacoesCor = value),
                  ),
                  const Text('Produto com variações de cor?'),
                ],
              ),
              const SizedBox(height: 10),
              ElevatedButton(
  onPressed: _salvarProduto,
  style: ElevatedButton.styleFrom(
    backgroundColor: Colors.black,
    padding: const EdgeInsets.symmetric(vertical: 16),
  ),
  child: const Text(
    'Cadastrar Produto',
    style: TextStyle(color: Colors.white),
  ),
),
              if (possuiVariacoesCor) ...[
                ElevatedButton(
                  onPressed: adicionarVariacao,
                  child: const Text('+ Adicionar Cor'),
                ),
                const SizedBox(height: 10),
                ...variacoes.asMap().entries.map((entry) {
                  final index = entry.key;
                  final corData = entry.value;
                  final tamanhos =
                      corData['tamanhos'] as Map<String, TextEditingController>;

                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  decoration:
                                      const InputDecoration(labelText: 'Cor'),
                                  onChanged: (value) {
                                    corData['cor'] = value.trim();
                                  },
                                ),
                              ),
                              IconButton(
                                icon:
                                    const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => removerVariacao(index),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          const Text('Tamanhos e Estoque:'),
                          const SizedBox(height: 5),
                          Wrap(
                            spacing: 10,
                            children: [
                              'P',
                              'M',
                              'G',
                              'GG',
                              '36',
                              '38',
                              '40',
                              '42'
                            ].map((tamanho) {
                              tamanhos.putIfAbsent(
                                  tamanho, () => TextEditingController());
                              return SizedBox(
                                width: 80,
                                child: TextField(
                                  controller: tamanhos[tamanho],
                                  keyboardType: TextInputType.number,
                                  decoration:
                                      InputDecoration(labelText: tamanho),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ]
            ])));
  }
}
