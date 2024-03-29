// ignore_for_file: unnecessary_null_comparison

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:parking_map/pages/search.dart';
import 'package:parking_map/pages/star.dart';
import 'package:parking_map/pages/mypageview.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';

enum FilterOption { free, paid, mixed, all } // 필터링 옵션들

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
  bool isFavorite = false; // 즐겨찾기 여부를 저장하는 변수
  Map<String, bool> favoriteStatusMap = {}; // 각 주차장의 즐겨찾기 상태를 저장하는 맵
  List<Map<String, dynamic>> filteredParkingData = []; // 필터링된 주차장 데이터를 저장할 리스트
  FilterOption selectedFilterOption = FilterOption.all; // 현재 선택된 필터 옵션

  final double _minZoom = 10.0;
  final double _maxZoom = 16.0;
  final double _maxTilt = 30.0;

  @override
  void initState() {
    super.initState();
    _loadParkingData();
    _loadFavoriteStatus();
  }

  // json 파일 불러오기
  Future<void> _loadParkingData() async {
    try {
      String jsonString =
          await rootBundle.loadString('assets/parking_info.json');
      setState(() {
        parkingData = json.decode(jsonString).cast<Map<String, dynamic>>();
      });
      await _filterParkingData(); // 데이터 로드 후 필터링 함수 호출
      await _addInfoWindows(); // 데이터 로드 후 정보창 추가
    } catch (e) {
      debugPrint('주차 데이터 로드 실패: $e');
    }
  }

  // 즐겨찾기 상태 불러오기
  Future<void> _loadFavoriteStatus() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<String>? favoriteList =
        prefs.getStringList('favoriteParkingList');
    if (favoriteList != null) {
      setState(() {
        for (String parkingName in favoriteList) {
          favoriteStatusMap[parkingName] = true;
        }
      });
    }
  }

  void _changeFilterOption(FilterOption option) async {
    setState(() {
      selectedFilterOption = option;
    });
    // 필터링된 주차장 데이터 업데이트
    await _filterParkingData();
  }

