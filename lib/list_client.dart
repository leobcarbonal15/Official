import 'package:flutter/material.dart';

import 'package:myapp/telas/notification/notificacoes_grid.dart';
import 'package:myapp/telas/perfil_usuario/usuario.dart';
import 'package:myapp/telas/telas_carrinho/carrinho.dart';

List<Widget> getClientDrawerItems(BuildContext context) {
  return [
    ListTile(
      leading: const Icon(Icons.notifications, color: Color(0xFF4E342E)),
      title: const Text('Notificações'),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const TelaGridNotificacoes()),
        );
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
  ];
}
//teste