import 'package:flutter/material.dart';

class StarPage extends StatelessWidget {
  const StarPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('즐겨찾기 목록'),
      ),
      body: const Center(
        child: Text(
          '즐겨찾기 페이지 내용',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
