import 'package:beatcoin/env.dart';
import 'package:beatcoin/pages/devices.dart';
import 'package:beatcoin/pages/home.dart';
import 'package:beatcoin/pages/leaderboard.dart';
import 'package:beatcoin/pages/profile.dart';
import 'package:beatcoin/pages/workout.dart';
import 'package:beatcoin/services/nostr.dart';
import 'package:beatcoin/services/polar.dart';
import 'package:beatcoin/services/rewards.dart';
import 'package:beatcoin/services/workout.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:salomon_bottom_bar/salomon_bottom_bar.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  final prefs = await SharedPreferences.getInstance();
  final nostrService = NostrService(prefs, Env.relayUrl);
  await nostrService.init();
  final polarService = PolarService();
  final workoutService = WorkoutService(
    nostrService,
    polarService,
  );
  final rewardService = RewardsService();

  Get.put(nostrService);
  Get.put(polarService);
  Get.put(workoutService);
  Get.put(rewardService);

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
        return ProfilePage();
      case 3:
        return DevicesPage();
      default:
        return HomePage();
    }
  }

  Widget _fab(
    int currentIndex,
    WorkoutService workoutService,
    PolarService polarService,
  ) {
    if (currentIndex == 1 && polarService.isDeviceConnected.value) {
      return Obx(
        () => FloatingActionButton(
          onPressed: () {
            workoutService.running.value
                ? workoutService.stopWorkout()
                : workoutService.startWorkout();
          },
          child: Icon(
            workoutService.running.value ? Icons.stop : Icons.play_arrow,
          ),
        ),
      );
    }

    return Container();
  }

  @override
  Widget build(BuildContext context) {
    PolarService polarService = Get.find();
    WorkoutService workoutService = Get.find();

    Widget iconButton(bool deviceConnected) {
      return FilledButton.icon(
        onPressed: () {
          setState(() {
            _currentIndex = 3;
          });
          polarService.searchDevices();
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
          overlayColor: MaterialStateProperty.resolveWith(
            (states) {
              if (deviceConnected) {
                return Colors.green[100];
              }
              return Colors.red[100];
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
            ? Text(
                polarService.heartRate.value.toString(),
                style: TextStyle(
                  fontSize: 12,
                  color: deviceConnected ? Colors.green[400] : Colors.red[400],
                ),
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
      // Theme config for FlexColorScheme version 7.1.x. Make sure you use
// same or higher package version, but still same major version. If you
// use a lower package version, some properties may not be supported.
// In that case remove them after copying this theme to your app.
      theme: FlexThemeData.light(
        fontFamily: 'Sora',
        scheme: FlexScheme.orangeM3,
        surfaceMode: FlexSurfaceMode.highScaffoldLowSurface,
        blendLevel: 1,
        subThemesData: const FlexSubThemesData(
          useTextTheme: true,
          useM2StyleDividerInM3: true,
          defaultRadius: 12.0,
          elevatedButtonSchemeColor: SchemeColor.onPrimaryContainer,
          elevatedButtonSecondarySchemeColor: SchemeColor.primaryContainer,
          outlinedButtonOutlineSchemeColor: SchemeColor.primary,
          toggleButtonsBorderSchemeColor: SchemeColor.primary,
          segmentedButtonSchemeColor: SchemeColor.primary,
          segmentedButtonBorderSchemeColor: SchemeColor.primary,
          unselectedToggleIsColored: true,
          sliderValueTinted: true,
          inputDecoratorSchemeColor: SchemeColor.primary,
          inputDecoratorBackgroundAlpha: 31,
          inputDecoratorUnfocusedHasBorder: false,
          inputDecoratorFocusedBorderWidth: 1.0,
          inputDecoratorPrefixIconSchemeColor: SchemeColor.primary,
          fabUseShape: true,
          fabAlwaysCircular: true,
          fabSchemeColor: SchemeColor.primary,
          popupMenuRadius: 8.0,
          popupMenuElevation: 3.0,
          drawerIndicatorRadius: 12.0,
          drawerIndicatorSchemeColor: SchemeColor.primary,
          bottomNavigationBarMutedUnselectedLabel: false,
          bottomNavigationBarMutedUnselectedIcon: false,
          menuRadius: 8.0,
          menuElevation: 3.0,
          menuBarRadius: 0.0,
          menuBarElevation: 2.0,
          menuBarShadowColor: Color(0x00000000),
          navigationBarSelectedLabelSchemeColor: SchemeColor.primary,
          navigationBarMutedUnselectedLabel: false,
          navigationBarSelectedIconSchemeColor: SchemeColor.onPrimary,
          navigationBarMutedUnselectedIcon: false,
          navigationBarIndicatorSchemeColor: SchemeColor.primary,
          navigationBarIndicatorOpacity: 1.00,
          navigationBarIndicatorRadius: 12.0,
          navigationRailSelectedLabelSchemeColor: SchemeColor.primary,
          navigationRailMutedUnselectedLabel: false,
          navigationRailSelectedIconSchemeColor: SchemeColor.onPrimary,
          navigationRailMutedUnselectedIcon: false,
          navigationRailIndicatorSchemeColor: SchemeColor.primary,
          navigationRailIndicatorOpacity: 1.00,
          navigationRailIndicatorRadius: 12.0,
          navigationRailBackgroundSchemeColor: SchemeColor.surface,
        ),
        keyColors: const FlexKeyColors(
          useSecondary: true,
          useTertiary: true,
          keepPrimary: true,
        ),
        tones: FlexTones.jolly(Brightness.light),
        visualDensity: FlexColorScheme.comfortablePlatformDensity,
        useMaterial3: true,
      ),
      darkTheme: FlexThemeData.dark(
        fontFamily: 'Sora',
        scheme: FlexScheme.orangeM3,
        surfaceMode: FlexSurfaceMode.highScaffoldLowSurface,
        blendLevel: 2,
        subThemesData: const FlexSubThemesData(
          blendTextTheme: true,
          useTextTheme: true,
          useM2StyleDividerInM3: true,
          defaultRadius: 12.0,
          elevatedButtonSchemeColor: SchemeColor.onPrimaryContainer,
          elevatedButtonSecondarySchemeColor: SchemeColor.primaryContainer,
          outlinedButtonOutlineSchemeColor: SchemeColor.primary,
          toggleButtonsBorderSchemeColor: SchemeColor.primary,
          segmentedButtonSchemeColor: SchemeColor.primary,
          segmentedButtonBorderSchemeColor: SchemeColor.primary,
          unselectedToggleIsColored: true,
          sliderValueTinted: true,
          inputDecoratorSchemeColor: SchemeColor.primary,
          inputDecoratorBackgroundAlpha: 43,
          inputDecoratorUnfocusedHasBorder: false,
          inputDecoratorFocusedBorderWidth: 1.0,
          inputDecoratorPrefixIconSchemeColor: SchemeColor.primary,
          fabUseShape: true,
          fabAlwaysCircular: true,
          fabSchemeColor: SchemeColor.primary,
          popupMenuRadius: 8.0,
          popupMenuElevation: 3.0,
          drawerIndicatorRadius: 12.0,
          drawerIndicatorSchemeColor: SchemeColor.primary,
          bottomNavigationBarMutedUnselectedLabel: false,
          bottomNavigationBarMutedUnselectedIcon: false,
          menuRadius: 8.0,
          menuElevation: 3.0,
          menuBarRadius: 0.0,
          menuBarElevation: 2.0,
          menuBarShadowColor: Color(0x00000000),
          navigationBarSelectedLabelSchemeColor: SchemeColor.primary,
          navigationBarMutedUnselectedLabel: false,
          navigationBarSelectedIconSchemeColor: SchemeColor.onPrimary,
          navigationBarMutedUnselectedIcon: false,
          navigationBarIndicatorSchemeColor: SchemeColor.primary,
          navigationBarIndicatorOpacity: 1.00,
          navigationBarIndicatorRadius: 12.0,
          navigationRailSelectedLabelSchemeColor: SchemeColor.primary,
          navigationRailMutedUnselectedLabel: false,
          navigationRailSelectedIconSchemeColor: SchemeColor.onPrimary,
          navigationRailMutedUnselectedIcon: false,
          navigationRailIndicatorSchemeColor: SchemeColor.primary,
          navigationRailIndicatorOpacity: 1.00,
          navigationRailIndicatorRadius: 12.0,
          navigationRailBackgroundSchemeColor: SchemeColor.surface,
        ),
        keyColors: const FlexKeyColors(
          useSecondary: true,
          useTertiary: true,
        ),
        tones: FlexTones.jolly(Brightness.dark),
        visualDensity: FlexColorScheme.comfortablePlatformDensity,
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system,
      home: Scaffold(
        appBar: AppBar(
          elevation: 0,
          title: Obx(
            () => iconButton(
              polarService.isDeviceConnected.value,
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
        floatingActionButton: _fab(
          _currentIndex,
          workoutService,
          polarService,
        ),
        body: _selectedPage(),
      ),
    );
  }

  @override
  void dispose() {
    NostrService nostr = Get.find();
    nostr.dispose();
    super.dispose();
  }
}
