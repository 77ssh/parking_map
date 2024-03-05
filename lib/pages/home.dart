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
  List<Map<String, dynamic>> parkingData = [];

  @override
  void initState() {
    super.initState();
    _loadParkingData();
  }

  Future<void> _loadParkingData() async {
    try {
      String jsonString =
          await rootBundle.loadString('assets/parking_info.json');
      setState(() {
        parkingData = json.decode(jsonString).cast<Map<String, dynamic>>();
      });
    } catch (e) {
      debugPrint('주차 데이터 로드 실패: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NaverMap(
        options: const NaverMapViewOptions(
          minZoom: 10, // 기본값은 0
          maxZoom: 18, // 기본값은 21
          maxTilt: 30, // 기본값은 63
          initialCameraPosition: NCameraPosition(
            target: NLatLng(37.5665, 126.9780), // 초기 중심 위치 (서울)
            zoom: 20.0, // 초기 줌 레벨
          ),
        ),
        onMapReady: (controller) {
          for (var parking in parkingData) {
            final marker = NMarker(
              id: parking['prkplce_nm'], // 마커 ID
              position: NLatLng(parking['prkplce_la'], parking['prkplce_lo']),
            );
            controller.addOverlay(marker);
          }
        },
      ),
    );
  }
}
