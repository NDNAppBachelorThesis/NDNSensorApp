import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ndn_sensor_app/extensions.dart';
import 'package:ndn_sensor_app/provided/configured_sensors.dart';
import 'package:ndn_sensor_app/widgets/generic_bottom_sheet.dart';
import 'package:ndn_sensor_app/provided/ndn_api_wrapper.dart';
import 'package:ndn_sensor_app/widgets/text_checkbox.dart';
import 'package:provider/provider.dart';

class SensorAddButton extends StatefulWidget {
  final void Function(SensorConfig config) onSensorAdded;

  const SensorAddButton({
    required this.onSensorAdded,
    super.key,
  });

  @override
  State<SensorAddButton> createState() => _SensorAddButtonState();
}

class _SensorAddButtonState extends State<SensorAddButton> {
  Future<void> _openBottomSheet() async {
    showMaterialModalBottomSheet(
      context: context,
      builder: (context) => _AddSensorBottomSheetContent(onSensorAdded: widget.onSensorAdded),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 60),
      child: FilledButton.icon(
        onPressed: _openBottomSheet,
        icon: Icon(Icons.add),
        label: Text("Add new Sensor"),
      ),
    );
  }
}

class _AddSensorBottomSheetContent extends StatefulWidget {
  final void Function(SensorConfig config) onSensorAdded;

  const _AddSensorBottomSheetContent({
    required this.onSensorAdded,
    super.key,
  });

  @override
  State<_AddSensorBottomSheetContent> createState() => _AddSensorBottomSheetContentState();
}

class _AddSensorBottomSheetContentState extends State<_AddSensorBottomSheetContent> {
  var pathController = TextEditingController();
  var titleController = TextEditingController();
  var unit = SensorUnit.none;
  var allowAddingWhenConnectionFailure = false;
  String? pathError;
  String? titleError;
  bool loading = false;

  Future<bool> _validateInput() async {
    setState(() => loading = true);

    var ndnApi = context.read<NDNApiWrapper>();
    var configuredSensors = context.read<ConfiguredSensors>();
    String? newPathError;
    String? newTitleError;

    var path = pathController.text.trim();
    if (path.isEmpty) {
      newPathError = "Path can't be empty";
    } else if (path.contains(" ")) {
      newPathError = "Path can't contain spaces";
    } else if (!path.startsWith("/")) {
      newPathError = "Path must start with a /";
    } else if (configuredSensors.pathExists(path)) {
      newPathError = "The sensor is already added";
    } else if (!allowAddingWhenConnectionFailure) {
      try {
        await ndnApi.getRawData(path);
      } on NDNException catch (e) {
        newPathError = "Can't connect to sensor";
      }
    }

    var title = titleController.text.trim();
    if (title.isEmpty) {
      newTitleError = "Title can't be empty";
    }

    setState(() {
      pathError = newPathError;
      titleError = newTitleError;
      loading = false;
    });

    if (newPathError == null && newTitleError == null) {
      widget.onSensorAdded(SensorConfig(path, title, unit, true));
      pathController.clear();
      titleController.clear();
      if (context.mounted) {
        Navigator.of(context).pop(true);
      }
      return true;
    }

    return false;
  }

  void _cancelInput() {
    pathController.clear();
    titleController.clear();
    Navigator.of(context).pop(false);
  }

  DropdownMenuEntry<SensorUnit> _createSensorUnitDropdownEntry(SensorUnit unit, String title) {
    return DropdownMenuEntry(
      value: unit,
      label: title,
      leadingIcon: unit.icon?.toIcon(),
    );
  }

  @override
  Widget build(BuildContext context) {
    var colorScheme = Theme.of(context).colorScheme;
    var textBtnStyle = TextStyle(fontSize: 17, fontWeight: FontWeight.w600);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Text(
            "Add new Sensor",
            style: TextStyle(fontSize: 20, color: colorScheme.primary, fontWeight: FontWeight.w500),
          ),
        ),
        SizedBox(height: 20),
        TextField(
          controller: pathController,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            labelText: "NDN Path",
            prefixIcon: Icon(Icons.sensors_outlined),
            errorText: pathError,
          ),
        ),
        SizedBox(height: 15),
        TextField(
          controller: titleController,
          decoration: InputDecoration(
            labelText: "Name",
            prefixIcon: Icon(Icons.text_snippet_outlined),
            errorText: titleError,
          ),
        ),
        SizedBox(height: 15),
        DropdownMenu<SensorUnit>(
          initialSelection: SensorUnit.none,
          label: Text("Unit"),
          leadingIcon: unit.icon?.toIcon(),
          dropdownMenuEntries: [
            _createSensorUnitDropdownEntry(SensorUnit.none, "None"),
            _createSensorUnitDropdownEntry(SensorUnit.temperature, "Temperature"),
            _createSensorUnitDropdownEntry(SensorUnit.humidity, "Humidity"),
            _createSensorUnitDropdownEntry(SensorUnit.percent, "Percent"),
          ],
          onSelected: (value) => setState(() {
            unit = value ?? SensorUnit.none;
          }),
        ),
        SizedBox(height: 10),
        TextCheckbox(
          value: allowAddingWhenConnectionFailure,
          onChanged: (value) => setState(() => allowAddingWhenConnectionFailure = value),
          text: Text("Allow adding non-responding sensor", style: TextStyle(fontSize: 15)),
        ),
        SizedBox(height: 20),
        if (loading) LinearProgressIndicator(),
        SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: loading ? null : _cancelInput,
              child: Text(
                "Cancel",
                style: textBtnStyle.copyWith(color: colorScheme.onSurfaceVariant),
              ),
            ),
            TextButton(
              onPressed: loading ? null : _validateInput,
              child: Text("Save", style: textBtnStyle),
            ),
          ],
        ),
        SizedBox(height: 5),
      ],
    );
  }
}