// 필터링된 주차장 데이터 업데이트
  Future<void> _filterParkingData() async {
    setState(() {
      if (selectedFilterOption == FilterOption.all) {
        filteredParkingData =
            List.from(parkingData); // 전체 옵션 선택 시, 모든 주차장 데이터 유지
      } else {
        filteredParkingData = parkingData
            .where((parking) => _filterParkingByOption(parking))
            .toList(); // 선택된 필터 옵션에 맞게 주차장 데이터 필터링
      }
    });
    // 필터링된 데이터로 정보창 추가
    await _addInfoWindows();

    debugPrint('필터링 데이터: $filteredParkingData');
  }

  bool _filterParkingByOption(Map<String, dynamic> parking) {
    switch (selectedFilterOption) {
      case FilterOption.free:
        debugPrint('무료 주차장 필터링: ${parking['chrge_clsf'] == '무료'}');
        return parking['chrge_clsf'] == '무료';
      case FilterOption.paid:
        debugPrint('유료 주차장 필터링: ${parking['chrge_clsf'] == '유료'}');
        return parking['chrge_clsf'] == '유료';
      case FilterOption.mixed:
        debugPrint('혼합 주차장 필터링: ${parking['chrge_clsf'] == '혼합'}');
        return parking['chrge_clsf'] == '혼합';
      case FilterOption.all:
        return true; // 모든 주차장을 반환합니다.
    }
  }

  String _getFilterOptionText(FilterOption option) {
    switch (option) {
      case FilterOption.free:
        return '무료';
      case FilterOption.paid:
        return '유료';
      case FilterOption.mixed:
        return '혼합';
      case FilterOption.all:
        return '전체';
    }
  }

  // 위치 허용 권한 함수
  Future<void> _requestLocationPermission() async {
    Map<Permission, PermissionStatus> status =
        await [Permission.location].request(); // [] 권한배열에 권한을 작성 -> 여기서는 음성인식만
    debugPrint('위치 서비스 허용: $status');
    if (await Permission.location.isGranted) {
      // 권한이 허용된 경우 위치 추적 모드를 활성화
      debugPrint(
          'Location permission granted. Enabling location tracking mode...');
      _mapController?.setLocationTrackingMode(NLocationTrackingMode.follow);
    } else {
      // 권한이 거부된 경우 사용자에게 메시지를 표시
      showDialog(
        context: context,
        builder: (BuildContext context) => AlertDialog(
          title: const Text('위치 권한 필요'),
          content: const Text('현재 위치를 찾기 위해서는 위치 권한이 필요합니다.'),
          actions: <Widget>[
            TextButton(
              child: const Text('확인'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          NaverMap(
            options: NaverMapViewOptions(
              locationButtonEnable: true, // 내 위치 표시 기능이라는데 구현 뷸가
              logoAlign: NLogoAlign.leftBottom, // 로고를 왼쪽 아래로 정렬합니다.
              logoMargin: const EdgeInsets.only(
                  bottom: 120, left: 10), // 로고의 마진을 설정합니다.
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
            onMapReady: (controller) async {
              debugPrint('지도가 준비되었습니다.');
              _mapController = controller; // 지도 컨트롤러 설정
              await _requestLocationPermission(); // 화면 로드 시 위치 권한 요청
              if (widget.selectedLatitude != null &&
                  widget.selectedLongitude != null &&
                  widget.selectedLatitude != 37.36771852000005 &&
                  widget.selectedLongitude != 127.1042703539339) {
                // await _addMarker(
                //     widget.selectedLatitude, widget.selectedLongitude);
                await _addInfoWindows(); // 데이터 로드가 완료되면 정보창 추가
              }
            },
          ),
          // 네이버맵 위로 쌓여야하기 때문에 뒤에 위치해야함.
          // appbar 역할을 하는 컨테이너
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Padding(
              padding:
                  const EdgeInsets.only(top: 30.0, left: 20.0, right: 20.0),
              child: Container(
                height:
                    MediaQuery.of(context).size.height * 0.151, // 화면 높이의 12%
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10.0),
                ),
                // 검색창 생성
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Align(
                            alignment: Alignment.topCenter,
                            child: Padding(
                              padding:
                                  const EdgeInsets.only(top: 8.0, bottom: 4.0),
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const SearchScreen(),
                                    ),
                                  );
                                },
                                child: const Text(
                                  '목적지 또는 주소 검색',
                                  style: TextStyle(
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const Icon(Icons.search),
                      ],
                    ),
                    const Divider(
                      // 화면 중간에 얇은 선 추가 해서 보기 좋게 함
                      color: Colors.grey,
                      thickness: 0.5,
                    ),
                    Padding(
                      padding: const EdgeInsets.only(
                          bottom: 14.0, left: 5.0, right: 5.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: RichText(
                              text: TextSpan(
                                style: DefaultTextStyle.of(context).style,
                                children: [
                                  TextSpan(
                                    text: ' ✔ 필터',
                                    style:
                                        Theme.of(context).textTheme.bodyLarge,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          DropdownButton<FilterOption>(
                            value: selectedFilterOption,
                            underline: Container(), // 드롭다운버튼 밑줄 없애기
                            onChanged: (FilterOption? option) {
                              if (option != null) {
                                setState(() {
                                  _changeFilterOption(option);
                                });
                              }
                            },
                            items:
                                FilterOption.values.map((FilterOption option) {
                              return DropdownMenuItem<FilterOption>(
                                value: option,
                                child: Text(_getFilterOptionText(option)),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // bottomnavigationbar 역할을 하는 컨테이너
          Positioned(
            bottom: 0,
            left: 80,
            right: 0,
            child: Container(
              height: MediaQuery.of(context).size.height * 0.15, // 화면 높이의 15%
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
                    height: 20,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 25.0), // 가로 방향으로만 패딩 추가
                    child: SizedBox(
                      height: MediaQuery.of(context).size.height * 0.05,
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
  Future<void> _addInfoWindows() async {
    final controller = _mapController;
    if (controller != null && filteredParkingData.isNotEmpty) {
      // 현재 지도에 표시된 모든 정보창 제거
      await controller.clearOverlays();

      // 필터링된 데이터를 기반으로 새로운 정보창 추가
      for (var parking in filteredParkingData) {
        final infoWindow = NInfoWindow.onMap(
          id: parking['prkplce_mnnmb'],
          text: "${parking['prkplce_nm']}", // 주차장명
          position: NLatLng(
              parking['prkplce_la'], parking['prkplce_lo']), // 주차장 위치(경도,위도)
        );
        await controller.addOverlay(infoWindow);

        // 정보창 터치 이벤트 리스너 등록
        infoWindow.setOnTapListener((NInfoWindow infoWindow) {
          _showParkingDetails(parking);
        });
      }
    }
  }

  // // 검색으로 불러온 위치정보에 마커 추가
  // Future<NMarker?> _addMarker(double latitude, double longitude) async {
  //   if (_mapController != null) {
  //     final marker = NMarker(
  //       id: '',
  //       position: NLatLng(widget.selectedLatitude, widget.selectedLongitude),
  //     );
  //     await _mapController!.addOverlay(marker);
  //     return Future.value(marker); // 마커를 Future로 감싸서 반환
  //   }
  //   // 지도 컨트롤러가 null이면 null을 Future로 감싸서 반환
  //   return Future.value(null);
  // }

  // 주차장 정보를 보여주는 다이얼로그 표시
  void _showParkingDetails(Map<String, dynamic> parkingData) async {
    final String parkingName = parkingData['prkplce_nm'];
    final bool isFavorite =
        favoriteStatusMap[parkingName] ?? false; // 해당 주차장의 즐겨찾기 상태 가져오기

    showDialog(
      context: context,
      builder: (context) {
        return PopScope(
          // 확인 버튼 이외의 동작 방지용
          canPop: false,
          child: AlertDialog(
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('주차장 정보'),
                IconButton(
                  icon: Icon(
                    isFavorite ? Icons.star : Icons.star_border,
                    color: isFavorite ? Colors.yellow : null,
                  ),
                  onPressed: () async {
                    debugPrint('버튼 눌렀는지 확인');
                    setState(() {
                      // 해당 주차장의 즐겨찾기 상태 토글
                      favoriteStatusMap[parkingName] =
                          !(favoriteStatusMap[parkingName] ?? false);
                    });

                    // 상태 변경 저장
                    if (favoriteStatusMap[parkingName] ?? false) {
                      // 즐겨찾기 상태인 경우 저장
                      await _saveFavoriteParking(parkingName);
                    } else {
                      // 즐겨찾기 상태가 아닌 경우 제거
                      await _removeFavoriteParking(parkingName);
                    }
                  },
                ),
              ],
            ),
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('주차장명: ${parkingData['prkplce_nm']}'),
                Text('주차장 구분: ${parkingData['prkplce_clsf']}'),
                Text('주차단위구획수: ${parkingData['prkucmprt_cnt']}'),
                Text('요금 구분: ${parkingData['chrge_clsf']}'),
                const SizedBox(
                  height: 30.0,
                ),
                const Text('* 즐겨찾기 버튼을 누른 후 확인 버튼을 누르면 적용됩니다.')
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

// 즐겨찾기에 주차장 정보 저장
  Future<void> _saveFavoriteParking(String parkingName) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    // 기존 즐겨찾기 목록을 불러오거나 빈 목록을 초기화합니다.
    List<String> favoriteParkingList =
        prefs.getStringList('favoriteParkingList') ?? [];

    // 현재 주차장의 이름을 즐겨찾기 목록에 추가합니다.
    favoriteParkingList.add(parkingName);

    debugPrint('주차장 이름: $parkingName');

    // 갱신된 즐겨찾기 목록을 저장합니다.
    await prefs.setStringList('favoriteParkingList', favoriteParkingList);

    debugPrint('주차장 정보가 즐겨찾기에 추가되었습니다.');
  }

  // 즐겨찾기에 주차장 정보 삭제
  Future<void> _removeFavoriteParking(String parkingName) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    // 기존 즐겨찾기 목록을 불러오거나 빈 목록을 초기화합니다.
    List<String> favoriteParkingList =
        prefs.getStringList('favoriteParkingList') ?? [];

    // 현재 주차장의 이름을 즐겨찾기 목록에서 제거합니다.
    favoriteParkingList.removeWhere((name) => name == parkingName);
    setState(() {
      favoriteStatusMap[parkingName] = false; // 해당 주차장의 즐겨찾기 상태 업데이트
    });

    debugPrint('주차장 삭제: $parkingName');

    // 갱신된 즐겨찾기 목록을 저장합니다.
    await prefs.setStringList('favoriteParkingList', favoriteParkingList);

    debugPrint('주차장 정보가 즐겨찾기에서 삭제되었습니다.');
  }
}
