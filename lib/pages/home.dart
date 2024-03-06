import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:flutter/services.dart' show rootBundle;

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    required this.title,
  });

  final String title;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Map<String, dynamic>> parkingData = []; // json 파일 list로 불러오기 위한 코드
  NaverMapController? _mapController; // 지도 컨트롤러 변수 -> 이게 핵심(컨트롤러 활성화)

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
      body: NaverMap(
        options: const NaverMapViewOptions(
          minZoom: 10, // default is 0
          maxZoom: 16, // default is 21
          maxTilt: 30, // default is 63
          initialCameraPosition: NCameraPosition(
            target:
                NLatLng(37.36771850000052, 127.1042703539339), // 초기 위치 설정(정자역)
            zoom: 14.0,
          ),
        ),
        onMapReady: (controller) {
          debugPrint('지도가 준비되었습니다.');
          _mapController = controller; // 지도 컨트롤러 설정
        },
      ),
    );
  }

  void _addInfoWindows() {
    final controller = _mapController;
    if (controller != null && parkingData.isNotEmpty) {
      for (var parking in parkingData) {
        // 지도에 띄울 수 있는 정보창(마커 대신 사용)
        final infoWindow = NInfoWindow.onMap(
          id: parking['prkplce_mnnmb'],
          text: "${parking['prkplce_nm']}", // 주차장명
          position: NLatLng(parking['prkplce_la'],
              parking['prkplce_lo']), // 주차장 표시하는 위치(경도,위도)
        );
        controller.addOverlay(infoWindow);

        // 마커에 터치 이벤트 리스너 등록
        infoWindow.setOnTapListener((NInfoWindow infoWindow) {
          final infoWindowData = infoWindowsData[infoWindow.id];
          if (infoWindowData != null) {
            _showParkingDetails(infoWindowData);
          }
        });
      }
    }
  }

  // 주차장 정보를 보여주는 다이얼로그 표시
  void _showParkingDetails(Map<String, dynamic> parkingData) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('주차장 정보'),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('주차장명: ${parkingData['prkplce_nm']}'),
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
        );
      },
    );
  }
}
