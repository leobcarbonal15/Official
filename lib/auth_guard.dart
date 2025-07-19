// auth_guard.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:myapp/telas/tela_login/login.dart';  // Substitua com a tela de login do seu app

class AuthGuard {
  static Widget checkUserLogin({required Widget authenticatedScreen}) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      // Se o usuário não estiver logado, redireciona para a tela de login
      return const LoginScreen(); // Altere para o nome da sua tela de login
    }

    // Se o usuário estiver logado, retorna a tela autenticada
    return authenticatedScreen;
  }
}
