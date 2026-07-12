import 'dart:ui' as ui;

import 'package:atelier/atelier.dart';
import 'package:atelier_weather_example/src/features/weather/data/repositories/open_meteo_weather_repository.dart';
import 'package:atelier_weather_example/src/features/weather/presentation/weather_view_model.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> with AtelierVmMixin<WeatherViewModel, WeatherScreen> {
  late final _repository = disposeWith(OpenMeteoWeatherRepository(), (value) => value.close());

  @override
  WeatherViewModel createViewModel(BuildContext context) {
    return WeatherViewModel(_repository);
  }

  @override
  Widget build(BuildContext context) {
    final weather = watchSelect(viewModel.state, (state) => state.weather);

    return Scaffold(
      body: Stack(
        children: [
          WeatherBackground(child: const SafeArea(child: SizedBox.expand())),
          Positioned.fill(child: _WeatherContent()),
        ],
      ),
    );
  }
}

class _WeatherContent extends StatelessWidget {
  const _WeatherContent();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: .start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16, top: 32),
            child: Row(
              spacing: 8,
              children: [
                PhosphorIcon(PhosphorIconsLight.cloudRain, size: 96, color: Colors.black),
                Text('16°', style: GoogleFonts.inter(fontSize: 48)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 24, right: 24, top: 148),
            child: Text.rich(
              TextSpan(
                text: "It's fucking ",
                style: TextStyle(fontSize: 72, height: 1),
                children: [
                  TextSpan(
                    text: 'raining. ',
                    style: TextStyle(
                      foreground: Paint()
                        ..style = PaintingStyle.stroke
                        ..strokeWidth = 2
                        ..strokeJoin = StrokeJoin.round,
                    ),
                  ),
                  TextSpan(text: 'now.'),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 24, right: 24, top: 148),
            child: Row(
              mainAxisAlignment: .spaceBetween,
              children: [
                Text('Kraków', style: GoogleFonts.inter(fontSize: 24)),
                ClipOval(
                  child: BackdropFilter(
                    filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                    child: IconButton.filledTonal(
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: .65),
                        shape: const CircleBorder(),
                      ),
                      onPressed: () {},
                      icon: PhosphorIcon(PhosphorIconsRegular.mapPin, size: 32),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class WeatherBackground extends StatefulWidget {
  const WeatherBackground({super.key, required this.child});
  final Widget child;

  @override
  State<WeatherBackground> createState() => _WeatherBackgroundState();
}

class _WeatherBackgroundState extends State<WeatherBackground> {
  static const _shaderAsset = 'assets/shaders/noise.frag';

  ui.FragmentProgram? _program;

  @override
  void initState() {
    super.initState();
    _loadShader();
  }

  Future<void> _loadShader() async {
    try {
      final program = await ui.FragmentProgram.fromAsset(_shaderAsset);
      if (!mounted) return;
      setState(() => _program = program);
    } catch (_) {
      // Keep the painted gradient fallback if runtime shaders are unavailable.
    }
  }

  @override
  Widget build(BuildContext context) {
    final pixelRatio = MediaQuery.devicePixelRatioOf(context);
    return SizedBox.expand(
      child: CustomPaint(
        key: const Key('weather-background-grain'),
        painter: _NoisePainter(program: _program, devicePixelRatio: pixelRatio),
        child: widget.child,
      ),
    );
  }
}

class _NoisePainter extends CustomPainter {
  const _NoisePainter({required this.program, required this.devicePixelRatio});

  final ui.FragmentProgram? program;
  final double devicePixelRatio;

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Offset.zero & size;
    canvas.drawRect(
      bounds,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment(-2, -1),
          end: Alignment(1.5, 1.5),
          colors: [
            Colors.white,
            Color.lerp(Colors.white, Colors.blueAccent, 0.156)!,
            Color.lerp(Colors.white, Colors.blueAccent, 0.5)!,
            Color.lerp(Colors.white, Colors.blueAccent, 0.844)!,
            Colors.blueAccent,
            Color.lerp(Colors.blueAccent, Colors.white, 0.156)!,
            Color.lerp(Colors.blueAccent, Colors.white, 0.5)!,
            Color.lerp(Colors.blueAccent, Colors.white, 0.844)!,
            Colors.white,
          ],
        ).createShader(bounds),
    );

    final program = this.program;
    if (program == null) return;

    final shader = program.fragmentShader()..setFloat(0, devicePixelRatio);
    canvas.drawRect(
      bounds,
      Paint()
        ..shader = shader
        ..blendMode = BlendMode.softLight,
    );
  }

  @override
  bool shouldRepaint(_NoisePainter oldDelegate) =>
      oldDelegate.program != program || oldDelegate.devicePixelRatio != devicePixelRatio;
}
