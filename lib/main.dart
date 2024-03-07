import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:parking_map/pages/home.dart';

void main() async {
  // 지도 초기화 하기
  WidgetsFlutterBinding.ensureInitialized();
  await NaverMapSdk.instance.initialize(clientId: 'm5t3bqnun7');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Parking Map',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.red),
        useMaterial3: true,
      ),
      home:
          const HomePage(title: 'parking_map', lat: 37.517305, lng: 127.047502),
    );
  }
}
