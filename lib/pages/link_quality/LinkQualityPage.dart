import 'package:flutter/material.dart';
import 'package:ndn_sensor_app/widgets/drawer.dart';
import 'package:zoom_widget/zoom_widget.dart';

class LinkQualityPage extends StatefulWidget {
  const LinkQualityPage({super.key});

  @override
  State<LinkQualityPage> createState() => _LinkQualityPageState();
}

class _LinkQualityPageState extends State<LinkQualityPage> {
  @override
  Widget build(BuildContext context) {
    var colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: colorScheme.inversePrimary,
        title: Text("Link Quality"),
      ),
      drawer: AppDrawer(),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        child: _LinkQuality(),
      ),
    );
  }
}

class _LinkQuality extends StatefulWidget {
  const _LinkQuality({super.key});

  @override
  State<_LinkQuality> createState() => _LinkQualityState();
}

class _LinkQualityState extends State<_LinkQuality> {
  var zoomKey = GlobalKey();
  final markers = <MarkerData>[
    MarkerData(751.5708418867484, 573.0261938566197, "2323235644"),
    MarkerData(580.1684081298546, 694.0488370155447, "5431651351"),
    MarkerData(622.2878670953639, 739.8691689445507, "6879843145"),
    MarkerData(657.3580442256420, 826.5753355181180, "6316498465"),
    MarkerData(752.8758130930316, 837.5017223628716, "8794131624"),
    MarkerData(757.9865424235746, 680.4789694830854, "3164613112"),
  ];
  Offset? lastTapPosition;

  Size? _getImageSize() {
    final keyContext = zoomKey.currentContext;
    if (keyContext == null) {
      return null;
    }

    final box = keyContext.findRenderObject() as RenderBox;
    return box.size;
  }

  void _handleTapDown(TapDownDetails details) {
    final widgetSize = _getImageSize();
    if (widgetSize == null) {
      return;
    }

    final tapPosition = details.localPosition;
    final relativePosition = Offset(tapPosition.dx / widgetSize.width, tapPosition.dy / widgetSize.height);

    // print("Tap: ${tapPosition.dx}, ${tapPosition.dy}");
    lastTapPosition = relativePosition;
  }

  void _handleTap() {
    if (lastTapPosition == null) {
      return;
    }
    final imageSize = _getImageSize();
    if (imageSize == null) {
      return;
    }

    final widgetX = imageSize.width * lastTapPosition!.dx;
    final widgetY = imageSize.height * lastTapPosition!.dy;
    print("Add marker at $widgetX, $widgetY");

    // setState(() {
    //   markers.add(MarkerData(widgetX, widgetY, "11274238333"));
    // });
  }

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;

    return SizedBox(
      width: size.width,
      height: size.height,
      child: Zoom(
        backgroundColor: Colors.transparent,
        maxZoomHeight: size.height,
        maxZoomWidth: size.height,
        initTotalZoomOut: true,
        maxScale: 3,
        centerOnScale: true,
        child: Container(
          decoration: BoxDecoration(
              border: Border.all(width: 2, color: Colors.black38), borderRadius: BorderRadius.circular(16)),
          child: Stack(
            key: zoomKey,
            children: [
              GestureDetector(
                onTap: _handleTap,
                onTapDown: _handleTapDown,
                child: Image.asset(
                  "assets/images/room-plan.png",
                ),
              ),
              for (var markerData in markers) _Marker(data: markerData)
            ],
          ),
        ),
      ),
    );
  }
}

class MarkerData {
  final double x;
  final double y;
  final String sensorId;

  MarkerData(this.x, this.y, this.sensorId);
}

class _Marker extends StatelessWidget {
  final MarkerData data;

  const _Marker({required this.data, super.key});

  @override
  Widget build(BuildContext context) {
    const scaling = 6.0;

    return Positioned(
      left: data.x - (256 / scaling / 2),
      top: data.y - (256 / scaling),
      child: Tooltip(
        message: "ID: ${data.sensorId}\nQuality: 98%",
        textStyle: TextStyle(fontSize: 16, color: Colors.white),
        triggerMode: TooltipTriggerMode.tap,
        verticalOffset: - (256 / scaling),
        showDuration: Duration(seconds: 3),
        child: Image.asset("assets/images/sensor_pin.png", scale: scaling),
      ),
    );
  }
}
