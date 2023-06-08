import 'package:beatcoin/pages/devices.dart';
import 'package:beatcoin/pages/home.dart';
import 'package:beatcoin/pages/leaderboard.dart';
import 'package:beatcoin/pages/profile.dart';
import 'package:beatcoin/pages/workout.dart';
import 'package:beatcoin/polar/polar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_state_manager/get_state_manager.dart';
import 'package:polar/polar.dart';
import 'package:salomon_bottom_bar/salomon_bottom_bar.dart';
import 'package:uuid/uuid.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  Get.put(PolarController());

  runApp(const MyApp());
}

/// Example app
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  var _currentIndex = 0;

  Widget _selectedPage() {
    switch (_currentIndex) {
      case 1:
        return WorkoutPage();
      case 2:
        return LeaderboardPage();
      case 3:
        return ProfilePage();
      case 4:
        return DevicesPage();
      default:
        return HomePage();
    }
  }

  @override
  Widget build(BuildContext context) {
    PolarController polarController = Get.find();

    return MaterialApp(
      theme: ThemeData(
        fontFamily: 'Sora',
        textTheme: Typography.blackMountainView,
      ),
      home: Scaffold(
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.white,
          leading: IconButton(
            icon: Obx(
              () => Icon(
                polarController.isDeviceConnected.value
                    ? Icons.heart_broken
                    : Icons.heart_broken_outlined,
                color: Colors.red[400],
              ),
            ),
            onPressed: () {
              setState(() {
                _currentIndex = 4;
              });
            },
          ),
          title: Obx(
            () => polarController.isDeviceConnected.value
                ? Text(
                    polarController.heartRate.string,
                    style: TextStyle(
                      color: Colors.black54,
                    ),
                  )
                : Container(),
          ),
        ),
        bottomNavigationBar: SalomonBottomBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          items: [
            /// Home
            SalomonBottomBarItem(
              icon: Icon(Icons.home),
              title: Text("Home"),
              selectedColor: Colors.orange,
            ),

            /// Likes
            SalomonBottomBarItem(
              icon: Icon(Icons.play_arrow),
              title: Text("Workout"),
              selectedColor: Colors.orange,
            ),

            /// Search
            SalomonBottomBarItem(
              icon: Icon(Icons.leaderboard),
              title: Text("Leaderboard"),
              selectedColor: Colors.orange,
            ),

            /// Profile
            SalomonBottomBarItem(
              icon: Icon(Icons.person),
              title: Text("Profile"),
              selectedColor: Colors.orange,
            ),
          ],
        ),
        body: _selectedPage(),
      ),
    );
  }
}
