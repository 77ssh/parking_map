import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StarPage extends StatefulWidget {
  const StarPage({super.key});

  @override
  _StarPageState createState() => _StarPageState();
}

class _StarPageState extends State<StarPage> {
  List<String> favoriteParkingList = [];

  @override
  void initState() {
    super.initState();
    _loadFavoriteParkingList();
  }

  Future<void> _loadFavoriteParkingList() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<String>? favoriteList =
        prefs.getStringList('favoriteParkingList');
    debugPrint('정보 불러오는지 확인하기: $favoriteList');
    if (favoriteList != null) {
      setState(() {
        favoriteParkingList = favoriteList;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('즐겨찾기 목록'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 40.0),
            RichText(
              text: TextSpan(
                style: DefaultTextStyle.of(context).style,
                children: const <TextSpan>[
                  TextSpan(
                    text: ' ⭐ 즐겨찾기 목록입니다.',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                        fontSize: 20.0),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20.0),
            // 여기에 favoriteParkingList를 사용하여 즐겨찾기 목록을 표시하는 위젯을 추가하세요.
            favoriteParkingList.isNotEmpty
                ? ListView.builder(
                    shrinkWrap: true,
                    itemCount: favoriteParkingList.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        title: Text(favoriteParkingList[index]),
                      );
                    },
                  )
                : const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text(' 즐겨찾기 목록이 없습니다.'),
                  ),
          ],
        ),
      ),
    );
  }
}
