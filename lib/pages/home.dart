// ignore_for_file: unnecessary_null_comparison

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:parking_map/pages/search.dart';
import 'package:parking_map/pages/star.dart';
import 'package:parking_map/pages/mypageview.dart';
// import 'package:http/http.dart' as http;

class HomePage extends StatefulWidget {
  final double selectedLatitude;
  final double selectedLongitude;

  const HomePage(
      {super.key,
      required this.selectedLatitude,
      required this.selectedLongitude});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Map<String, dynamic>> parkingData = []; // json 파일 list로 불러오기 위한 코드
  NaverMapController? _mapController; // 지도 컨트롤러 변수 -> 이게 핵심(컨트롤러 활성화)
  Map<String, dynamic> infoWindowsData = {}; // 정보창 데이터를 저장할 맵 변수

  final double _minZoom = 10.0;
  final double _maxZoom = 16.0;
  final double _maxTilt = 30.0;

  @override
  void initState() {
    super.initState();
    _loadParkingData();
  }

  // json 파일 불러오기
  Future<void> _loadParkingData() async {
    try {
      String jsonString =
          await rootBundle.loadString('assets/parking_info.json');
      setState(() {
        parkingData = json.decode(jsonString).cast<Map<String, dynamic>>();
      });
      // 데이터 로드가 완료되면 정보창 추가
      _addInfoWindows();
    } catch (e) {
      debugPrint('주차 데이터 로드 실패: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          NaverMap(
            options: NaverMapViewOptions(
              minZoom: _minZoom, // default is 0
              maxZoom: _maxZoom, // default is 21
              maxTilt: _maxTilt, // default is 63
              initialCameraPosition: widget.selectedLongitude != null
                  ? NCameraPosition(
                      target: NLatLng(
                          widget.selectedLatitude, widget.selectedLongitude),
                      zoom: 14.0,
                    )
                  : const NCameraPosition(
                      target: NLatLng(37.36771852000005,
                          127.1042703539339), // 초기 위치 설정(정자역)
                      zoom: 14.0,
                    ),
            ),
            onMapReady: (controller) {
              debugPrint('지도가 준비되었습니다.');
              _mapController = controller; // 지도 컨트롤러 설정
              if (widget.selectedLatitude != null &&
                  widget.selectedLongitude != null &&
                  widget.selectedLatitude != 37.36771852000005 &&
                  widget.selectedLongitude != 127.1042703539339) {
                _addMarker(widget.selectedLatitude, widget.selectedLongitude);
                _addInfoWindows(); // 데이터 로드가 완료되면 정보창 추가
                // 비동기 처리보다 동기 처리가 차라리 더빠름..
              }
            },
          ),

          // 네이버맵 위로 쌓여야하기 때문에 뒤에 위치해야함.
          // appbar 역할을 하는 컨테이너
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SearchScreen(),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(30.0),
                child: Container(
                  // margin: const EdgeInsets.all(30.0), // margin을 사용하여 상대적인 여백을 지정
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  // 검색창 생성
                  child: const Row(
                    children: [
                      Expanded(
                        child: Text(
                          '목적지 또는 주소 검색',
                          style: TextStyle(
                            color: Colors.grey,
                          ),
                        ),
                      ),
                      Icon(Icons.search),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // bottomnavigationbar 역할을 하는 컨테이너
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: MediaQuery.of(context).size.height * 0.12, // 화면 높이의 12%
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.3), // 그림자 색상 및 투명도 설정
                    spreadRadius: 5, // 그림자의 확산 정도
                    blurRadius: 7, // 그림자의 흐릿한 정도
                    offset: const Offset(0, 3), // 그림자의 위치 조정 (수평, 수직)
                  ),
                ],
              ),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.topCenter,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 15.0),
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const StarPage()),
                          );
                        },
                        child: RichText(
                          text: TextSpan(
                            style: DefaultTextStyle.of(context).style,
                            children: [
                              TextSpan(
                                text: ' ⭐ 즐겨찾기',
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  // 즐겨찾기 밑에 들어갈 pageview 적용된 컨테이너 추가하기
                  const SizedBox(
                    height: 10,
                  ),
                  Padding(
                    padding: const EdgeInsets.all(15.0),
                    child: Container(
                      height: MediaQuery.of(context).size.height * 0.01,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const MyPageView(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 지도에 띄울 수 있는 정보창(json 파일에서 불러올 데이터 선택헤서 불러옴)
  void _addInfoWindows() {
    final controller = _mapController;
    if (controller != null && parkingData.isNotEmpty) {
      for (var parking in parkingData) {
        final infoWindow = NInfoWindow.onMap(
          id: parking['prkplce_mnnmb'],
          text: "${parking['prkplce_nm']}", // 주차장명
          position: NLatLng(parking['prkplce_la'],
              parking['prkplce_lo']), // 주차장 표시하는 위치(경도,위도)
        );
        controller.addOverlay(infoWindow);
        // 정보창에 터치 이벤트 리스너 등록
        infoWindow.setOnTapListener((NInfoWindow infoWindow) {
          _showParkingDetails(
              parking); // 터치 이벤트 리스너 등록의 핵심코드(json 불러오는 parking으로 해결)
        });
      }
    }
  }

  // 검색으로 불러온 위치정보에 마커 추가
  void _addMarker(double latitude, double longitude) {
    if (_mapController != null) {
      final marker = NMarker(
        id: '',
        position: NLatLng(widget.selectedLatitude, widget.selectedLongitude),
      );
      _mapController!.addOverlay(marker);
    }
  }

  // 주차장 정보를 보여주는 다이얼로그 표시
  void _showParkingDetails(Map<String, dynamic> parkingData) {
    showDialog(
      context: context,
      builder: (context) {
        return PopScope(
          // 확인 버튼 이외의 동작 방지용
          canPop: false,
          child: AlertDialog(
            title: const Text('주차장 정보'),
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('주차장명: ${parkingData['prkplce_nm']}'),
                Text('주차장 구분: ${parkingData['prkplce_clsf']}'),
                Text('주차단위구획수: ${parkingData['prkucmprt_cnt']}'),
                Text('요금 구분: ${parkingData['chrge_clsf']}'),
                // 여기에 다른 주차장 정보 필드 추가
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('확인'),
              ),
            ],
          ),
        );
      },
    );
  }
}
