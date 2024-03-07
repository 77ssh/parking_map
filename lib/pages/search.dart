import 'package:flutter/material.dart';
// import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:parking_map/pages/home.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  TextEditingController searchController = TextEditingController();
  final List<String> _searchHistory = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: searchController,
          decoration: const InputDecoration(
            hintText: '목적지 또는 주소 검색',
            border: InputBorder.none,
            suffixIcon: Icon(Icons.search),
          ),
          onSubmitted: (value) {
            _search(value);
          },
        ),
      ),
      body: ListView.builder(
        itemCount: _searchHistory.length,
        itemBuilder: (context, index) {
          final searchTerm = _searchHistory[index];
          return ListTile(
            title: Text(searchTerm),
            onTap: () {
              _search(searchTerm);
            },
          );
        },
      ),
    );
  }

  Future<void> _search(String keyword) async {
    // API 호출을 위한 키워드 인코딩
    String encodedKeyword = Uri.encodeComponent(keyword);

    // 네이버 지오코딩 API 호출 URL
    String apiUrl =
        'https://naveropenapi.apigw.ntruss.com/map-geocode/v2/geocode?query=$encodedKeyword';

    // 네이버 지오코딩 API 호출 및 응답 받기
    final response = await http.get(Uri.parse(apiUrl), headers: {
      'X-NCP-APIGW-API-KEY-ID': 'm5t3bqnun7', // 본인의 네이버 API 키 입력
      'X-NCP-APIGW-API-KEY':
          'o3Qmcdp6soqG8ihoPOwZeVmw1XDUh21ds6k3hA36', // 본인의 네이버 API 시크릿 키 입력
    });

    // API 응답 확인 (디버깅용)
    debugPrint('API 응답: ${response.body}');

    if (response.statusCode == 200) {
      // API 호출 성공 시 응답 데이터 파싱
      Map<String, dynamic> data = json.decode(response.body);

      // 검색 결과에서 좌표 추출
      List<dynamic> addresses = data['addresses'];
      if (addresses.isNotEmpty) {
        double lat = double.parse(addresses[0]['y']);
        double lng = double.parse(addresses[0]['x']);

        // 검색 결과를 홈 화면으로 전달하고 페이지 이동
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) =>
                HomePage(title: 'parking_map', lat: lat, lng: lng),
          ),
        );
      } else {
        // 검색 결과가 없는 경우 에러 메시지 출력
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('검색 결과가 없습니다.')),
        );
      }
    } else {
      // API 호출 실패 시 에러 메시지 출력
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('검색 중 오류가 발생했습니다.')),
      );
    }
  }
}
