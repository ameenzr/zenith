import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:flutter/services.dart';
import 'package:torch_light/torch_light.dart';
import 'package:flutter_volume_controller/flutter_volume_controller.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'dart:math';
import 'package:wifi_iot/wifi_iot.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.light;

  void _toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ultimate Control Panel',
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: _themeMode,
      home: ControlPanel(toggleTheme: _toggleTheme),
    );
  }
}

class ControlPanel extends StatefulWidget {
  final VoidCallback toggleTheme;

  ControlPanel({required this.toggleTheme});

  @override
  _ControlPanelState createState() => _ControlPanelState();
}

class _ControlPanelState extends State<ControlPanel> {
  double volume = 0.5;
  bool isWiFiOn = false;
  bool isBluetoothOn = false;
  bool isTorchOn = false;
  double _lastX = 0;

  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _startAccelerometer();
    _initVolume();
  }

  void _startAccelerometer() {
    accelerometerEvents.listen((AccelerometerEvent event) {
      setState(() {
        // Map device tilt to volume level changes
        if (event.x - _lastX > 1 || event.x - _lastX < -1) {
          volume = (min(max(volume + event.x * 0.01, 0), 1)).toDouble();
          _lastX = event.x;
        }
      });
      updateVolume(volume);
    });
  }

  Future<void> _initVolume() async {
    volume = (await FlutterVolumeController.getVolume())!;
  }

  void updateVolume(double newVolume) {
    setState(() {
      volume = newVolume;
    });
    FlutterVolumeController.setVolume(newVolume);
  }

  void _toggleWiFi() async {
    _randomizeToggle();
  }

  void _toggleWiFiReal() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    setState(() {
      isWiFiOn = !isWiFiOn;
    });
    if (isWiFiOn) {
      await WiFiForIoTPlugin.setEnabled(true);
    } else {
      await WiFiForIoTPlugin.setEnabled(false);
    }
  }

  void _toggleBluetooth() async {
    _randomizeToggle();
  }

  void _toggleBluetoothReal() async {
    final BluetoothState state = await FlutterBluetoothSerial.instance.state;
    setState(() {
      isBluetoothOn = !isBluetoothOn;
    });
  }

  void _toggleTorch() async {
    _randomizeToggle();
  }

  void _toggleTheme() {
    _randomizeToggle();
  }

  void _toggleTorchReal() async {
    if (isTorchOn) {
      await TorchLight.disableTorch();
    } else {
      await TorchLight.enableTorch();
    }
    setState(() {
      isTorchOn = !isTorchOn;
    });
  }

  void _randomizeToggle() {
    int option = _random.nextInt(4);
    switch (option) {
      case 0:
        _toggleBluetoothReal();
        break;
      case 1:
        widget.toggleTheme();
        break;
      case 2:
        _toggleTorchReal();
        break;
      case 3:
        _toggleWiFiReal();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Ultimate Control Panel'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Text(
              'Volume Level: ${(volume * 100).toInt()}%',
              style: TextStyle(fontSize: 20),
            ),
            Slider(
              value: volume,
              onChanged: null, // Disable manual control
              min: 0,
              max: 1,
            ),
            SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: Icon(
                    isWiFiOn ? Icons.wifi : Icons.wifi_off,
                    color: isWiFiOn ? Colors.green : Colors.red,
                  ),
                  onPressed: _toggleWiFi,
                ),
                IconButton(
                  icon: Icon(
                    isBluetoothOn ? Icons.bluetooth : Icons.bluetooth_disabled,
                    color: isBluetoothOn ? Colors.blue : Colors.grey,
                  ),
                  onPressed: _toggleBluetooth,
                ),
                IconButton(
                  icon: Icon(
                    isTorchOn ? Icons.flash_on : Icons.flash_off,
                    color: isTorchOn ? Colors.orange : Colors.grey,
                  ),
                  onPressed: _toggleTorch,
                ),
                IconButton(
                  icon: Icon(
                    Icons.brightness_6,
                    color: Theme.of(context).brightness == Brightness.dark ? Colors.yellow : Colors.grey,
                  ),
                  // onPressed: widget.toggleTheme,
                  onPressed: _toggleTheme,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
