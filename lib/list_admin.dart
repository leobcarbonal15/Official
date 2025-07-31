import 'package:firebase_auth/firebase_auth.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:myapp/adm _e_pedidos/estatisticas.dart';
import 'package:myapp/adm _e_pedidos/gerenciamento_produtos.dart';
import 'package:myapp/adm%20_e_pedidos/estoque.dart';
import 'package:myapp/telas/notification/notificacoes_grid.dart';
import 'package:myapp/telas/perfil_usuario/usuario.dart';
import 'package:myapp/tela_cadastro_produto/cadastro_produto.dart';
import 'package:myapp/adm _e_pedidos/gerenciamento_pedidos.dart';
import 'package:myapp/telas/tela_login/cadastro.dart';
import 'package:myapp/telas/telas_carrinho/carrinho.dart';

// Função para apagar todos os documentos antigos na coleção 'whats'
Future<void> _deleteOldWhatsAppLink() async {
  try {
    final snapshot = await FirebaseFirestore.instance.collection('whats').get();
    for (var doc in snapshot.docs) {
      await doc.reference.delete();
    }
  } catch (e) {
    print('Erro ao apagar link antigo: $e');
  }
}

// Diálogo para cadastrar link e número do WhatsApp
void _showWhatsAppInputDialog(BuildContext context) {
  final TextEditingController _linkController = TextEditingController();
  final TextEditingController _numeroController = TextEditingController();

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Cadastrar link e número do WhatsApp'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _numeroController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(hintText: 'Digite o número do WhatsApp'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _linkController,
            decoration: const InputDecoration(hintText: 'Digite o link aqui'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () async {
            final link = _linkController.text.trim();
            final numero = _numeroController.text.trim();

            if (link.isNotEmpty && numero.isNotEmpty) {
              await _deleteOldWhatsAppLink();

              await FirebaseFirestore.instance.collection('whats').add({
                'link': link,
                'numero': numero,
                'createdAt': Timestamp.now(),
              });

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Link e número do WhatsApp salvos!')),
              );

              Navigator.of(context).pop();
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Por favor, preencha link e número.')),
              );
            }
          },
          child: const Text('Salvar'),
        ),
      ],
    ),
  );
}

// Diálogo para cadastrar chave Pix
void _mostrarDialogoChavePix(BuildContext context) {
  final TextEditingController chaveController = TextEditingController();
  final user = FirebaseAuth.instance.currentUser;

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Cadastrar chave Pix'),
      content: TextField(
        controller: chaveController,
        decoration: const InputDecoration(
          hintText: 'Digite a chave Pix (CPF, e-mail, telefone)',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () async {
            final chavePix = chaveController.text.trim();
            if (chavePix.isNotEmpty && user != null) {
              try {
                final snapshot = await FirebaseFirestore.instance
                    .collection('chaves_pix')
                    .where('uid', isEqualTo: user.uid)
                    .get();

                for (var doc in snapshot.docs) {
                  await doc.reference.delete();
                }

                await FirebaseFirestore.instance.collection('chaves_pix').add({
                  'chave': chavePix,
                  'uid': user.uid,
                  'dataCadastro': Timestamp.now(),
                });

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Chave Pix salva com sucesso!')),
                );

                Navigator.of(context).pop();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Erro ao salvar chave Pix: $e')),
                );
              }
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Chave Pix inválida!')),
              );
            }
          },
          child: const Text('Salvar'),
        ),
      ],
    ),
  );
}

// Função que retorna os itens do Drawer para o Admin
List<Widget> getAdminDrawerItems(BuildContext context) {
  return [
    ListTile(
      leading: const Icon(Icons.notifications, color: Color(0xFF4E342E)),
      title: const Text('Notificações'),
      onTap: () {
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => TelaGridNotificacoes()));
      },
    ),
    ListTile(
      leading: const Icon(Icons.shopping_cart, color: Color(0xFF4E342E)),
      title: const Text('Carrinho'),
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => CarrinhoMLApp()));
      },
    ),
    ListTile(
      leading: const Icon(Icons.person, color: Color(0xFF4E342E)),
      title: const Text('Minha conta'),
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => TelaUsuario()));
      },
    ),
    ListTile(
      leading: const Icon(Icons.add_box, color: Color(0xFF4E342E)),
      title: const Text('Cadastrar Produto'),
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => CadastroProduto()));
      },
    ),
    ListTile(
      leading: const Icon(Icons.add_box, color: Color(0xFF4E342E)),
      title: const Text('Cadastrar Usuario Admin'),
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => CadastroScreen()));
      },
    ),
    ListTile(
      leading: const Icon(Icons.local_shipping_outlined, color: Color(0xFF4E342E)),
      title: const Text('Gerenciar Pedidos'),
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => TelaGerenciamentoPedidos()));
      },
    ),
    ListTile(
      leading: const Icon(Icons.inventory_2_outlined, color: Color(0xFF4E342E)),
      title: const Text('Gerenciar Produtos'),
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => GerenciarProdutos()));
      },
    ),
    ListTile(
      leading: const Icon(Icons.equalizer_outlined, color: Color(0xFF4E342E)),
      title: const Text('Estatísticas'),
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const EstatisticasPage()));
      },
    ),
    ListTile(
      leading: const FaIcon(FontAwesomeIcons.whatsapp, color: Color(0xFF4E342E)),
      title: const Text('Link e Número do WhatsApp'),
      onTap: () {
        _showWhatsAppInputDialog(context);
      },
    ),
    ListTile(
      leading: const FaIcon(FontAwesomeIcons.coins, color: Color(0xFF4E342E)),
      title: const Text('Chave Pix'),
      onTap: () {
        _mostrarDialogoChavePix(context);
      },
    ),
    ListTile(
      leading: const FaIcon(FontAwesomeIcons.store, color: Color(0xFF4E342E)),
      title: const Text('Estoque'),
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => EstoqueHortifrutiPage()));
      },
    ),
  ];
}
