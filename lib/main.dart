import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';
import 'package:ndn_sensor_app/extensions.dart';
import 'package:ndn_sensor_app/pages/home/home.dart';
import 'package:ndn_sensor_app/provided/app_settings.dart';
import 'package:ndn_sensor_app/provided/configured_sensors.dart';
import 'package:ndn_sensor_app/provided/global_app_state.dart';
import 'package:ndn_sensor_app/provided/ndn_api_wrapper.dart';
import 'package:ndn_sensor_app/provided/drawer_state_info.dart';
import 'package:ndn_sensor_app/provided/sensor_data_handler.dart';
import 'package:ndn_sensor_app/utils.dart';
import 'package:provider/provider.dart';

class StartupData {
  final AppSettings appSettings;
  final NDNApiWrapper ndnApiWrapper;
  final ConfiguredSensors configuredSensors;
  final SensorDataHandler sensorDataHandler;
  final GlobalAppState globalAppState;

  StartupData(this.appSettings, this.ndnApiWrapper, this.configuredSensors, this.sensorDataHandler, this.globalAppState);
}

Future<StartupData> _initializeApp() async {
  await FlutterDisplayMode.setHighRefreshRate();  // Enable refresh rate of > 60 fps
  var appState = GlobalAppState();
  var apiWrapper = NDNApiWrapper(globalAppState: appState);
  var appSettings = AppSettings(apiWrapper);
  await appSettings.load();
  var configuredSensors = ConfiguredSensors();
  await configuredSensors.initialize();
  var sensorDataHandler = SensorDataHandler(
    configuredSensors: configuredSensors,
    ndnApiWrapper: apiWrapper,
  );
  await sensorDataHandler.startAndInitialize();

  return StartupData(appSettings, apiWrapper, configuredSensors, sensorDataHandler, appState);
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

          if (snapshot.hasError) {
            return _ErrorApp(colorScheme: colorScheme, error: snapshot.error);
          }

          var data = snapshot.data!;

          return MultiProvider(
            providers: [
              ChangeNotifierProvider(
                create: (context) => data.appSettings,
              ),
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
        appBar: AppBar(
          backgroundColor: colorScheme.inversePrimary,
          title: Text("Loading..."),
        ),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
    );
  }
}

class _ErrorApp extends StatelessWidget {
  final ColorScheme colorScheme;
  final Object? error;

  const _ErrorApp({required this.colorScheme, required this.error, super.key});

  String _extractStacktrace() {
    if (error is Error) {
      return (error as Error).stackTrace.toString();
    }

    return "Can't extract stacktrace";
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Error',
      theme: ThemeData(
        colorScheme: colorScheme,
        useMaterial3: true,
      ),
      home: Scaffold(
        appBar: AppBar(
          backgroundColor: colorScheme.inversePrimary,
          title: Text("Startup Error"),
          leading: Icons.error_outline.toIcon(size: 30),
        ),
        body: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Exception", style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant.withOpacity(0.6))),
              Text(error.toString(), style: TextStyle(fontSize: 16, color: Colors.red)),
              SizedBox(height: 8),
              Divider(),
              SizedBox(height: 8),
              Text("StackTrace", style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant.withOpacity(0.6))),
              Text(_extractStacktrace()),
            ],
          ),
        ),
      ),
    );
  }
}

class _MainApp extends StatelessWidget {
  final ColorScheme colorScheme;

  const _MainApp({required this.colorScheme, super.key});

  TextStyle _buildTextStyle(
      double fontSize,
      double lineHeight,
      ColorScheme colorScheme, {
        Color? color,
        double opacity = 1.0,
        FontWeight? weight,
      }) {
    var baseColor = color ?? colorScheme.onSurfaceVariant;
    var fontColor = Color.alphaBlend(baseColor.withOpacity(opacity), colorScheme.surface);

    return TextStyle(fontSize: fontSize, color: fontColor, fontWeight: weight);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NDN Sensor App',
      theme: ThemeData(
        colorScheme: colorScheme,
        useMaterial3: true,
        fontFamily: "Kanit",
        fontFamilyFallback: ["Roboto"],
        textTheme: TextTheme(
          displayLarge: _buildTextStyle(57, 0, colorScheme),
          displayMedium: _buildTextStyle(45, 0, colorScheme),
          displaySmall: _buildTextStyle(36, 0, colorScheme),
          headlineLarge: _buildTextStyle(32, 0, colorScheme),
          headlineMedium: _buildTextStyle(20, 0, colorScheme),
          headlineSmall: _buildTextStyle(24, 0, colorScheme),
          titleLarge: _buildTextStyle(20, 0, colorScheme),
          titleMedium: _buildTextStyle(18, 0, colorScheme),
          titleSmall: _buildTextStyle(16, 0, colorScheme),
          bodyLarge: _buildTextStyle(17, 0, colorScheme),
          bodyMedium: _buildTextStyle(16, 0, colorScheme),
          bodySmall: _buildTextStyle(15, 0, colorScheme),
          labelLarge: _buildTextStyle(17, 0, colorScheme),
          labelMedium: _buildTextStyle(16, 0, colorScheme, opacity: 0.6, weight: FontWeight.w600),
          labelSmall:
          _buildTextStyle(13, 0, colorScheme, opacity: 0.6, weight: FontWeight.normal), // Done
        ),
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
        dropdownMenuTheme: DropdownMenuThemeData(
            inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        )),
      ),
      home: NFDConnectionErrorPageWrapper(child: HomePage()),
    );
  }
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Prevent user from entering landscape mode
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  runApp(const MyApp());
}
