import 'package:flutter/material.dart';
import 'package:ndn_sensor_app/extensions.dart';
import 'package:ndn_sensor_app/provided/app_settings.dart';
import 'package:provider/provider.dart';

///
/// The specific settings page for the NFD connection.
/// Configure if you want a direct connection or use the nfd-android app
class SettingsConnectionPage extends StatefulWidget {
  const SettingsConnectionPage({super.key});

  @override
  State<SettingsConnectionPage> createState() => _SettingsConnectionPageState();
}

class _SettingsConnectionPageState extends State<SettingsConnectionPage> {
  late bool useNfd = true;
  late var remoteNfdIpController = TextEditingController();
  late var remoteNfdPortController = TextEditingController();

  void _saveSettings() {
    var appSettings = context.read<AppSettings>();
    appSettings.useNfd = useNfd;
    appSettings.remoteNfdIp = remoteNfdIpController.text;
    appSettings.remoteNfdPort = int.tryParse(remoteNfdPortController.text) ?? 0;
    appSettings.save();

    var sb = SnackBar(
      elevation: 5,
      behavior: SnackBarBehavior.floating,
      content: Row(
        children: [
          Icons.update.toIcon(size: 30, color: Colors.white),
          SizedBox(width: 20),
          Flexible(child: Text("Update successfull.\n(Re-)connected to NDN!")),
        ],
      ),
    );

    if (context.mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context)..clearSnackBars()..showSnackBar(sb);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    var appSettings = context.read<AppSettings>();
    useNfd = appSettings.useNfd;
    remoteNfdIpController.text = appSettings.remoteNfdIp;
    remoteNfdPortController.text = appSettings.remoteNfdPort <= 0 ? "" : appSettings.remoteNfdPort.toString();
  }

  @override
  Widget build(BuildContext context) {
    var colorScheme = Theme.of(context).colorScheme;
    var borderRadius = Radius.circular(8);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: colorScheme.inversePrimary,
        title: Text("NDN Connection"),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        child: ListView(
          children: [
            Row(
              children: [
                Icons.info_outline.toIcon(size: 30),
                SizedBox(width: 10),
                Flexible(
                  child: Text(
                      "You can either choose to use the NFD-android app to route all your phones NDN traffic or "
                      "directly connect to a remote NFD instance.\nThe first solution is more NDN-like but requires an "
                      "additional app to always be running while the second solution has to downside that it requires a "
                      "direct connection to the remote NFD."),
                ),
              ],
            ),
            SizedBox(height: 15),
            Divider(),
            SizedBox(height: 20),
            Text("Select connection type", style: TextStyle(fontSize: 20)),
            ListTile(
              leading: Radio<bool>(
                value: true,
                groupValue: useNfd,
                onChanged: (value) => setState(() => useNfd = true),
              ),
              title: Text("Use NFD-android"),
            ),
            ListTile(
              leading: Radio<bool>(
                value: false,
                groupValue: useNfd,
                onChanged: (value) => setState(() => useNfd = false),
              ),
              title: Text("Connect directly"),
            ),
            SizedBox(height: 30),
            Row(
              children: [
                Flexible(
                  flex: 5,
                  child: TextField(
                    controller: remoteNfdIpController,
                    enabled: !useNfd,
                    decoration: InputDecoration(
                      labelText: "Remote NFD IP",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.only(
                          topLeft: borderRadius,
                          bottomLeft: borderRadius,
                        ),
                      ),
                    ),
                    textInputAction: TextInputAction.next,
                  ),
                ),
                Flexible(
                  flex: 2,
                  child: TextField(
                    controller: remoteNfdPortController,
                    enabled: !useNfd,
                    decoration: InputDecoration(
                        labelText: "Port",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.only(
                            topRight: borderRadius,
                            bottomRight: borderRadius,
                          ),
                        )),
                    keyboardType: TextInputType.number,
                  ),
                )
              ],
            ),
            SizedBox(height: 30),
            Center(
                child: ElevatedButton(
                    onPressed: _saveSettings,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: Text("Save", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ))),
            SizedBox(height: 50),
          ],
        ),
      ),
    );
  }
}
