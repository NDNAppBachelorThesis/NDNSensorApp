import 'dart:math';

import 'package:flutter/material.dart';
import 'package:ndn_sensor_app/extensions.dart';
import 'package:ndn_sensor_app/provided/configured_sensors.dart';
import 'package:ndn_sensor_app/provided/global_app_state.dart';
import 'package:provider/provider.dart';

/// Adds a NDF connection error wrapper around pages
class NDFConnectionErrorPageWrapper extends StatelessWidget {
  Widget child;

  NDFConnectionErrorPageWrapper({required this.child, super.key});

  Future<void> _showNDFConnectionError(BuildContext context, GlobalAppState appState) async {
    var configuredSensors = Provider.of<ConfiguredSensors>(context, listen: false);
    // Use min to prevent the limit from becoming 0
    var unsuccessfulPacketsLimit = max(configuredSensors.activeEndpoints.length * 4, 1);
    if (appState.showedNDFConnectionError || appState.unsuccessfulPacketsCnt < unsuccessfulPacketsLimit) {
      return;
    }

    appState.showedNDFConnectionError = true;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Couldn't connect to NDF"),
        icon: Icons.signal_wifi_statusbar_connected_no_internet_4_rounded.toIcon(size: 30),
        content: IntrinsicHeight(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "It seems like the app can't connect to the NDF (Named Data Forwarder). Make sure the NDF app is "
                "running and connected to another NDF in the network.",
                style: TextStyle(fontSize: 15),
              ),
              SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text("Okay", style: TextStyle(fontSize: 16)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    var appState = Provider.of<GlobalAppState>(context);

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) => _showNDFConnectionError(context, appState));

    return child;
  }
}

Future<Object?> pushReplacement(
  NavigatorState navigator,
  Widget Function(BuildContext context) builder,
) async {
  return navigator.pushReplacement(MaterialPageRoute(
    builder: (context) => NDFConnectionErrorPageWrapper(child: builder(context)),
  ));
}

Future<Object?> push(
  NavigatorState navigator,
  Widget Function(BuildContext context) builder,
) async {
  return navigator.push(MaterialPageRoute(
    builder: (context) => NDFConnectionErrorPageWrapper(child: builder(context)),
  ));
}
