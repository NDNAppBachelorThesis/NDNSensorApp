import 'package:flutter/material.dart';
import 'package:ndn_sensor_app/widgets/drawer.dart';
import 'package:zoom_widget/zoom_widget.dart';

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
  @override
  Widget build(BuildContext context) {

    return Placeholder();
  }
}

