import 'package:flutter/material.dart';

class FilterPage extends StatelessWidget {
  const FilterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('필터 페이지'),
      ),
      body: const Center(
        child: Text(
          '필터 페이지 내용',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
