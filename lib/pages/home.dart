import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:parking_map/pages/search.dart';
// import 'package:http/http.dart' as http;

class HomePage extends StatefulWidget {
  final double? lat;
  final double? lng;

  const HomePage({
    super.key,
    required this.title,
    required this.lat,
    required this.lng,
  });

  final String title;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Map<String, dynamic>> parkingData = []; // json 파일 list로 불러오기 위한 코드
  NaverMapController? _mapController; // 지도 컨트롤러 변수 -> 이게 핵심(컨트롤러 활성화)
  Map<String, dynamic> infoWindowsData = {}; // 정보창 데이터를 저장할 맵 변수

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
            options: const NaverMapViewOptions(
              minZoom: 10, // default is 0
              maxZoom: 16, // default is 21
              maxTilt: 30, // default is 63
              initialCameraPosition: NCameraPosition(
                target: NLatLng(
                    37.36771850000052, 127.1042703539339), // 초기 위치 설정(정자역)
                zoom: 14.0,
              ),
            ),
            onMapReady: (controller) {
              debugPrint('지도가 준비되었습니다.');
              _mapController = controller; // 지도 컨트롤러 설정
            },
          ),
          // 네이버맵 위로 쌓여야하기 때문에 뒤에 위치해야함.
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
        ],
      ),
    );
  }

  // 지도에 띄울 수 있는 정보창(마커 대신 사용)
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
