import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:myapp/main.dart';
import 'package:myapp/telas/perfil_usuario/usuario.dart';

class TelaGridNotificacoes extends StatefulWidget {
  const TelaGridNotificacoes({super.key});

  @override
  State<TelaGridNotificacoes> createState() => _TelaGridNotificacoesState();
}

class _TelaGridNotificacoesState extends State<TelaGridNotificacoes> {
  final Map<String, bool> _expandStates = {};

  @override
  Widget build(BuildContext context) {
    final email = FirebaseAuth.instance.currentUser?.email;

    if (email == null) {
      return Scaffold(
        body: Center(child: Text("Usuário não autenticado")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Minhas Notificações",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color.fromARGB(255, 0, 0, 0),
      ),
      backgroundColor: Color(0xFFFAF3E0),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('notificacoes')
            .where('email', isEqualTo: email)
            //.orderBy('data', descending: true) // Adicione novamente depois de criar o índice
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Erro: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("Nenhuma notificação."));
          }
          final notificacoes = snapshot.data!.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final produtos = data['produtos'] as List<dynamic>?;

            final produto = produtos != null && produtos.isNotEmpty
                ? produtos[0] as Map<String, dynamic>
                : {};

            return {
              'id': doc.id,
              'titulo': data['titulo'] ?? '',
              'mensagem': data['mensagem'] ?? '',
              'data': (data['data'] as Timestamp).toDate(),
              'nomeProduto': produto['nome'] ?? '',
              'imagem': produto['imagem'] ?? '',
            };
          }).toList();

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: notificacoes.length,
            itemBuilder: (context, index) {
              final notif = notificacoes[index];
              final id = notif['id'];
              final isExpanded = _expandStates[id] ?? false;

              return Dismissible(
                key: Key(id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  color: Color(0xFFFAF3E0),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                onDismissed: (_) async {
                  await FirebaseFirestore.instance
                      .collection('notificacoes')
                      .doc(id)
                      .delete();

                  setState(() {
                    _expandStates.remove(id);
                  });

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Notificação apagada")),
                  );
                },
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _expandStates[id] = !isExpanded;
                    });
                  },
                  child: Card(
                    color: const Color.fromARGB(255, 238, 238, 238),
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.notification_add_sharp,
                                  color: Colors.orange, size: 28),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  "Nova Notificação",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color.fromARGB(255, 24, 24, 24),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            notif['titulo'],
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Color.fromARGB(255, 24, 24, 24),
                            ),
                          ),
                          Text(
                            notif['nomeProduto'],
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Color.fromARGB(255, 24, 24, 24),
                            ),
                          ),
                          if (isExpanded) ...[
                            const SizedBox(height: 12),
                           
                            const Text(
                              'Seu produto foi separado e está pronto para pagamento e retirada na loja.',
                              style: TextStyle(
                                fontSize: 13,
                                color: Color.fromARGB(255, 24, 24, 24),
                              ),
                            ),
                          ],
                          const SizedBox(height: 10),
                          Text(
                            '${notif['data'].day.toString().padLeft(2, '0')}/${notif['data'].month.toString().padLeft(2, '0')} às ${notif['data'].hour.toString().padLeft(2, '0')}:${notif['data'].minute.toString().padLeft(2, '0')}',
                            style: const TextStyle(
                                fontSize: 12,
                                color: Color.fromARGB(255, 99, 99, 99)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: 'Início',
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
              MaterialPageRoute(builder: (context) => const MyApp()),
            );
          } else if (index == 2) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const TelaUsuario()),
            );
          }
        },
      ),
    );
  }
}
