import 'package:flutter/material.dart';
import 'package:ndn_sensor_app/constants.dart';
import 'package:ndn_sensor_app/extensions.dart';
import 'package:ndn_sensor_app/pages/info/info_list_item.dart';
import 'package:ndn_sensor_app/pages/settings/settings_connection_page.dart';
import 'package:ndn_sensor_app/utils.dart';
import 'package:ndn_sensor_app/widgets/drawer.dart';
import 'package:ndn_sensor_app/widgets/labeled_text.dart';
import 'package:url_launcher/url_launcher.dart';

///
/// The basic settings page. Link specific settings pages here
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {

  @override
  Widget build(BuildContext context) {
    var colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: colorScheme.inversePrimary,
        title: Text("Settings"),
      ),
      drawer: AppDrawer(),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InfoListItem(
              text: "NDF Connection",
              icon: Icons.wifi_find_rounded,
              onClick: () => push(Navigator.of(context), (context) => SettingsConnectionPage()),
            ),
          ],
        ),
      ),
    );
  }
}
