import 'package:beatcoin/pages/devices.dart';
import 'package:beatcoin/pages/home.dart';
import 'package:beatcoin/pages/leaderboard.dart';
import 'package:beatcoin/pages/profile.dart';
import 'package:beatcoin/pages/workout.dart';
import 'package:beatcoin/polar/polar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:salomon_bottom_bar/salomon_bottom_bar.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

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
  final _disconnectedIconAssetName =
      'assets/icons/plug-disconnected-24-regular.svg';
  final _connectedIconAssetName = 'assets/icons/heart-rate.svg';

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

    Widget iconButton(bool deviceConnected) {
      return FilledButton.icon(
        onPressed: () {
          setState(() {
            _currentIndex = 4;
          });
        },
        style: ButtonStyle(
          backgroundColor: MaterialStateProperty.resolveWith(
            (states) {
              if (deviceConnected) {
                return Colors.green[50];
              }
              return Colors.red[50];
            },
          ),
        ),
        icon: SvgPicture.asset(
          deviceConnected
              ? _connectedIconAssetName
              : _disconnectedIconAssetName,
          width: 24,
          height: 24,
          colorFilter: ColorFilter.mode(
            deviceConnected ? Colors.green[400]! : Colors.red[400]!,
            BlendMode.srcIn,
          ),
        ),
        label: deviceConnected
            ? Container(
                height: 0,
                width: 0,
              )
            : Text(
                'connect',
                style: TextStyle(
                  fontSize: 12,
                  color: deviceConnected ? Colors.green[400] : Colors.red[400],
                ),
              ),
      );
    }

    return MaterialApp(
      theme: ThemeData(
        fontFamily: 'Sora',
      ),
      home: Scaffold(
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.white,
          title: Obx(
            () => iconButton(
              polarController.isDeviceConnected.value,
            ),
          ),
        ),
        bottomNavigationBar: SalomonBottomBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          items: [
            /// Home
            SalomonBottomBarItem(
              icon: Icon(Icons.home),
              title: Text(
                "Home",
                style: TextStyle(
                  fontSize: 12,
                  fontFamily: 'Sora',
                ),
              ),
              selectedColor: Colors.orange,
            ),

            /// Likes
            SalomonBottomBarItem(
              icon: Icon(Icons.play_arrow),
              title: Text(
                "Workout",
                style: TextStyle(
                  fontSize: 12,
                  fontFamily: 'Sora',
                ),
              ),
              selectedColor: Colors.orange,
            ),

            /// Search
            SalomonBottomBarItem(
              icon: Icon(Icons.leaderboard),
              title: Text(
                "Leaderboard",
                style: TextStyle(
                  fontSize: 12,
                  fontFamily: 'Sora',
                ),
              ),
              selectedColor: Colors.orange,
            ),

            /// Profile
            SalomonBottomBarItem(
              icon: Icon(Icons.person),
              title: Text(
                "Profile",
                style: TextStyle(
                  fontSize: 12,
                  fontFamily: 'Sora',
                ),
              ),
              selectedColor: Colors.orange,
            ),
          ],
        ),
        body: _selectedPage(),
      ),
    );
  }
}
