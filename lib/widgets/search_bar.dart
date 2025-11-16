import 'package:flutter/material.dart';
import '../modules/search_page/search_page.dart';

class SearchBarWidget extends StatelessWidget {
  const SearchBarWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return TextField(
      readOnly: true,
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const SearchPage()));
      },
      decoration: InputDecoration(
        hintText: 'Search for products...',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: const Icon(Icons.mic_none_outlined),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }
}

