import 'package:flutter/material.dart';
import 'package:ndn_sensor_app/extensions.dart';
import 'package:ndn_sensor_app/pages/sensor_settings/sensor_add_field.dart';
import 'package:ndn_sensor_app/provided/ndn_api_wrapper.dart';
import 'package:provider/provider.dart';

import '../../provided/configured_sensors.dart';

class SensorDiscoveryPage extends StatefulWidget {
  const SensorDiscoveryPage({super.key});

  @override
  State<SensorDiscoveryPage> createState() => _SensorDiscoveryPageState();
}

class _SensorDiscoveryPageState extends State<SensorDiscoveryPage> {
  List<String> foundSensors = [];
  bool searchRunning = false;
  bool disposed = false;

  void _runDiscovery() {
    if (searchRunning) {
      return;
    }

    try {
      var ndnApi = context.read<NDNApiWrapper>();
      setState(() {
        foundSensors.clear();
        searchRunning = true;
      });
      ndnApi.runNameDiscovery((paths, deviceId, isNfd, finished) {
        if (!disposed) {
          setState(() {
            foundSensors.addAll(paths);
            searchRunning = !finished;
          });
        }
      });

    } catch (e) {   // Ensure searchRunning get reset even on a critical exception
      setState(() => searchRunning = false);
      rethrow;
    }
  }


  @override
  void dispose() {
    disposed = true;
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _runDiscovery();
  }

  @override
  Widget build(BuildContext context) {
    var colorScheme = Theme.of(context).colorScheme;
    var configuredSensors = Provider.of<ConfiguredSensors>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: colorScheme.inversePrimary,
        title: Text("Sensor Discovery"),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        child: RefreshIndicator(
          onRefresh: () async => _runDiscovery(),
          child: ListView(
            children: [
              ListView.separated(
                primary: false,
                shrinkWrap: true,
                separatorBuilder: (context, index) => Divider(),
                itemCount: foundSensors.length,
                itemBuilder: (context, index) {
                  var path = foundSensors[index];

                  return _FoundSensorWidget(path: path, exists: configuredSensors.pathExists(path), key: UniqueKey());
                },
              ),
              SizedBox(height: 30),
              if (searchRunning) Center(child: CircularProgressIndicator()),
              if (searchRunning)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Center(
                    child: Text(
                      "Searching...",
                      style: TextStyle(fontSize: 14, color: colorScheme.onSurfaceVariant.withOpacity(0.6)),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FoundSensorWidget extends StatefulWidget {
  final String path;
  final bool exists;

  const _FoundSensorWidget({
    required this.path,
    required this.exists,
    super.key,
  });

  @override
  State<_FoundSensorWidget> createState() => _FoundSensorWidgetState();
}

class _FoundSensorWidgetState extends State<_FoundSensorWidget> {
  late bool exists;

  void _addNewSensor(BuildContext context) async {
    var configuredSensors = Provider.of<ConfiguredSensors>(context, listen: false);
    showSensorAddBottomSheet(context, (config) {
      configuredSensors.addEndpoint(config);
      // setState(() => exists = true);
    }, widget.path);
  }

  @override
  void initState() {
    super.initState();
    exists = widget.exists;
  }

  @override
  Widget build(BuildContext context) {
    var colorScheme = Theme.of(context).colorScheme;

    return ListTile(
      enabled: !exists,
      contentPadding: EdgeInsets.zero,
      leading: Container(
        decoration: BoxDecoration(
          color: colorScheme.tertiaryContainer,
          borderRadius: BorderRadius.circular(100),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Icon(Icons.near_me, size: 28),
        ),
      ),
      title: Text(
        "Sensor Path",
        style: TextStyle(fontSize: 14, color: colorScheme.onSurfaceVariant.withOpacity(0.7)),
      ),
      subtitle: Text(
        widget.path,
        style: TextStyle(),
      ),
      trailing: ElevatedButton(
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.all(10),
          minimumSize: Size(0, 0),
        ),
        onPressed: exists ? null : () => _addNewSensor(context),
        child: Icons.add.toIcon(size: 30),
      ),
    );
  }
}
