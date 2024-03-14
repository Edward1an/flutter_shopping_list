import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shopping_list/data/categories.dart';
import 'package:shopping_list/models/category.dart';
import 'package:shopping_list/models/grocery_item.dart';

class NewItem extends StatefulWidget {
  const NewItem({super.key});

  @override
  State<NewItem> createState() => _NewItemState();
}

class _NewItemState extends State<NewItem> {
  bool _isSending = false;
  final _formKey = GlobalKey<FormState>();
  var enteredName = "";
  int enteredQuantity = 1;
  Category enteredCategory = const Category("", Colors.white);

  void _saveItem() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSending = true;
      });
      _formKey.currentState!.save();
      final response = await http.post(
        Uri.https(
          "flutter-udemy-5ede6-default-rtdb.europe-west1.firebasedatabase.app",
          "shopping-list.json",
        ),
        headers: {"Content-Type": "applicaton/json"},
        body: json.encode(
          {
            "name": enteredName,
            "quantity": enteredQuantity,
            "category": enteredCategory.title,
          },
        ),
      );
      Map<String, dynamic> resData = json.decode(response.body);
      if (!context.mounted) {
        return;
      } else {
        // ignore: use_build_context_synchronously
        Navigator.of(context).pop(
          GroceryItem(
            id: resData['name'],
            name: enteredName,
            quantity: enteredQuantity,
            category: enteredCategory,
          ),
        );
      }
    }
  }

  void _resetItem() {
    _formKey.currentState!.reset();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("add a new item"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                decoration: const InputDecoration(
                  label: Text("Name"),
                ),
                maxLength: 50,
                onSaved: (newValue) {
                  enteredName = newValue!;
                },
                validator: (String? value) {
                  if (value == null ||
                      value.isEmpty ||
                      value.trim().length > 50 ||
                      value.trim().length <= 1) {
                    return "Enter the name";
                  } else {
                    return null;
                  }
                },
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextFormField(
                      keyboardType: TextInputType.number,
                      initialValue: enteredQuantity.toString(),
                      decoration: const InputDecoration(
                        label: Text("Quantity"),
                      ),
                      onSaved: (newValue) {
                        enteredQuantity = int.parse(newValue!);
                      },
                      validator: (String? value) {
                        if (value == null ||
                            value.isEmpty ||
                            int.tryParse(value) == null ||
                            int.tryParse(value)! <= 0) {
                          return "Enter the valid positive quantity";
                        } else {
                          return null;
                        }
                      },
                    ),
                  ),
                  const SizedBox(
                    width: 8,
                  ),
                  Expanded(
                    child: DropdownButtonFormField(
                        onSaved: (newValue) {
                          enteredCategory = newValue!;
                        },
                        items: [
                          for (var element in categories.entries)
                            DropdownMenuItem(
                              value: element.value,
                              child: Row(
                                children: [
                                  Container(
                                    color: element.value.categoryColor,
                                    height: 16,
                                    width: 16,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    element.value.title,
                                  ),
                                ],
                              ),
                            )
                        ],
                        onChanged: (value) {}),
                  ),
                ],
              ),
              const SizedBox(
                height: 16,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isSending ? null : _resetItem,
                    child: const Text("Reset"),
                  ),
                  ElevatedButton(
                    onPressed: _isSending ? null : _saveItem,
                    child: _isSending
                        ? const CircularProgressIndicator()
                        : const Text("Submit"),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
