import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:myapp/adm%20_e_pedidos/gerenciamento_pedidos.dart';
import 'package:myapp/adm%20_e_pedidos/gerenciamento_produtos.dart';
import 'package:myapp/tela_produtos/produtos_grid.dart';
import 'package:myapp/telas/notification/notificacoes_grid.dart';
import 'package:myapp/telas/tela_login/cadastro_cliente.dart';
import 'firebase_options.dart';

import 'package:myapp/tela_cadastro_produto/cadastro_produto.dart';
import 'package:myapp/tela_whats/tela_comunic.dart';

import 'package:myapp/telas/perfil_usuario/usuario.dart';
import 'package:myapp/telas/telas_carrinho/carrinho.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        useMaterial3: true,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      debugShowCheckedModeBanner: false,
      home: const MyHomePage(title: ''),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String userName = '';
  String userPhotoUrl = '';
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // Função para carregar os dados do usuário, incluindo foto e nome
  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final perfilRef =
          FirebaseFirestore.instance.collection('perfil').doc(user.uid);
      final perfilSnap = await perfilRef.get();

      String defaultPhoto =
          'https://png.pngtree.com/thumb_back/fh260/background/20220813/pngtree-rounded-raster-icon-with-cobalt-and-gray-color-scheme-for-user-profile-photo-image_19491244.jpg';

      setState(() {
        final perfilData = perfilSnap.data();
        userName =
            perfilData?['nome'] ?? user.displayName ?? user.email ?? 'Usuário';

        userPhotoUrl = perfilData?['fotoUrl'] ?? user.photoURL ?? defaultPhoto;

        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      drawer: Drawer(
        backgroundColor: Colors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: NetworkImage(
                    'https://wallpapers.com/images/featured-full/fundo-full-hd-vjzgi9qrproc2upa.jpg',
                  ),
                  fit: BoxFit.fill,
                ),
              ),
              padding: const EdgeInsets.all(10),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Column(
                  children: [
                    // Exibindo a foto do usuário
                    CircleAvatar(
                      radius: 40,
                      backgroundImage:
                          NetworkImage(userPhotoUrl), // Foto do perfil
                    ),
                    const SizedBox(height: 8),
                    Text(userName), // Nome do usuário
                  ],
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  ListTile(
                    leading: const Icon(Icons.notifications,
                        color: Color(0xFF4E342E)),
                    title: const Text('Notificações'),
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => TelaGridNotificacoes()));
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.shopping_cart,
                        color: Color(0xFF4E342E)),
                    title: const Text('Carrinho'),
                    onTap: () {
                      Navigator.push(context,
                          MaterialPageRoute(builder: (_) => CarrinhoMLApp()));
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.person, color: Color(0xFF4E342E)),
                    title: const Text('Minha conta'),
                    onTap: () {
                      Navigator.push(context,
                          MaterialPageRoute(builder: (_) => TelaUsuario()));
                    },
                  ),
                  ListTile(
                    leading:
                        const Icon(Icons.add_box, color: Color(0xFF4E342E)),
                    title: const Text('Cadastrar Produto'),
                    onTap: () {
                      Navigator.push(context,
                          MaterialPageRoute(builder: (_) => CadastroProduto()));
                    },
                  ),
                  ListTile(
                    leading:
                        const Icon(Icons.add_box, color: Color(0xFF4E342E)),
                    title: const Text('Cadastrar Cliente'),
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => CadastroClienteScreen()));
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.inventory_2_outlined,
                        color: Color(0xFF4E342E)),
                    title: const Text('Gerenciar Pedidos'),
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => TelaGerenciamentoPedidos()));
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.inventory_2_outlined,
                        color: Color(0xFF4E342E)),
                    title: const Text('Gerenciar Produtos'),
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => GerenciarProdutos()));
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      appBar: AppBar(
        backgroundColor: const Color(0xFF4E342E),
        toolbarHeight: MediaQuery.of(context).size.height * 0.1,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: SizedBox(
                height: 40,
                child: TextField(
                  cursorColor: const Color(0xFF4E342E),
                  style: const TextStyle(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Busque',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: const Icon(Icons.search),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              child: IconButton(
                icon: const Icon(Icons.phone, color: Colors.white),
                onPressed: () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (_) => TelaComunic()));
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              child: IconButton(
                icon: const Icon(Icons.shopping_cart, color: Colors.white),
                onPressed: () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (_) => CarrinhoMLApp()));
                },
              ),
            ),
          ],
        ),
      ),
      backgroundColor: const Color(0xFFFAF3E0),
      body: const ProdutosGrid(),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications_outlined),
            label: 'Notificações',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Minha Conta',
          ),
        ],
        onTap: (int index) {
          if (index == 0) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (context) => const MyHomePage(title: '')),
            );
          } else if (index == 1) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => TelaGridNotificacoes()),
            );
          } else if (index == 2) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => TelaUsuario()),
            );
          }
        },
      ),
    );
  }
}
