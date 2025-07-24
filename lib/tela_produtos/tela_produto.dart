import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TelaProduto extends StatefulWidget {
  final String idEstoque;
  final String nome;
  final double preco;
  final String descricao;
  final String imagemUrl;
  final Map<String, dynamic> estoquePorTamanho;

  const TelaProduto({
    super.key,
    required this.idEstoque,
    required this.nome,
    required this.preco,
    required this.descricao,
    required this.imagemUrl,
    required this.estoquePorTamanho,
  });

  @override
  State<TelaProduto> createState() => _TelaProdutoState();
}

class _TelaProdutoState extends State<TelaProduto> {
  String? tamanhoSelecionado;
  int quantidade = 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.nome),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Image.network(
              widget.imagemUrl,
              height: 250,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
            const SizedBox(height: 16),
            Text(
              widget.nome,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            Text(
              'R\$ ${widget.preco.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 18, color: Colors.green),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(widget.descricao),
            ),
            const SizedBox(height: 20),
            const Text(
              'Selecione o tamanho:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              children: widget.estoquePorTamanho.entries.map((entry) {
                final tamanho = entry.key;
                final estoque = entry.value as int;
                final esgotado = estoque <= 0;

                return ElevatedButton(
                  onPressed: esgotado
                      ? null
                      : () {
                          setState(() {
                            tamanhoSelecionado = tamanho;
                          });
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: tamanhoSelecionado == tamanho
                        ? Colors.blue
                        : esgotado
                            ? Colors.grey
                            : Colors.black,
                  ),
                  child: Text(
                    tamanho,
                    style: TextStyle(
                      color: esgotado ? Colors.white60 : Colors.white,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: tamanhoSelecionado == null
                  ? null
                  : () {
                      // Adicionar à sacola ou lógica de compra
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(
                            'Produto adicionado: ${widget.nome} - Tamanho $tamanhoSelecionado'),
                      ));
                    },
              child: const Text('Adicionar à sacola'),
            ),
          ],
        ),
      ),
    );
  }
}
