import 'package:flutter/material.dart';
import 'package:ndn_sensor_app/constants.dart';
import 'package:ndn_sensor_app/extensions.dart';
import 'package:ndn_sensor_app/pages/info/info_list_item.dart';
import 'package:ndn_sensor_app/widgets/drawer.dart';
import 'package:ndn_sensor_app/widgets/labeled_text.dart';
import 'package:url_launcher/url_launcher.dart';

class InfoPage extends StatefulWidget {
  const InfoPage({super.key});

  @override
  State<InfoPage> createState() => _InfoPageState();
}

class _InfoPageState extends State<InfoPage> {

  void _showUrlOpenError() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icons.browser_not_supported_rounded.toIcon(size: 30),
        title: Text("Failed to open URL"),
        content: IntrinsicHeight(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Manually go to"),
              SelectableText(Constants.sourceUrl, style: TextStyle(color: Colors.blue.shade800)),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(onPressed: () => Navigator.of(context).pop(), child: Text("Okay")),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    var colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: colorScheme.inversePrimary,
        title: Text("About this App"),
      ),
      drawer: AppDrawer(),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InfoListItem(
              text: "Arne Matthes",
              labelText: "Author",
              icon: Icons.account_circle_outlined,
              labelTop: true,
            ),
            Divider(),
            InfoListItem(
              text: "0.0.1-dev",
              labelText: "Version",
              icon: Icons.update_outlined,
              labelTop: true,
            ),
            Divider(),
            InfoListItem(
              text: "www.github.com",
              labelText: "Sourcecode",
              icon: Icons.code_outlined,
              labelTop: true,
              onClick: () async {
                var uri = Uri.parse(Constants.sourceUrl);
                if (!await launchUrl(uri) && context.mounted) {
                  _showUrlOpenError();
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
