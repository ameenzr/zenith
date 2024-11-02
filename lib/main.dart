import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_volume_controller/flutter_volume_controller.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Slingshot Volume Control',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: VolumeControlPage(),
    );
  }
}

class VolumeControlPage extends StatefulWidget {
  @override
  _VolumeControlPageState createState() => _VolumeControlPageState();
}

class _VolumeControlPageState extends State<VolumeControlPage>
    with SingleTickerProviderStateMixin {
  double volume = 0.5;
  double pullDistance = 0.0; // Represents how much the icon is pulled
  double stonePosition = 0.5; // Stone's horizontal position on the slider
  double stoneVerticalPosition = 0.0; // Vertical position of the stone
  bool isShooting = false;
  late AnimationController animationController;

  @override
  void initState() {
    super.initState();
    _initVolume();
    animationController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 1),
    )..addListener(() {
      if (isShooting) {
        // Parabolic motion calculation
        double t = animationController.value; // Normalized time (0 to 1)
        double initialVelocity = pullDistance * 300; // Speed based on pull
        double gravity = 500; // Arbitrary gravity to create arc

        // Calculate stone position
        stonePosition = pullDistance * t; // Horizontal position based on pull
        stoneVerticalPosition = (initialVelocity * t) - (0.5 * gravity * pow(t, 2));

        // Clamp vertical position to ensure it doesn't go too high
        stoneVerticalPosition = stoneVerticalPosition.clamp(-100.0, 0.0); // Adjust based on your needs

        // When the animation completes, update volume and reset
        if (animationController.isCompleted) {
          updateVolume(stonePosition.clamp(0.0, 1.0));
          setState(() {
            isShooting = false;
            pullDistance = 0.0; // Reset the slingshot pull
            stoneVerticalPosition = 0.0; // Reset vertical position
          });
        }
      }
    });
  }

  Future<void> _initVolume() async {
    volume = (await FlutterVolumeController.getVolume())!;
    setState(() {
      stonePosition = volume;
    });
  }

  void startShooting() {
    setState(() {
      isShooting = true;
    });
    animationController.reset();
    animationController.forward();
  }

  void updateVolume(double newVolume) {
    setState(() {
      volume = newVolume;
    });
    FlutterVolumeController.setVolume(newVolume);
  }

  @override
  void dispose() {
    animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
        title: Text('Slingshot Volume Control'),
    ),
    body: Padding(
    padding: const EdgeInsets.all(20.0), // Add padding around the entire body
    child: Center(
    child: Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
    GestureDetector(
    onPanUpdate: (details) {
    if (!isShooting) {
    setState(() {
    pullDistance -= details.delta.dx / 200;
    pullDistance = pullDistance.clamp(0.0, 1.0);
    });
    }
    },
    onPanEnd: (_) {
    if (!isShooting) {
    startShooting();
    }
    },
    child: Stack(
    alignment: Alignment.center,
    children: [
      // Volume icon as slingshot
      Transform.translate(
        offset: Offset(-pullDistance * 50, 0), // Move icon based on pull
        child: Icon(
          Icons.volume_up,
          size: 70, // Increased size for better visibility
          color: Colors.blue,
        ),
      ),
      // Stone following a parabolic trajectory
      Positioned(
        left: 200 * stonePosition, // Adjusted by trajectory animation
        top: stoneVerticalPosition, // Vertical position based on trajectory
        child: Icon(
          Icons.circle,
          size: 20,
          color: Colors.red,
        ),
      ),
    ],
    ),
    ),
      SizedBox(width: 40), // Increased space between icon and slider
      // Volume slider (Non-interactive, shows current volume)
      Expanded(
        child: Slider(
          value: volume,
          min: 0.0,
          max: 1.0,
          divisions: 10,
          label: '${(volume * 100).round()}%',
          onChanged: null, // Disable manual adjustment
        ),
      ),
    ],
    ),
    ),
    ),
    );
  }
}