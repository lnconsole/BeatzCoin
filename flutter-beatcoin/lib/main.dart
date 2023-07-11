import 'package:beatcoin/env.dart';
import 'package:beatcoin/pages/debug.dart';
import 'package:beatcoin/pages/devices.dart';
import 'package:beatcoin/pages/home.dart';
import 'package:beatcoin/pages/profile.dart';
import 'package:beatcoin/pages/workout.dart';
import 'package:beatcoin/services/debug.dart';
import 'package:beatcoin/services/nostr.dart';
import 'package:beatcoin/services/polar.dart';
import 'package:beatcoin/services/rewards.dart';
import 'package:beatcoin/services/workout.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:salomon_bottom_bar/salomon_bottom_bar.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/services.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  const storage = FlutterSecureStorage();
  final debugService = DebugService();
  final nostrService = NostrService(
    storage,
    Env.relayUrl,
    debugService,
  );
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
  Get.put(debugService);

  runApp(
    MyApp(
      nostrService: nostrService,
    ),
  );
}

/// Example app
class MyApp extends StatefulWidget {
  const MyApp({super.key, required this.nostrService});

  final NostrService nostrService;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    widget.nostrService.init();
    super.initState();
  }

  var _currentIndex = 0;
  final _disconnectedIconAssetName =
      'assets/icons/plug-disconnected-24-regular.svg';
  final _connectedIconAssetName = 'assets/icons/heart-rate.svg';

  Widget _selectedPage() {
    switch (_currentIndex) {
      case 1:
        return const WorkoutPage();
      case 2:
        return const ProfilePage();
      case 3:
        return const DevicesPage();
      case 4:
        return const DebugPage();
      default:
        return const HomePage();
    }
  }

  Widget _fab(
    int currentIndex,
    WorkoutService workoutService,
    PolarService polarService,
  ) {
    if (currentIndex == 1 && workoutService.readyToWorkout) {
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
    final polarService = Get.find<PolarService>();
    final workoutService = Get.find<WorkoutService>();
    final nostrService = Get.find<NostrService>();

    Widget connectHRSensorButton(bool deviceConnected) {
      return GestureDetector(
        onTap: () {
          setState(() {
            _currentIndex = 3;
          });
        },
        onLongPress: () {
          setState(() {
            _currentIndex = 4;
          });
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.all(Radius.circular(8)),
            color: deviceConnected ? Colors.green[100]! : Colors.red[100]!,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 4,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SvgPicture.asset(
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
                Padding(
                  padding: const EdgeInsets.only(left: 6.0),
                  child: Text(
                    'connect',
                    style: TextStyle(
                      fontSize: 12.0,
                      color:
                          deviceConnected ? Colors.green[400] : Colors.red[400],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    Widget relayButton(NostrService nostrService) {
      return GestureDetector(
        onTap: () {
          setState(() {
            _currentIndex = 3;
          });
        },
        onLongPress: () {
          setState(() {
            _currentIndex = 4;
          });
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.all(Radius.circular(8)),
            color: nostrService.connected.value
                ? const Color.fromARGB(255, 189, 131, 255)
                : Colors.red[50]!,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 4,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SvgPicture.asset(
                  'assets/icons/network-3.svg',
                  width: 24,
                  height: 24,
                  colorFilter: ColorFilter.mode(
                    nostrService.connected.value
                        ? const Color.fromARGB(255, 136, 58, 225)
                        : Colors.red[400]!,
                    BlendMode.srcIn,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 6.0),
                  child: Text(
                    'nostr',
                    style: TextStyle(
                      fontSize: 12.0,
                      color: nostrService.connected.value
                          ? const Color.fromARGB(255, 136, 58, 225)
                          : Colors.red[400],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return MaterialApp(
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
            () => connectHRSensorButton(
              polarService.isDeviceConnected.value,
            ),
          ),
          actions: [
            Obx(
              () => Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: relayButton(nostrService),
              ),
            ),
          ],
        ),
        bottomNavigationBar: SalomonBottomBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          items: [
            /// Home
            SalomonBottomBarItem(
              icon: const Icon(Icons.home),
              title: const Text(
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
              icon: const Icon(Icons.play_arrow),
              title: const Text(
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
              icon: const Icon(Icons.person),
              title: const Text(
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
