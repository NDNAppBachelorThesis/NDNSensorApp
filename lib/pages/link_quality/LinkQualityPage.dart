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
  late final Future<Map<String, DeviceInfo>> future;

  Future<Map<String, DeviceInfo>> loadData(NDNApiWrapper apiWrapper) async {
    bool doRun = true;
    List<DeviceInfo> resultCache = [];

    // ---  Find all devices  ---
    apiWrapper.runDeviceDiscovery(
      (deviceId, isNFD, finished) {
        if (!finished) {
          resultCache.add(DeviceInfo(deviceId!, isNFD!));
        } else {
          doRun = false;
        }
      },
    );
    while (doRun) {
      await Future.delayed(Duration(milliseconds: 10));
    }

    Map<String, DeviceInfo> result = {};
    for (var element in resultCache) {
      result[element.id] = element;
    }

    // ---  Fetch all sensor qualities  ---

    var qualities = await Future.wait(resultCache.map((e) => apiWrapper.getSensorLinkQualities(e.id)));

    for (var i = 0; i < resultCache.length; i++) {
      var deviceInfo = resultCache[i];
      var quality = qualities[i];

      result[deviceInfo.id]!.qualityMap = quality.map((key, value) => MapEntry(key.toString(), value));
    }

    return result;
  }

  @override
  void initState() {
    super.initState();
    future = loadData(context.read<NDNApiWrapper>());
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
        child: FutureBuilder(
          future: future,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Text("Error: ${snapshot.error}");
            } else if (!snapshot.hasData) {
              return _Loading();
            }

            var data = snapshot.data!;
            return _LinkQuality(data);
          },
        ),
      ),
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text("Searching for available sensors..."),
          SizedBox(height: 20),
          CircularProgressIndicator(),
        ],
      ),
    );
  }
}

class _LinkQuality extends StatefulWidget {
  final Map<String, DeviceInfo> availableDevices;

  const _LinkQuality(this.availableDevices, {super.key});

  @override
  State<_LinkQuality> createState() => _LinkQualityState();
}

class _LinkQualityState extends State<_LinkQuality> {
  var zoomKey = GlobalKey();
  Offset? lastTapPosition;

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
      setState(() {
        injectMarkerPositions();
      });
    });
  }

  void injectMarkerPositions() {
    var lookup = {
      // NFDs
      "123": (0.18922539658771828, 0.49491724484244753),
      // Devices
      "198328652539720": (0.8706381641558737, 0.4158521646138516),
      "233585120353436": (0.6305785123962663, 0.7951537972516991),
      // "159348532864940": (0.8429355270415819, 0.7615024862619101),
      // "92843337030812": (0.6705678640697553, 0.7934779904469904),
      // "8794131624": (0.742915378368151, 0.9264777441759959),
      // "3164613112": (0.8302219651718544, 0.921854030855141),
    };

    var imageSize = _getImageSize();
    if (imageSize == null) {
      return;
    }

    var imgX = imageSize.width;
    var imgY = imageSize.height;

    widget.availableDevices.forEach((deviceId, deviceInfo) {
      var position = lookup[deviceId];
      if (position == null) {
        return;
      }

      deviceInfo.x = imgX * position.$1;
      deviceInfo.y = imgY * position.$2;
    });
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
  }

  List<LinkLineInfo> _calculateLinkLines() {
    List<LinkLineInfo> res = [];
    var devices = widget.availableDevices;
    Map<String, Map<String, double>> linkQualities = {};

    // Create quality mapping
    devices.forEach((srcDevice, srcInfo) {
      srcInfo.qualityMap.forEach((dstDevice, quality) {
        if (!linkQualities.containsKey(srcDevice)) {
          linkQualities[srcDevice] = {};
        }
        linkQualities[srcDevice]![dstDevice] = quality;
      });
    });

    Set<(String, String)> alreadyAdded = {};

    // Convert to LinkLineInfos
    devices.forEach((srcId, deviceInfo) {
      deviceInfo.qualityMap.forEach((dstId, _) {
        if (alreadyAdded.contains((srcId, dstId))) {
          return;
        }

        try {
          // ToDo: Remove if link quality is fixed. This prevents links between non-nfd devices
          if (!devices[srcId]!.isNFD && !devices[dstId]!.isNFD) {
            return;
          }

          res.add(
              LinkLineInfo(deviceInfo, devices[dstId]!, linkQualities[srcId]![dstId]!, linkQualities[dstId]![srcId]!));
        } on Error {
          // Catch "! on null value" error
          print("NullError: $srcId, $dstId");
        }
        alreadyAdded.add((srcId, dstId));
        alreadyAdded.add((dstId, srcId));
      });
    });

    return res;
  }

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
    var linkLines = _calculateLinkLines();

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
                  scale: 0.25,
                ),
              ),
              for (var deviceInfo in widget.availableDevices.values) _Marker(data: deviceInfo),
              for (var lineInfo in linkLines) _LinkLine(lineInfo),
              for (var lineInfo in linkLines) _LinkLineText(lineInfo),
            ],
          ),
        ),
      ),
    );
  }
}

