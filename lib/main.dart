import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:usbcan_plugins/usbcan.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Flutter Demo',
      home: MainPage(),
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  final UsbCan _usbCan = UsbCan();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
          child: TextButton(
              child: const Text("Connect"),
              onPressed: () async {
                bool isConnected = await _usbCan.connectUSB();
                // var isConnected = true;
                if (!mounted) return;
                if (isConnected) {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => SetteingPage(
                                usbCan: _usbCan,
                              )));
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text("Connection Failed"),
                  ));
                }
              })),
    );
  }
}

class SetteingPage extends StatefulWidget {
  const SetteingPage({super.key, required this.usbCan});
  final UsbCan usbCan;
  @override
  State<SetteingPage> createState() => _SetteingPageState();
}

class PIDParameters {
  double P = 0;
  double I = 0;
  double D = 0;
  double max = 0;
  double epsilon = 0;
}

class _SetteingPageState extends State<SetteingPage> {
  int canID = 0x000;
  double target = 0;

  PIDParameters current = PIDParameters();
  PIDParameters position = PIDParameters();

  @override
  void initState() {
    super.initState();

    current.P = 12;
    current.D = -7.5;
    current.epsilon = 2000;
    current.max = 19433;
    position.P = 0.3;
    position.D = 96;
    position.epsilon = 200;
    position.max = 1000;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(title: const Text("Setting")),
        body: SingleChildScrollView(
          child: Center(
              child: Column(children: [
            SizedBox(
              height: 100,
              child: Row(
                children: [
                  const SizedBox(width: 130, child: Text("Can Base High ID")),
                  Expanded(
                      child: TextField(
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      switch (int.tryParse(value)) {
                        case null:
                          break;
                        case int i:
                          canID = i << 2;
                          setState(() {});
                      }
                    },
                  ))
                ],
              ),
            ),
            ButtonBar(
              children: [
                TextButton(
                    onPressed: () {
                      widget.usbCan.sendFrame(CANFrame.fromIdAndData(
                          canID + 1, Uint8List.fromList([0])));
                    },
                    child: const Text("Stop")),
                TextButton(
                    onPressed: () {
                      widget.usbCan.sendFrame(CANFrame.fromIdAndData(
                          canID + 1, Uint8List.fromList([2])));
                    },
                    child: const Text("Current")),
                TextButton(
                    onPressed: () {
                      widget.usbCan.sendFrame(CANFrame.fromIdAndData(
                          canID + 1, Uint8List.fromList([3])));
                    },
                    child: const Text("Position")),
              ],
            ),
            CustomSlider(
              value: target,
              onChanged: (value) {
                setState(() {
                  target = value;
                });
                widget.usbCan.sendFrame(CANFrame.fromIdAndData(canID,
                    Float32List.fromList([target]).buffer.asUint8List()));
              },
              parameterName: "target",
            ),
            const SizedBox(
              height: 100,
            ),
            CustomSlider(
                value: current.P,
                onChanged: (value) {
                  setState(() {
                    current.P = value;
                  });
                  _sendParam(0, value);
                },
                parameterName: "currentP"),
            CustomSlider(
                value: current.I,
                onChanged: (value) {
                  setState(() {
                    current.I = value;
                  });
                  _sendParam(1, value);
                },
                parameterName: "currentI"),
            CustomSlider(
                value: current.D,
                onChanged: (value) {
                  setState(() {
                    current.D = value;
                  });
                  _sendParam(2, value);
                },
                parameterName: "currentD"),
            CustomSlider(
                value: current.max,
                onChanged: (value) {
                  setState(() {
                    current.max = value;
                  });
                  _sendParam(3, value);
                },
                parameterName: "currentMax"),
            CustomSlider(
                value: current.epsilon,
                onChanged: (value) {
                  setState(() {
                    current.epsilon = value;
                  });
                  _sendParam(10, value);
                },
                parameterName: "currentEpsilon"),
            CustomSlider(
                value: position.P,
                onChanged: (value) {
                  setState(() {
                    position.P = value;
                  });
                  _sendParam(4, value);
                },
                parameterName: "positionP"),
            CustomSlider(
                value: position.I,
                onChanged: (value) {
                  setState(() {
                    position.I = value;
                  });
                  _sendParam(5, value);
                },
                parameterName: "positionI"),
            CustomSlider(
                value: position.D,
                onChanged: (value) {
                  setState(() {
                    position.D = value;
                  });
                  _sendParam(6, value);
                },
                parameterName: "positionD"),
            CustomSlider(
                value: position.max,
                onChanged: (value) {
                  setState(() {
                    position.max = value;
                  });
                  _sendParam(7, value);
                },
                parameterName: "positionMax"),
            CustomSlider(
                value: position.epsilon,
                onChanged: (value) {
                  setState(() {
                    position.epsilon = value;
                  });
                  _sendParam(11, value);
                },
                parameterName: "positionEpsilon"),
          ])),
        ),
      ),
    );
  }

  void _sendParam(int id, double val) {
    Uint8List data = Uint8List(5);
    data[0] = id;
    data.setRange(1, 5, Float32List.fromList([val]).buffer.asUint8List());
    widget.usbCan.sendFrame(CANFrame.fromIdAndData(canID + 2, data));
  }
}

class CustomSlider extends StatefulWidget {
  const CustomSlider({
    super.key,
    required this.value,
    required this.onChanged,
    required this.parameterName,
  });
  final double value;
  final String parameterName;
  final Function(double) onChanged;

  @override
  State<CustomSlider> createState() => _CustomSliderState();
}

class _CustomSliderState extends State<CustomSlider> {
  double scaler = 1;

  @override
  Widget build(BuildContext context) {
    double sliderValue = switch (widget.value / scaler) {
      > 1 => 1,
      < -1 => -1,
      _ => widget.value / scaler
    };

    return Row(children: [
      SizedBox(
        width: 40,
        child: Text(widget.parameterName),
      ),
      SizedBox(
        width: 40,
        child: TextButton(
          child: Text(widget.value.toStringAsFixed(2)),
          onPressed: () {
            widget.onChanged(0);
          },
        ),
      ),
      Expanded(
        child: Slider.adaptive(
          value: sliderValue,
          onChanged: (value) {
            widget.onChanged(value * scaler);
          },
          min: -1,
          max: 1,
        ),
      ),
      SizedBox(
        width: 40,
        child: TextField(
          keyboardType: TextInputType.number,
          onChanged: (value) {
            scaler = double.tryParse(value) ?? scaler;
            setState(() {});
          },
        ),
      )
    ]);
  }
}
