import 'package:flutter/material.dart';
import 'package:ndn_sensor_app/widgets/drawer.dart';
import 'package:ndn_sensor_app/provided/configured_sensors.dart';
import 'package:ndn_sensor_app/provided/sensor_data_handler.dart';
import 'package:ndn_sensor_app/pages/home/sensor_card.dart';
import 'package:provider/provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    var colorScheme = Theme.of(context).colorScheme;
    var configuredSensors = Provider.of<ConfiguredSensors>(context);
    Provider.of<SensorDataHandler>(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: colorScheme.inversePrimary,
        title: Text("NDN Sensor App (PoC)"),
      ),
      drawer: AppDrawer(),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: ListView(
          children: [
            for (var sensor in configuredSensors.activeEndpoints)
              SensorCard(sensor: sensor),
          ],
        ),
      ),
    );
  }
}
