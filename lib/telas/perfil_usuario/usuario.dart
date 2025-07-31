// ... importaçōes inalteradas
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:myapp/main.dart';
import 'package:myapp/telas/notification/notificacoes_grid.dart';
import 'package:myapp/telas/tela_login/login.dart';

class TelaUsuario extends StatefulWidget {
  const TelaUsuario({super.key});

  @override
  State<TelaUsuario> createState() => _TelaUsuarioState();
}

class _TelaUsuarioState extends State<TelaUsuario> {
  User? usuario;
  String userRole = "Cliente";
  String userName = "Nome do Usuário";
  String photoUrl = "https://via.placeholder.com/150";

  @override
  void initState() {
    super.initState();
    _carregarDadosUsuario();
  }

  Future<void> _carregarDadosUsuario() async {
    usuario = FirebaseAuth.instance.currentUser;

    if (usuario != null) {
      final email = usuario!.email;

      if (email != null) {
        final perfilQuery = await FirebaseFirestore.instance
            .collection('perfil')
            .where('email', isEqualTo: email)
            .limit(1)
            .get();

        if (perfilQuery.docs.isNotEmpty) {
          final perfilData = perfilQuery.docs.first.data();
          setState(() {
            userName = perfilData['nome'] ?? 'Nome do Usuário';
            photoUrl = perfilData['fotoUrl'] ?? "https://via.placeholder.com/150";
          });
        } else {
          await FirebaseFirestore.instance.collection('perfil').add({
            'email': email,
            'nome': userName,
            'fotoUrl': photoUrl,
          });
        }

        final roleQuery = await FirebaseFirestore.instance
            .collection('usuarios_admins')
            .where('email', isEqualTo: email)
            .limit(1)
            .get();

        if (roleQuery.docs.isNotEmpty) {
          final roleData = roleQuery.docs.first.data();
          setState(() {
            userRole = roleData['role'] ?? 'Cliente';
          });
        }
      }
    }
  }

  Future<void> _editarNome() async {
    final TextEditingController _nomeController = TextEditingController(text: userName);

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar Nome'),
        content: TextField(
          controller: _nomeController,
          decoration: const InputDecoration(hintText: 'Digite seu nome'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              String novoNome = _nomeController.text.trim();
              if (novoNome.isNotEmpty && usuario != null) {
                final email = usuario!.email;

                final perfilQuery = await FirebaseFirestore.instance
                    .collection('perfil')
                    .where('email', isEqualTo: email)
                    .limit(1)
                    .get();

                if (perfilQuery.docs.isNotEmpty) {
                  await perfilQuery.docs.first.reference.update({'nome': novoNome});
                }

                setState(() {
                  userName = novoNome;
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  Future<void> _alterarFoto() async {
    final TextEditingController _fotoController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Alterar URL da Foto'),
        content: TextField(
          controller: _fotoController,
          decoration: const InputDecoration(hintText: 'Cole a URL da nova foto'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              String novaFotoUrl = _fotoController.text.trim();
              if (novaFotoUrl.isNotEmpty && usuario != null) {
                final email = usuario!.email;

                final perfilQuery = await FirebaseFirestore.instance
                    .collection('perfil')
                    .where('email', isEqualTo: email)
                    .limit(1)
                    .get();

                if (perfilQuery.docs.isNotEmpty) {
                  await perfilQuery.docs.first.reference.update({'fotoUrl': novaFotoUrl});
                }

                setState(() {
                  photoUrl = novaFotoUrl;
                });

                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('A URL da imagem está inválida ou vazia!')),
                );
              }
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

 void _alterarSenha() async {
  final usuario = FirebaseAuth.instance.currentUser;

  if (usuario != null && usuario.email != null) {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: usuario.email!);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('E-mail de redefinição de senha enviado para ${usuario.email!}'),
          backgroundColor: Colors.green,
        ),
      );
    } on FirebaseAuthException catch (e) {
      String mensagemErro = 'Erro ao enviar e-mail de redefinição de senha.';

      if (e.code == 'user-not-found') {
        mensagemErro = 'Usuário não encontrado.';
      } else if (e.code == 'invalid-email') {
        mensagemErro = 'E-mail inválido.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(mensagemErro),
          backgroundColor: Colors.red,
        ),
      );
    }
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Nenhum usuário logado.'),
        backgroundColor: Colors.orange,
      ),
    );
  }
}



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black12,
      appBar: AppBar(
        title: const Text('Minha Conta', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        centerTitle: true,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Container(
                  width: double.infinity,
                  constraints: BoxConstraints(
                    maxWidth: 500,
                    minHeight: constraints.maxHeight - kBottomNavigationBarHeight,
                  ),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.black26),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: _alterarFoto,
                        child: CircleAvatar(
                          radius: 50,
                          backgroundImage: NetworkImage(photoUrl),
                        ),
                      ),
                      const SizedBox(height: 15),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            userName,
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.black),
                            onPressed: _editarNome,
                          ),
                        ],
                      ),
                      Text(
                        usuario?.email ?? "usuario@email.com",
                        style: const TextStyle(fontSize: 16, color: Colors.black87),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        " $userRole",
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
                      ),
                      const SizedBox(height: 30),

                      // Opções (sem "Meus Endereços")
                      _buildListTile(Icons.password, 'Alterar Senha', _alterarSenha),
                      _buildListTile(Icons.logout, 'Sair', () {
                        FirebaseAuth.instance.signOut();
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => const LoginScreen()),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 2,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.black45,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Início'),
          BottomNavigationBarItem(icon: Icon(Icons.notifications_outlined), label: 'Notificações'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Minha Conta'),
        ],
        onTap: (int index) {
          if (index == 0) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const MyApp()),
            );
          } else if (index == 1) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const TelaGridNotificacoes()),
            );
          }
        },
      ),
    );
  }

  Widget _buildListTile(IconData icon, String title, VoidCallback onTap) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: Colors.black),
        title: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.black),
        onTap: onTap,
      ),
    );
  }
}
