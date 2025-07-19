import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class TelaEnderecos extends StatefulWidget {
  const TelaEnderecos({super.key});

  @override
  State<TelaEnderecos> createState() => _TelaEnderecosState();
}

class _TelaEnderecosState extends State<TelaEnderecos> {
  final user = FirebaseAuth.instance.currentUser;

  // Referência à subcoleção 'enderecos' dentro do usuário atual
  CollectionReference<Map<String, dynamic>> get enderecosRef {
    return FirebaseFirestore.instance
        .collection('users') // Coleção users
        .doc(user!.uid) // Documento do usuário
        .collection('enderecos'); // Subcoleção de endereços
  }

  @override
  void initState() {
    super.initState();
    _verificaEnderecoInicial();
  }

  // Função para verificar se o usuário já tem um endereço cadastrado
  void _verificaEnderecoInicial() async {
    final snapshot = await enderecosRef.get();

    if (snapshot.docs.isEmpty) {
      // Se não houver endereços, abre o formulário de cadastro de endereço
      Future.delayed(Duration.zero, () {
        _adicionarOuEditarEndereco(); // Abre o formulário automaticamente
      });
    }
  }

  // Função para adicionar ou editar um endereço
  void _adicionarOuEditarEndereco({DocumentSnapshot? doc}) {
    final TextEditingController nomeUsuarioCtrl =
        TextEditingController(text: doc?['nomeUsuario']);
    final TextEditingController logradouroCtrl =
        TextEditingController(text: doc?['logradouro']);
    final TextEditingController cidadeCtrl =
        TextEditingController(text: doc?['cidade']);
    final TextEditingController estadoCtrl =
        TextEditingController(text: doc?['estado']);
    final TextEditingController cepCtrl =
        TextEditingController(text: doc?['cep']);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(doc == null ? 'Novo Endereço' : 'Editar Endereço'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: nomeUsuarioCtrl,
                decoration: const InputDecoration(labelText: 'Nome do Usuário'),
              ),
              TextField(
                controller: logradouroCtrl,
                decoration: const InputDecoration(labelText: 'Logradouro'),
              ),
              TextField(
                controller: cidadeCtrl,
                decoration: const InputDecoration(labelText: 'Cidade'),
              ),
              TextField(
                controller: estadoCtrl,
                decoration: const InputDecoration(labelText: 'Estado'),
              ),
              TextField(
                controller: cepCtrl,
                decoration: const InputDecoration(labelText: 'CEP'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final data = {
                'nomeUsuario': nomeUsuarioCtrl.text.trim(),
                'logradouro': logradouroCtrl.text.trim(),
                'cidade': cidadeCtrl.text.trim(),
                'estado': estadoCtrl.text.trim(),
                'cep': cepCtrl.text.trim(),
              };

              if (doc == null) {
                await enderecosRef.add(data);
              } else {
                await enderecosRef.doc(doc.id).update(data);
              }

              // Fecha o diálogo após salvar
              if (context.mounted) Navigator.pop(context);

              // Opcional: limpa os controllers
              nomeUsuarioCtrl.dispose();
              logradouroCtrl.dispose();
              cidadeCtrl.dispose();
              estadoCtrl.dispose();
              cepCtrl.dispose();
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  // Função para excluir um endereço
  void _excluirEndereco(String id) async {
    await enderecosRef.doc(id).delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            const Text('Meus Endereços', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.brown.shade800,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: enderecosRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Nenhum endereço cadastrado.'));
          }

          final docs = snapshot.data!.docs;

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final endereco = doc.data() as Map<String, dynamic>;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(endereco['nomeUsuario'] ?? 'Sem nome'),
                  subtitle: Text(
                      '${endereco['logradouro']}, ${endereco['cidade']}, ${endereco['estado']} - ${endereco['cep']}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _adicionarOuEditarEndereco(doc: doc),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _excluirEndereco(doc.id),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.brown.shade700,
        onPressed: () => _adicionarOuEditarEndereco(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
