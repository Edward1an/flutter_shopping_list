import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shopping_list/data/categories.dart';
import 'package:shopping_list/models/grocery_item.dart';
import 'package:shopping_list/widgets/new_item.dart';

class ShoppingList extends StatefulWidget {
  const ShoppingList({super.key});

  @override
  State<ShoppingList> createState() => _ShoppingListState();
}

class _ShoppingListState extends State<ShoppingList> {
  late Future<List<GroceryItem>> _futureData;
  @override
  void initState() {
    super.initState();
    _futureData = loadItems();
  }

  Future<List<GroceryItem>> loadItems() async {
    final getResponse = await http.get(
      Uri.https(
        "flutter-udemy-5ede6-default-rtdb.europe-west1.firebasedatabase.app",
        "shopping-list.json",
      ),
    );
    if (getResponse.statusCode >= 400) {
      throw Exception("error somewhere in the bachkend");
    }
    if (getResponse.body == "null") {
      return [];
    }
    final newGroceryItem = json.decode(getResponse.body);
    print(getResponse.body);
    final List<GroceryItem> loadedItems = [];
    for (var element in newGroceryItem.entries) {
      final category = categories.entries
          .firstWhere(
              (catItem) => catItem.value.title == element.value["category"])
          .value;
      loadedItems.add(GroceryItem(
        id: element.key,
        name: element.value["name"],
        quantity: element.value["quantity"],
        category: category,
      ));
    }
    return loadedItems;
  }

  final List<GroceryItem> _groceryList = [];

  void addItem() async {
    final resGroceryItem = await Navigator.of(context).push<GroceryItem>(
      MaterialPageRoute(
        builder: (builder) => const NewItem(),
      ),
    );

    if (resGroceryItem == null) {
      return;
    }

    setState(() {
      _groceryList.add(resGroceryItem);
      _futureData = loadItems();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        floatingActionButton: FloatingActionButton(
          onPressed: addItem,
          child: const Icon(Icons.add),
        ),
        appBar: AppBar(
          title: const Text(
            "Your groceries",
          ),
        ),
        body: FutureBuilder(
          future: _futureData,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }
            if (snapshot.hasError) {
              return Center(child: Text(snapshot.error.toString()));
            }
            if (snapshot.data!.isEmpty) {
              const Center(
                child: Text("No items added yet"),
              );
            }
            return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: ((ctx, index) {
                return Dismissible(
                  onDismissed: (direction) async {
                    final item = snapshot.data![index];
                    final shoppingId = item.id;
                    setState(() {
                      snapshot.data!.removeAt(index);
                    });
                    final response = await http.delete(
                      Uri.https(
                        "flutter-udemy-5ede6-default-rtdb.europe-west1.firebasedatabase.app",
                        "shopping-list/$shoppingId.json",
                      ),
                    );
                    if (response.statusCode >= 400) {
                      setState(() {
                        snapshot.data!.insert(index, item);
                      });
                    }
                  },
                  key: ValueKey<GroceryItem>(snapshot.data![index]),
                  child: ListTile(
                    onFocusChange: (value) {},
                    leading: Container(
                      color: snapshot.data![index].category.categoryColor,
                      width: 30,
                      height: 30,
                    ),
                    title: Text(snapshot.data![index].name),
                    trailing: Text(
                      snapshot.data![index].quantity.toString(),
                    ),
                  ),
                );
              }),
            );
          },
        ));
  }
}
