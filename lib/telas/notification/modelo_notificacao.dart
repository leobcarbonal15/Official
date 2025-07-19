import 'package:cloud_firestore/cloud_firestore.dart';

class Notificacao {
  final String titulo;
  final String mensagem;
  final DateTime data;

  var lido;

  Notificacao({
    required this.titulo,
    required this.mensagem,
    required this.data,
  });

  factory Notificacao.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Notificacao(
      titulo: data['titulo'],
      mensagem: data['mensagem'],
      data: (data['data'] as Timestamp).toDate(),
    );
  }
}
