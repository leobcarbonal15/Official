import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // IMPORTAÇÃO FIRESTORE
import 'package:url_launcher/url_launcher.dart';
import 'package:myapp/main.dart';

void main() {
  runApp(const TelaComunic());
}

class TelaComunic extends StatelessWidget {
  const TelaComunic({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Contato',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const MyHomePage(
        title: '',
        style: TextStyle(
          color: Color.fromARGB(255, 255, 255, 255),
          fontSize: 24.0,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title, required TextStyle style});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String? latestWhatsAppLink;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchLatestWhatsAppLink();
  }

  // Função para buscar o link mais recente do Firestore
  Future<void> fetchLatestWhatsAppLink() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('whats')
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        setState(() {
          latestWhatsAppLink = snapshot.docs.first['link'];
        });
      }
    } catch (e) {
      print('Erro ao buscar link do WhatsApp: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Função para abrir o link do WhatsApp, tratando o caso de falta de "https://"
  Future<void> _openWhatsAppLink() async {
    String url = latestWhatsAppLink ?? '';
    
    // Verifica se o link começa com http ou https, se não adicionar o https://
    if (!url.startsWith('http')) {
      url = 'https://' + url;  // Adiciona "https://" se não estiver presente
    }

    final uri = Uri.parse(url);
    
    // Tenta abrir o link
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível abrir o link.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF3E0),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 0, 0, 0),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () =>
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => MyApp())),
        ),
        title: Text(widget.title),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: <Widget>[
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    const Text(
                      "Fale com o vendedor",
                      style: TextStyle(
                        color: Color.fromARGB(255, 0, 0, 0),
                        fontSize: 24.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Padding(padding: EdgeInsets.all(16.0)),
                    Image.network(
                      'https://static.vecteezy.com/system/resources/previews/018/930/564/non_2x/whatsapp-logo-whatsapp-icon-whatsapp-transparent-free-png.png',
                      width: 150,
                      height: 150,
                    ),
                    const Padding(padding: EdgeInsets.all(16.0)),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                      onPressed: latestWhatsAppLink != null
                          ? _openWhatsAppLink  // Chama a nova função para abrir o link
                          : null,
                      icon: const Icon(Icons.chat, color: Colors.white),
                      label: const Text(
                        'Entre em contato via WhatsApp',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    const Padding(padding: EdgeInsets.all(16.0)),
                  ],
                ),
              ],
            ),
    );
  }
}
