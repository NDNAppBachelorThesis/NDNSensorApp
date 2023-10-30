import 'dart:isolate';

import 'package:flutter/material.dart';
import 'package:ndn_sensor_app/pages/home/home.dart';
import 'package:ndn_sensor_app/provided/configured_sensors.dart';
import 'package:ndn_sensor_app/provided/global_app_state.dart';
import 'package:ndn_sensor_app/provided/ndn_api_wrapper.dart';
import 'package:ndn_sensor_app/provided/drawer_state_info.dart';
import 'package:ndn_sensor_app/provided/sensor_data_handler.dart';
import 'package:ndn_sensor_app/utils.dart';
import 'package:provider/provider.dart';

class StartupData {
  final NDNApiWrapper ndnApiWrapper;
  final ConfiguredSensors configuredSensors;
  final SensorDataHandler sensorDataHandler;
  final GlobalAppState globalAppState;

  StartupData(this.ndnApiWrapper, this.configuredSensors, this.sensorDataHandler, this.globalAppState);
}

Future<StartupData> _initializeApp() async {
  var appState = GlobalAppState();
  var apiWrapper = NDNApiWrapper(globalAppState: appState);
  var configuredSensors = ConfiguredSensors();
  await configuredSensors.initialize();
  var sensorDataHandler = SensorDataHandler(
    configuredSensors: configuredSensors,
    ndnApiWrapper: apiWrapper,
  );
  await sensorDataHandler.startAndInitialize();

  return StartupData(apiWrapper, configuredSensors, sensorDataHandler, appState);
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final Future<StartupData> _startupFuture;

  @override
  void initState() {
    super.initState();
    _startupFuture = _initializeApp();
  }

  @override
  Widget build(BuildContext context) {
    var colorScheme = ColorScheme.fromSeed(seedColor: Colors.deepPurple);

    return FutureBuilder<StartupData>(
        future: _startupFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return _LoadingApp(colorScheme: colorScheme);
          }

          var data = snapshot.data!;

          return MultiProvider(
            providers: [
              ChangeNotifierProvider(
                create: (context) => DrawerStateInfo(),
              ),
              Provider(
                create: (context) => data.ndnApiWrapper,
              ),
              ChangeNotifierProvider(
                create: (context) => data.configuredSensors,
              ),
              Provider(
                create: (context) => data.sensorDataHandler,
              ),
              ChangeNotifierProvider(
                create: (context) => data.globalAppState,
              ),
            ],
            child: _MainApp(colorScheme: colorScheme),
          );
        });
  }
}

class _LoadingApp extends StatelessWidget {
  final ColorScheme colorScheme;

  const _LoadingApp({required this.colorScheme, super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Loading...',
      theme: ThemeData(
        colorScheme: colorScheme,
        useMaterial3: true,
      ),
      home: Scaffold(
        appBar: AppBar(title: Text("Loading...")),
      ),
    );
  }
}

class _MainApp extends StatelessWidget {
  final ColorScheme colorScheme;

  const _MainApp({required this.colorScheme, super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NDN Sensor App',
      theme: ThemeData(
        colorScheme: colorScheme,
        useMaterial3: true,
        iconTheme: IconThemeData(
          color: colorScheme.onSurfaceVariant,
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        buttonTheme: ButtonThemeData(
          colorScheme: colorScheme,
        ),
      ),
      home: NDFConnectionErrorPageWrapper(child: HomePage()),
    );
  }
}

void main() {
  runApp(const MyApp());
}
