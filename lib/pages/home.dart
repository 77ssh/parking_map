import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'dart:convert';
import 'dart:io';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.title});
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
      File file = File('assets/parking_info.json'); // JSON 파일 경로
      String jsonString = await file.readAsString();
      setState(() {
        parkingData = json.decode(jsonString).cast<Map<String, dynamic>>();
      });
    } catch (e) {
      debugPrint('Failed to load parking data: $e');
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
                NLatLng(37.5665, 126.9780), // Initial center position (Seoul)
            zoom: 12.0, // Initial zoom level
          ),
        ),
        onMapReady: (controller) {
          _buildMarkers(controller);
          // debugPrint("네이버 맵 로딩 완료");
        },
      ),
    );
  }

  void _buildMarkers(NaverMapController controller) {
    Set<NMarker> markers = parkingData.map((parking) {
      return NMarker(
        id: (parking['prkplce_nm']),
        position: NLatLng(parking['prkplce_la'], parking['prkplce_lo']),
      );
    }).toSet();

  controller. = markers;
  }
}
