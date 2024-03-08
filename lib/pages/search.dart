import 'package:flutter/material.dart';
// import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:parking_map/common/model.dart';
import 'dart:convert';
import 'package:parking_map/pages/home.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  TextEditingController searchController = TextEditingController();
  final List<SearchItem> _searchHistory = [];

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
          // input 칸의 내용이 바로바로 바뀔 때
          onChanged: (value) {
            _search(value);
          },
        ),
      ),
      body: ListView.builder(
        itemCount: _searchHistory.length,
        itemBuilder: (context, index) {
          final address = _searchHistory[index].address;
          return ListTile(
            title: Text(address ?? ''),
            onTap: () {
              debugPrint(
                  'click ${_searchHistory[index].address},${_searchHistory[index].latitude}, ${_searchHistory[index].longitude}');
              // _search(address ?? '정자역');
              // 선택 했을 경우 위경도 좌표를 던져서 새롭게 그리게 하면 됨,
              // 상위 페이지인 홈 페이지의 위경도를 갱신하면 된다.
            },
          );
        },
      ),
    );
  }

  Future<void> _search(String keyword) async {
    if (keyword.isEmpty) {
      // 검색어가 없을 경우 _serachhistory 데이터 초기화
      setState(() {
        _searchHistory.clear();
      });
      return;
    }
    debugPrint('_search call');
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
      List<dynamic> addresses =
          ((data['addresses'] ?? []) as List); // list에서 null 값 허용해줘야함
      setState(() {
        for (var element in addresses) {
          String? address = element['roadAddress'];
          double? lat = double.parse(element['y']);
          double? lng = double.parse(element['x']);
          SearchItem? addItem = SearchItem(address, lat, lng);
          _searchHistory.add(addItem);
        }
      });
    }
  }
}
