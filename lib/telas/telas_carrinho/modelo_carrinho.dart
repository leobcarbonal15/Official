import 'package:cloud_firestore/cloud_firestore.dart';

class Produto {
  final String nome;
  final double preco;
  final String imagemUrl;

  Produto({
    required this.nome,
    required this.preco,
    required this.imagemUrl,
  });
}

class CarrinhoModel {
  static final CarrinhoModel _instancia = CarrinhoModel._interno();

  factory CarrinhoModel() {
    return _instancia;
  }

  CarrinhoModel._interno();

  final List<Produto> _itens = [];
  Map<String, dynamic>? _endereco; // Armazenar o endereço aqui

  List<Produto> get itens => _itens;

  Map<String, dynamic>? get endereco => _endereco;

  // Adiciona um produto ao carrinho
  void adicionarProduto(Produto produto) {
    _itens.add(produto);
  }

  // Define o endereço de entrega
  void definirEndereco(Map<String, dynamic> endereco) {
    _endereco = endereco;
  }

  // Limpar o carrinho
  void limparCarrinho() {
    _itens.clear();
    _endereco = null; // Limpa o endereço também
  }

  // Função para finalizar a compra e salvar no Firestore
  Future<void> finalizarCompra() async {
    if (_itens.isEmpty || _endereco == null) {
      throw Exception('Carrinho vazio ou endereço não fornecido!');
    }

    final produtos = _itens.map((produto) => {
          'nome': produto.nome,
          'preco': produto.preco,
          'imagem': produto.imagemUrl,
        }).toList();

    // Salvar o pedido no Firestore
    await FirebaseFirestore.instance.collection('pedidos').add({
      'data': Timestamp.now(),
      'produtos': produtos,
      'enderecoEntrega': _endereco, // Adiciona o endereço ao pedido
    });

    limparCarrinho(); // Limpa o carrinho após finalizar
  }
}
