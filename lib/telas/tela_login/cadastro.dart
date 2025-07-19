import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:myapp/main.dart';
import 'package:myapp/telas/tela_login/login.dart';

class CadastroScreen extends StatefulWidget {
  const CadastroScreen({super.key}); // adicionado const

  @override
  State<CadastroScreen> createState() => _CadastroScreenState();
}

class _CadastroScreenState extends State<CadastroScreen> {
  final auth = FirebaseAuth.instance;
  final provider = GoogleAuthProvider();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final _confirmarSenhaController = TextEditingController();
  bool _verSenha = false;

  Future<void> _signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      final GoogleSignInAuthentication? googleAuth =
          await googleUser?.authentication;

      if (googleAuth?.accessToken != null && googleAuth?.idToken != null) {
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth?.accessToken,
          idToken: googleAuth?.idToken,
        );
        await FirebaseAuth.instance.signInWithCredential(credential);
        // Navegue para a próxima tela após o login bem-sucedido
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (context) => MyApp()));
      }
    } catch (e) {
      print('Erro ao fazer login com o Google: $e');
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao logar com Google: $e')));
    }
  }
/*ESSA AQUI FAZ LOGIN!
  Future<void> _loginUser() async { // Removido o contexto como parâmetro
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword( // Use signInWithEmailAndPassword para login
        email: emailController.text,
        password: passwordController.text,
      );
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => MyApp()));
    } on FirebaseAuthException catch (e) {
      print('Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro de login: ${e.message}')));
    }
  }
*/

// PARA CADASTRAR UM USUARIO - CLIENTE OU ADMIN
  Future<void> _registerUser() async {
    try {
      // Cria o usuário no Firebase Auth
      UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text,
        password: passwordController.text,
      );

      // Salva dados do usuário na coleção "usuarios_admins"
      await FirebaseFirestore.instance
          .collection('usuarios_admins')
          .doc(userCredential.user!.uid) // usa o UID como ID do documento
          .set({
        'usuario': emailController.text,
        'createdAt': Timestamp.now(),
        'role': 'admin', // você pode customizar isso
      });

      // Navega para a próxima tela
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => MyApp()));
    } on FirebaseAuthException catch (e) {
      print('Erro: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao cadastrar: ${e.message}')),
      );
    }
  }

  void _salvarCadastro() {
    String senha = passwordController.text.trim();
    String confirmar = _confirmarSenhaController.text.trim();

    if (senha != confirmar) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('As senhas não coincidem.'))); // adicionado const
      return;
    }

    // Simula cadastro com sucesso e redireciona
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Cadastro realizado com sucesso!'))); // adicionado const
    // Aqui você deve adicionar a lógica real para salvar o cadastro no Firebase ou em outro banco de dados.
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Cadastro',
          style: TextStyle(color: Colors.white),
        ), // adicionado const
        backgroundColor:
            const Color.fromARGB(255, 50, 34, 25), // adicionado const
      ),
      body: Padding(
        padding: const EdgeInsets.all(20), // adicionado const
        child: ListView(
          children: [
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                // adicionado const
                labelText: 'CPF ou Email',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20), // adicionado const
            TextField(
              controller: passwordController,
              obscureText: !_verSenha,
              decoration: const InputDecoration(
                // adicionado const
                labelText: 'Senha',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20), // adicionado const
            TextField(
              controller: _confirmarSenhaController,
              obscureText: !_verSenha,
              decoration: InputDecoration(
                labelText: 'Confirme a sua Senha ',
                border: const OutlineInputBorder(), // adicionado const
                suffixIcon: IconButton(
                  icon: Icon(
                    _verSenha ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() {
                      _verSenha = !_verSenha;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 30), // adicionado const
            ElevatedButton(
              onPressed: _registerUser, // Corrigido: chamada do método
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    const Color.fromARGB(255, 52, 37, 27), // adicionado const
                padding: const EdgeInsets.symmetric(
                    horizontal: 50, vertical: 15), // adicionado const
              ),
              child: const Text(
                // adicionado const
                'Cadrastrar', // Mudado para Login, pois este botão faz login
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
            const SizedBox(height: 20), // adicionado const
          
          ],
        ),
      ),
    );
  }
}