class _Marker extends StatefulWidget {
  final DeviceInfo data;

  const _Marker({required this.data, super.key});

  @override
  State<_Marker> createState() => _MarkerState();
}

class _MarkerState extends State<_Marker> {
  @override
  Widget build(BuildContext context) {
    const scaling = 2.0;
    var imageName = widget.data.isNFD ? "nfd_pin.png" : "sensor_pin.png";

    var textSuffix = widget.data.isNFD ? "\n(NFD Server)" : "";

    return Positioned(
      left: widget.data.x - (256 / scaling / 2),
      top: widget.data.y - (256 / scaling),
      child: Tooltip(
        message: "ID: ${widget.data.id}$textSuffix",
        textStyle: TextStyle(fontSize: 16, color: Colors.white),
        triggerMode: TooltipTriggerMode.tap,
        verticalOffset: -(128 / scaling),
        showDuration: Duration(seconds: 3),
        child: Image.asset("assets/images/$imageName", scale: scaling),
      ),
    );
  }
}

class _LinkLine extends StatelessWidget {
  final LinkLineInfo lineInfo;

  const _LinkLine(this.lineInfo, {super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _LinkPainter(Offset(lineInfo.from.x, lineInfo.from.y), Offset(lineInfo.to.x, lineInfo.to.y)),
    );
  }
}

class _LinkLineText extends StatelessWidget {
  final LinkLineInfo lineInfo;

  const _LinkLineText(this.lineInfo, {super.key});

  Size _textSize(String text, TextStyle style) {
    final TextPainter textPainter = TextPainter(
        text: TextSpan(text: text, style: style), maxLines: 1, textDirection: TextDirection.ltr)
      ..layout(minWidth: 0, maxWidth: double.infinity);
    return textPainter.size;
  }

  @override
  Widget build(BuildContext context) {
    var a = (lineInfo.from.x, lineInfo.from.y);
    var b = (lineInfo.to.x, lineInfo.to.y);
    var ab2 = ((b.$1 - a.$1) / 2.0, (b.$2 - a.$2) / 2.0);
    var textPos = (a.$1 + ab2.$1, a.$2 + ab2.$2);
    var fromText = (lineInfo.fromQuality * 100).toStringAsFixed(2);
    var toText = (lineInfo.toQuality * 100).toStringAsFixed(2);

    var fromArrow = "-->";
    var toArrow = "<--";

    if (lineInfo.from.x > lineInfo.to.x) {
      fromArrow = "<--";
      toArrow = "-->";
    }

    var labelText = "$fromText% $fromArrow\n$toText% $toArrow";
    var labelTextStyle = TextStyle(fontSize: 40);
    var textSize = _textSize(labelText, labelTextStyle);

    return Positioned(
      top: textPos.$2 - (textSize.height * 1.3),
      left: textPos.$1 - (textSize.width / 2),
      child: Container(
        decoration: BoxDecoration(
          color: Color(0xFFF6F6F6),
          border: Border.all()
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 8.0),
          child: Text(labelText, style: labelTextStyle),
        ),
      ),
    );
  }
}

class _LinkPainter extends CustomPainter {
  final Offset start;
  final Offset end;

  _LinkPainter(this.start, this.end);

  @override
  void paint(Canvas canvas, Size size) {
    var from = start.translate(0, -5);
    var to = end.translate(0, -5);
    Paint paint = Paint()
      ..color = Colors.blue.shade600
      ..strokeWidth = 8.0;

    canvas.drawLine(from, to, paint);
    canvas.drawCircle(from, 4, paint);
    canvas.drawCircle(to, 4, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

// -----  Data classes  -----

class DeviceInfo {
  final String id;
  final bool isNFD;

  double x = 0.5;
  double y = 0.5;
  Map<String, double> qualityMap = {};

  DeviceInfo(this.id, this.isNFD);

  @override
  String toString() {
    return "DeviceInfo($id, ${qualityMap.keys})";
  }
}

class LinkLineInfo {
  final DeviceInfo from;
  final DeviceInfo to;
  final double fromQuality;
  final double toQuality;

  LinkLineInfo(this.from, this.to, this.fromQuality, this.toQuality);
}
