import 'package:flutter/material.dart';
import 'package:ndn_sensor_app/pages/home/home.dart';
import 'package:ndn_sensor_app/pages/sensor_settings/sensor_settings.dart';
import 'package:ndn_sensor_app/provided/drawer_state_info.dart';
import 'package:ndn_sensor_app/utils.dart';
import 'package:provider/provider.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    var colorScheme = Theme.of(context).colorScheme;

    return Drawer(
      backgroundColor: colorScheme.surface,
      child: Column(
        children: [
          DrawerHeader(
            padding: EdgeInsets.zero,
            margin: EdgeInsets.only(bottom: 15),
            child: Column(
              children: [
                Image.asset(
                  "assets/images/uni-luebeck-logo.png",
                  width: 100,
                ),
                Text("NDN Sensor App",
                    style: TextStyle(
                      fontSize: 22,
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w900,
                    )),
              ],
            ),
          ),
          _DrawerItem(
            text: "Home",
            activeIcon: Icons.home,
            inactiveIcon: Icons.home_outlined,
            index: 0,
            onTap: () => pushReplacement(Navigator.of(context), (context) => HomePage()),
          ),
          _DrawerItem(
            text: "Sensor Settings",
            activeIcon: Icons.settings_rounded,
            inactiveIcon: Icons.settings_outlined,
            index: 1,
            onTap: () => pushReplacement(Navigator.of(context), (context) => SensorSettingsPage()),
          ),
          Spacer(),
          _DrawerItem(
            text: "Info",
            activeIcon: Icons.info,
            inactiveIcon: Icons.info_outline,
            index: 99,
          ),
          SizedBox(height: 15),
        ],
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final String text;
  final IconData activeIcon;
  final IconData inactiveIcon;
  final int index;
  final void Function()? onTap;

  const _DrawerItem({
    required this.text,
    required this.activeIcon,
    required this.inactiveIcon,
    required this.index,
    this.onTap,
    super.key,
  });

  bool isActive(DrawerStateInfo drawerStateInfo) {
    return drawerStateInfo.getSelectedIndex == index;
  }

  @override
  Widget build(BuildContext context) {
    var colorScheme = Theme.of(context).colorScheme;
    var drawerStateInfo = Provider.of<DrawerStateInfo>(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        selectedColor: colorScheme.primary,
        selectedTileColor: colorScheme.secondaryContainer,
        contentPadding: EdgeInsets.symmetric(horizontal: 16),
        selected: isActive(drawerStateInfo),
        title: Text(text,
            style: TextStyle(fontSize: 18, fontWeight: isActive(drawerStateInfo) ? FontWeight.w700 : FontWeight.w500)),
        leading: Icon(isActive(drawerStateInfo) ? activeIcon : inactiveIcon),
        onTap: () {
          onTap?.call();
          drawerStateInfo.setDrawerIndex(index);
        },
      ),
    );
  }
}
