import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:myapp/tela_produtos/produtos_grid.dart';
import 'package:myapp/telas/notification/notificacoes_grid.dart';

import 'firebase_options.dart';

import 'package:myapp/tela_whats/tela_comunic.dart';

import 'package:myapp/telas/perfil_usuario/usuario.dart';
import 'package:myapp/telas/telas_carrinho/carrinho.dart';
import 'auth_guard.dart';
import 'list_client.dart';
import 'list_admin.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(useMaterial3: true,    iconTheme: IconThemeData(color: Colors.white), ),
      debugShowCheckedModeBanner: false,
      home: AuthGuard.checkUserLogin(authenticatedScreen: const MyHomePage(title: '')),
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
  String userRole = '';
  String userPhotoUrl = ''; // Adicionando a variável para a URL da foto
  bool loading = true;
  String searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // Carregar dados do usuário, incluindo a foto de perfil
  Future<void> _loadUserData() async {
  final user = FirebaseAuth.instance.currentUser;

  if (user != null && user.email != null) {
    final email = user.email!;

    // Buscando dados do perfil (nome e foto)
    final perfilQuery = await FirebaseFirestore.instance
        .collection('perfil')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();

    if (perfilQuery.docs.isNotEmpty) {
      final perfilData = perfilQuery.docs.first.data();

      setState(() {
        userName = perfilData['nome'] ?? user.email!;
        userPhotoUrl = perfilData['fotoUrl'] ??
            'https://png.pngtree.com/thumb_back/fh260/background/20220813/pngtree-rounded-raster-icon-with-cobalt-and-gray-color-scheme-for-user-profile-photo-image_19491244.jpg';
      });
    } else {
      // Dados de perfil não encontrados, usar valores padrões
      setState(() {
        userName = user.email!;
        userPhotoUrl =
            'https://png.pngtree.com/thumb_back/fh260/background/20220813/pngtree-rounded-raster-icon-with-cobalt-and-gray-color-scheme-for-user-profile-photo-image_19491244.jpg';
      });
    }

    // Buscando o cargo (role)
    final roleQuery = await FirebaseFirestore.instance
        .collection('usuarios_admins')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();

    if (roleQuery.docs.isNotEmpty) {
      setState(() {
        userRole = roleQuery.docs.first.data()['role'] ?? 'cliente';
      });
    } else {
      setState(() {
        userRole = 'cliente';
      });
    }
  }

  setState(() {
    loading = false;
  });
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
                    'https://neon.com.br/aprenda/wp-content/uploads/2024/09/Quantas-pecas-de-roupa-preciso-para-abrir-uma-loja.webp',
                  ),
                  fit: BoxFit.fill,
                ),
              ),
              padding: const EdgeInsets.all(10),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Column(
                  children: [
                    // Exibindo a foto de perfil do usuário
                    CircleAvatar(
                      radius: 40,
                      backgroundImage: NetworkImage(userPhotoUrl), // Foto do perfil
                    ),
                    const SizedBox(height: 8),
                    Text(userName, style: TextStyle(color: Colors.white)), // Nome do usuário com cor branca
                  ],
                ),
              ),
            ),
            Expanded(
              child: FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('usuarios_admins')
                    .doc(FirebaseAuth.instance.currentUser?.uid)
                    .get(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return const Center(child: Text("Erro ao carregar os dados"));
                  } else {
                    String userRole = 'cliente';

                    if (snapshot.hasData && snapshot.data!.exists) {
                      userRole = snapshot.data!['role'] ?? 'cliente';
                    }

                    print("User Role: $userRole");

                    return ListView(
                      padding: EdgeInsets.zero,
                      children: userRole == 'admin'
                          ? getAdminDrawerItems(context)
                          : getClientDrawerItems(context),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
 appBar: AppBar(
  backgroundColor: Colors.black,  // trocar marrom por preto
  toolbarHeight: MediaQuery.of(context).size.height * 0.1,
  iconTheme: const IconThemeData(color: Color(0xFFFFD700)), // ícone do menu drawer dourado
  title: Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Expanded(
        child: SizedBox(
          height: 40,
          child: TextField(
            controller: _searchController,
            onChanged: (value) {
              setState(() {
                searchQuery = value;
              });
            },
            cursorColor: Colors.black,  // cursor preto, para combinar com a nova cor da appbar
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
          icon: const Icon(Icons.phone, color: Color(0xFFFFD700)), // dourado
          onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => TelaComunic()));
          },
        ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10.0),
        child: IconButton(
          icon: const Icon(Icons.shopping_cart, color: Color(0xFFFFD700)), // dourado
          onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => CarrinhoMLApp()));
          },
        ),
      ),
    ],
  ),
),

      backgroundColor: const Color(0xFFFAF3E0),
      body: ProdutosGrid(searchQuery: searchQuery), // Aqui a busca está sendo aplicada
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
              MaterialPageRoute(builder: (context) => const MyHomePage(title: '')),
            );
          } else if (index == 1) {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => TelaGridNotificacoes()));
          } else if (index == 2) {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => TelaUsuario()));
          }
        },
      ),
    );
  }
}
