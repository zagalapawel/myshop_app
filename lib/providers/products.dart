import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import './product.dart';
import '../models/http_exception.dart';

class Products with ChangeNotifier {
  List<Product> _items = [];

  final String authToken;
  final String userId;

  Products(this.authToken, this.userId, this._items);

  List<Product> get items {
    return [..._items];
  }

  List<Product> get favoriteItems {
    return _items.where((prodItem) => prodItem.isFavorite).toList();
  }

  Product findById(String id) {
    return _items.firstWhere((prod) => prod.id == id);
  }

  Future<void> fetchAndSetProducts([bool filterByUser = false]) async {
    if (authToken == null) return; //Obejście HotReload

    var url = Uri.https(
      'fluttershopapp-a7999-default-rtdb.europe-west1.firebasedatabase.app',
      '/products.json',
      filterByUser
          ? {
              'auth': authToken,
              'orderBy': json.encode('creatorId'),
              'equalTo': json.encode(userId),
            }
          : {'auth': authToken},
    );
    try {
      final response = await http.get(url);
      final extractedData = json.decode(response.body) as Map<String, dynamic>;
      final List<Product> loadedProducts = [];
      if (extractedData == null) {
        _items = loadedProducts;
        notifyListeners();
        return;
      }
      url = Uri.https(
        'fluttershopapp-a7999-default-rtdb.europe-west1.firebasedatabase.app',
        '/userFavorites/$userId.json',
        {'auth': authToken},
      );
      final favoriteResponse = await http.get(url);
      final favoriteData = json.decode(favoriteResponse.body);
      // final List<Product> loadedProducts = [];
      extractedData.forEach((prodId, prodData) {
        loadedProducts.add(Product(
          id: prodId,
          title: prodData['title'],
          description: prodData['description'],
          price: prodData['price'],
          isFavorite: favoriteData == null ? false : favoriteData[prodId] ?? false,
          imageUrl: prodData['imageUrl'],
        ));
      });
      _items = loadedProducts;
      notifyListeners();
    } catch (error) {
      print(error);
      throw (error);
    }
  }

  Future<void> addProduct(Product product) async {
    final url = Uri.https(
      'fluttershopapp-a7999-default-rtdb.europe-west1.firebasedatabase.app',
      '/products.json',
      {'auth': authToken},
    );
    try {
      final response = await http.post(
        url,
        body: json.encode(
            //json.encode pochodzi z importu dart:convert
            {
              'title': product.title,
              'description': product.description,
              'imageUrl': product.imageUrl,
              'price': product.price,
              'creatorId': userId,
            }),
      );

      print('JSON body:  ${json.decode(response.body)}');
      final newProduct = Product(
        title: product.title,
        description: product.description,
        price: product.price,
        imageUrl: product.imageUrl,
        id: json.decode(response.body)['name'], //unikalne id nadawane przez firebase
      );
      _items.add(newProduct);
      //_items.insert(0, newProduct); //dodanie na początku listy

      notifyListeners();
    } catch (error) {
      print(error);
      throw error;
    }
  }

  Future<void> updateProduct(String id, Product newProduct) async {
    final url = Uri.https(
      'fluttershopapp-a7999-default-rtdb.europe-west1.firebasedatabase.app',
      '/products/$id.json',
      {'auth': authToken},
    );
    http.patch(
      url,
      body: json.encode(
        {
          'title': newProduct.title,
          'description': newProduct.description,
          'imageUrl': newProduct.imageUrl,
          'price': newProduct.price,
        },
      ),
    );
    final prodIndex = _items.indexWhere((prod) => prod.id == id);
    if (prodIndex >= 0) {
      _items[prodIndex] = newProduct;
      notifyListeners();
    } else {
      print('...');
    }
  }

  Future<void> deleteProducts(String id) async {
    final url = Uri.https(
      'fluttershopapp-a7999-default-rtdb.europe-west1.firebasedatabase.app',
      '/products/$id.json',
      {'auth': authToken},
    );
    final urlFav = Uri.https(
      'fluttershopapp-a7999-default-rtdb.europe-west1.firebasedatabase.app',
      '/userFavorites/$userId/$id.json',
      {'auth': authToken},
    );
    final existingProductIndex = _items.indexWhere((prod) => prod.id == id);
    var existingProduct = _items[existingProductIndex];
    //"optimistic update" - usuwamy obiekt z pamięci lokalnej, następnie z firebase -> jeśli usuwanie z firebase się nie uda to dodajemy obiekt do pamięci lokalnej
    _items.removeAt(existingProductIndex);
    notifyListeners();
    final response = await http.delete(url);
    final responseFav = await http.delete(urlFav);
    if (response.statusCode >= 400 || responseFav.statusCode >= 400) {
      _items.insert(existingProductIndex, existingProduct);
      notifyListeners();
      throw HttpException('Cloud not delete product.');
    }
    existingProduct = null;
  }
}
