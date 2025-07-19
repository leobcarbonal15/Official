import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:myapp/main.dart';

class CadastroClienteScreen extends StatefulWidget {
  const CadastroClienteScreen({super.key});

  @override
  State<CadastroClienteScreen> createState() => _CadastroClienteScreenState();
}

class _CadastroClienteScreenState extends State<CadastroClienteScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmarSenhaController = TextEditingController();

  bool _verSenha = false;

  Future<void> _registerClient() async {
    try {
      // Cria o usuário no Firebase Auth
      UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      // Salva dados do cliente na coleção `usuarios_clientes`
      await FirebaseFirestore.instance
          .collection('usuarios_clientes')
          .doc(userCredential.user!.uid)
          .set({
        'usuario': emailController.text.trim(),
        'createdAt': Timestamp.now(),
        'role': 'cliente',
       
      });

      // Redireciona o usuário para a tela principal
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => MyApp()),
      );
    } on FirebaseAuthException catch (e) {
      print('Erro ao cadastrar cliente: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao cadastrar cliente: ${e.message}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cadastro Cliente', style: TextStyle(color: Colors.white)),
        
        backgroundColor: const Color.fromARGB(255, 50, 34, 25),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                  labelText: 'Email', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: passwordController,
              obscureText: !_verSenha,
              decoration: const InputDecoration(
                  labelText: 'Senha', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: confirmarSenhaController,
              obscureText: !_verSenha,
              decoration: InputDecoration(
                labelText: 'Confirme a Senha',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon:
                      Icon(_verSenha ? Icons.visibility_off : Icons.visibility),
                  onPressed: () {
                    setState(() {
                      _verSenha = !_verSenha;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 30),
           
            ElevatedButton(
              onPressed: _registerClient,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 52, 37, 27),
                padding:
                    const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
              ),
              child: const Text('Cadastrar Cliente',
                  style: TextStyle(color: Colors.white, fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}
