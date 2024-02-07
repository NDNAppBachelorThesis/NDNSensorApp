import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:ndn_sensor_app/provided/ndn_api_wrapper.dart';
import 'package:ndn_sensor_app/widgets/drawer.dart';
import 'package:provider/provider.dart';
import 'package:zoom_widget/zoom_widget.dart';

class LinkQualityPage extends StatefulWidget {
  const LinkQualityPage({super.key});

  @override
  State<LinkQualityPage> createState() => _LinkQualityPageState();
}

class _LinkQualityPageState extends State<LinkQualityPage> {
  List<String> devices = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    List<String> idCache = [];
    context.read<NDNApiWrapper>().runDeviceDiscovery((deviceId, finished) {
      if (!finished) {
        idCache.add(deviceId!);
      } else {
        setState(() {
          devices = idCache;
          loading = false;
        });
      }
    },);
  }

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
        child: loading ? _Loading() : _LinkQuality(devices),
      ),
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text("Searching for available sensors..."),
        SizedBox(height: 20),
        CircularProgressIndicator(),
      ],
    ));
  }
}


class _LinkQuality extends StatefulWidget {
  final List<String> availableDevices;

  const _LinkQuality(this.availableDevices, {super.key});

  @override
  State<_LinkQuality> createState() => _LinkQualityState();
}

class _LinkQualityState extends State<_LinkQuality> {
  var zoomKey = GlobalKey();
  List<MarkerData> markers = [];
  Offset? lastTapPosition;

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
      setState(() {
        markers = getMarkersForDevices();
      });
    });
  }

  List<MarkerData> getMarkersForDevices() {
    var lookup = {
      "198328652539720": (0.82643269751359, 0.6774511199817548),
      "233585120353436": (0.7339463222698952, 0.6365407256185107),
      "159348532864940": (0.8429355270415819, 0.7615024862619101),
      "92843337030812": (0.6705678640697553, 0.7934779904469904),
      "8794131624": (0.742915378368151, 0.9264777441759959),
      "3164613112": (0.8302219651718544, 0.921854030855141),
    };

    var imageSize = _getImageSize();
    if (imageSize == null) {
      return [];
    }

    var imgX = imageSize.width;
    var imgY = imageSize.height;

    return widget.availableDevices
        .map((i) => (i, lookup[i]))
        .where((element) => element.$2 != null)
        .map((e) => MarkerData(imgX * e.$2!.$1, imgY * e.$2!.$2, e.$1))
        .toList();
  }

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

    final dx = lastTapPosition!.dx;
    final dy = lastTapPosition!.dy;
    print("Add marker at $dx, $dy");

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

class _Marker extends StatefulWidget {
  final MarkerData data;

  const _Marker({required this.data, super.key});

  @override
  State<_Marker> createState() => _MarkerState();
}

class _MarkerState extends State<_Marker> {
  String quality = "Loading...";

  @override
  void initState() {
    super.initState();
    context.read<NDNApiWrapper>().getSensorLinkQuality(widget.data.sensorId)
        .then((value) => setState(() => quality = "$value%"))
        .onError((error, stackTrace) => setState(() => quality = "Error"));
  }

  @override
  Widget build(BuildContext context) {
    const scaling = 6.0;

    return Positioned(
      left: widget.data.x - (256 / scaling / 2),
      top: widget.data.y - (256 / scaling),
      child: Tooltip(
        message: "ID: ${widget.data.sensorId}\nQuality: $quality",
        textStyle: TextStyle(fontSize: 16, color: Colors.white),
        triggerMode: TooltipTriggerMode.tap,
        verticalOffset: - (256 / scaling),
        showDuration: Duration(seconds: 3),
        child: Image.asset("assets/images/sensor_pin.png", scale: scaling),
      ),
    );
  }

}
