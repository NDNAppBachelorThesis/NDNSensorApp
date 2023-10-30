import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ndn_sensor_app/widgets/drawer.dart';
import 'package:ndn_sensor_app/extensions.dart';
import 'package:ndn_sensor_app/provided/configured_sensors.dart';
import 'package:ndn_sensor_app/pages/sensor_settings/sensor_add_field.dart';
import 'package:ndn_sensor_app/provided/sensor_data_handler.dart';
import 'package:provider/provider.dart';

class SensorSettingsPage extends StatefulWidget {
  const SensorSettingsPage({super.key});

  @override
  State<SensorSettingsPage> createState() => _SensorSettingsPageState();
}

class _SensorSettingsPageState extends State<SensorSettingsPage> {
  @override
  Widget build(BuildContext context) {
    var colorScheme = Theme.of(context).colorScheme;
    var configuredSensors = Provider.of<ConfiguredSensors>(context);
    var data = configuredSensors.allEndpoints;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: colorScheme.inversePrimary,
        title: Text("Sensor Settings"),
      ),
      drawer: AppDrawer(),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        child: ListView(
          children: [
            ListView.separated(
              primary: false,
              shrinkWrap: true,
              itemCount: data.length,
              separatorBuilder: (context, index) => Divider(),
              itemBuilder: (context, index) {
                var item = data[index];

                return _SensorListItem(item: item);
              },
            ),
            SizedBox(height: 40),
            SensorAddButton(
              onSensorAdded: (config) => configuredSensors.addEndpoint(config),
            ),
          ],
        ),
      ),
    );
  }
}

class _SensorListItem extends StatefulWidget {
  final SensorConfig item;

  const _SensorListItem({required this.item, super.key});

  @override
  State<_SensorListItem> createState() => _SensorListItemState();
}

class _SensorListItemState extends State<_SensorListItem> {
  late bool enabled;

  @override
  void initState() {
    super.initState();
    enabled = widget.item.enabled;
  }

  Future<bool> _confirmRemoval(
    BuildContext context,
    ConfiguredSensors configuredSensors,
  ) async {
    var doRemove = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text("Confirm removal"),
            icon: Icon(Icons.delete_sweep_outlined, size: 32),
            content: Text("Do you really want to remove the sensor '${widget.item.path}' (${widget.item.title})?"),
            actions: [
              TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text("Cancel", style: TextStyle(fontSize: 16))),
              TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text("Delete", style: TextStyle(fontSize: 16))),
            ],
          ),
        ) ??
        false;

    return doRemove;
  }

  @override
  Widget build(BuildContext context) {
    var colorScheme = Theme.of(context).colorScheme;
    var configuredSensors = Provider.of<ConfiguredSensors>(context);
    var sensorDataHandler = context.read<SensorDataHandler>();

    return Dismissible(
      key: ValueKey(widget.item.path),
      onDismissed: (direction) {
        configuredSensors.removeEndpoint(widget.item.path);
      },
      confirmDismiss: (direction) {
        return _confirmRemoval(context, configuredSensors);
      },
      background: Container(
        color: Colors.red,
        child: Row(
          children: [
            Expanded(child: Container()),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Icon(Icons.delete_forever_rounded, size: 30),
            ),
          ],
        ),
      ),
      direction: DismissDirection.endToStart,
      dismissThresholds: {
        DismissDirection.endToStart: 0.25,
      },
      onUpdate: (details) {
        if (details.reached && !details.previousReached) {
          HapticFeedback.lightImpact();
        }
      },
      child: ChangeNotifierProvider.value(
        value: sensorDataHandler.getData(widget.item.path),
        child: Consumer<SensorData>(
          builder: (context, sensorData, _) => ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(widget.item.title, style: TextStyle(fontSize: 18)),
            subtitle: Text(widget.item.path, style: TextStyle(fontWeight: FontWeight.w500)),
            leading: Container(
              decoration: BoxDecoration(
                color: sensorData.lastResultError ? Colors.red.shade300 : colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(100),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Icon(Icons.sensors_outlined, size: 28),
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(sensorData.lastItem?.roundToNPadded(2) ?? "", style: TextStyle(fontSize: 14)),
                SizedBox(width: 4),
                Text(widget.item.unit.unitString, style: TextStyle(fontSize: 14)),
                SizedBox(width: 15),
                Switch(
                  value: enabled,
                  thumbIcon: MaterialStateProperty.resolveWith((states) {
                    if (states.contains(MaterialState.selected)) {
                      return Icon(Icons.check);
                    }
                    return Icon(Icons.close);
                  }),
                  onChanged: (value) {
                    setState(() {
                      enabled = value;
                    });
                    configuredSensors.toggleEndpoint(widget.item.path, value);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
