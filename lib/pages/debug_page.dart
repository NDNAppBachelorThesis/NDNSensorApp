import 'package:flutter/material.dart';
import 'package:ndn_sensor_app/provided/ndn_api_wrapper.dart';
import 'package:ndn_sensor_app/widgets/drawer.dart';
import 'package:provider/provider.dart';

class DebugPage extends StatefulWidget {
  const DebugPage({super.key});

  @override
  State<DebugPage> createState() => _DebugPageState();
}

class _DebugPageState extends State<DebugPage> {
  @override
  Widget build(BuildContext context) {
    var colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: colorScheme.inversePrimary,
        title: Text("Debug"),
      ),
      drawer: AppDrawer(),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        child: _DebugWidget(),
      ),
    );
  }
}

class _DebugWidget extends StatefulWidget {
  const _DebugWidget({super.key});

  @override
  State<_DebugWidget> createState() => _DebugWidgetState();
}

class _DebugWidgetState extends State<_DebugWidget> {
  late final Future<Map<int, double>> future;

  @override
  void initState() {
    super.initState();
    future = context.read<NDNApiWrapper>().getSensorLinkQualities("198328652539720");
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return Text("Loading...");
        }

        if (snapshot.hasError) {
          return Text("Error: ${snapshot.error}");
        }

        return Text("Data: ${snapshot.data}");
      },
    );
  }
}
