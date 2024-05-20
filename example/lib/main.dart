import 'package:flutter/material.dart';
import 'package:rfid_c72_plugin_example/raw_sql_list.dart';
import 'package:rfid_c72_plugin_example/rfid_scanner.dart';
import 'package:rfid_c72_plugin_example/scan_and_check.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: Future.delayed(const Duration(seconds: 2)),
      builder: ((context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return SafeArea(
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              home: const RfidScanner(),
              routes: {
                '/main1': (context) => const RfidScanner(),
                '/list': (context) => const SQLList(),
                //'/check': (context) => const ScanAndCheckView(),
              },
              // home: SQLList(),
            ),
          );
        } else {
          return const SafeArea(
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              home: SplashScreenTest(),
            ),
          );
        }
      }),
    );
  }
}

class SplashScreenTest extends StatelessWidget {
  const SplashScreenTest({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Colors.red,
        child: Center(
          child: Column(
            children: [
              Image.asset(
                'assets/images/c4_TT_Logo_RGB.png',
                scale: 10.0,
                width: 200.0,
                height: 200.0,
                color: Colors.white,
              ),
              const Text(
                'R&D',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 40,
                ),
              ),
              const Text(
                'Tool & Test Systems',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
