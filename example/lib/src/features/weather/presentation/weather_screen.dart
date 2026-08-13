import 'dart:async';
import 'dart:ui' as ui;

import 'package:atelier/atelier.dart';
import 'package:atelier_weather_example/src/features/weather/domain/entities/weather.dart';
import 'package:atelier_weather_example/src/features/weather/domain/repositories/weather_repository.dart';
import 'package:atelier_weather_example/src/features/weather/presentation/weather_view_model.dart';
import 'package:atelier_weather_example/src/features/weather/presentation/weather_search_view_model.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({
    super.key,
    required this.repository,
  });

  final WeatherRepository repository;

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> with AtelierVmMixin<WeatherViewModel, WeatherScreen> {
  @override
  WeatherViewModel createViewModel(BuildContext context) {
    return WeatherViewModel(widget.repository);
  }

  @override
  void initState() {
    super.initState();
    viewModel.load('Kraków');
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = watchSelect(
      viewModel.state,
      (state) => (
        weather: state.weather,
        loadStatus: state.loadStatus,
        requestedCity: state.requestedCity,
      ),
    );

    return Scaffold(
      body: Stack(
        children: [
          WeatherBackground(
            weather: snapshot.weather,
            child: const SafeArea(child: SizedBox.expand()),
          ),
          Positioned.fill(
            child: _WeatherContent(
              snapshot: snapshot,
              onOpenSearch: () => _openSearch(context),
              onRetry: () => viewModel.load(snapshot.requestedCity.isEmpty ? 'Kraków' : snapshot.requestedCity),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openSearch(BuildContext context) async {
    final city = await Navigator.of(context).push<String>(
      MaterialPageRoute<String>(
        fullscreenDialog: true,
        builder: (context) => WeatherSearchScreen(repository: widget.repository),
      ),
    );

    if (city != null && mounted) viewModel.load(city);
  }
}

class _WeatherContent extends StatelessWidget {
  const _WeatherContent({
    required this.snapshot,
    required this.onOpenSearch,
    required this.onRetry,
  });

  final ({Weather? weather, WeatherLoadStatus loadStatus, String requestedCity}) snapshot;
  final VoidCallback onOpenSearch;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final weather = snapshot.weather;
    if (weather == null) {
      return SafeArea(
        child: Center(
          child: switch (snapshot.loadStatus) {
            WeatherLoadStatus.notFound => _WeatherUnavailable(
              message: 'City weather was not found.',
              onRetry: onRetry,
            ),
            WeatherLoadStatus.serviceUnavailable => _WeatherUnavailable(
              message: 'Weather is unavailable right now.',
              onRetry: onRetry,
            ),
            WeatherLoadStatus.emptyInput => _WeatherUnavailable(
              message: 'Choose a city to see the weather.',
              onRetry: onRetry,
            ),
            _ => const CircularProgressIndicator(color: Colors.black),
          },
        ),
      );
    }

    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxHeight < 620 || constraints.maxWidth < 350;
          final horizontalPadding = compact ? 20.0 : 28.0;

          return AnimatedSwitcher(
            duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 420),
            reverseDuration: reduceMotion ? Duration.zero : const Duration(milliseconds: 260),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            // Keep only the current report interactive while the new city
            // settles in. This also prevents duplicate accessibility actions.
            layoutBuilder: (currentChild, previousChildren) => currentChild ?? const SizedBox.shrink(),
            transitionBuilder: (child, animation) {
              final offset = Tween<Offset>(
                begin: const Offset(0, .025),
                end: Offset.zero,
              ).animate(animation);
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(position: offset, child: child),
              );
            },
            child: Semantics(
              key: ValueKey(weather.city),
              liveRegion: true,
              child: _WeatherReport(
                weather: weather,
                compact: compact,
                horizontalPadding: horizontalPadding,
                loadStatus: snapshot.loadStatus,
                requestedCity: snapshot.requestedCity,
                onOpenSearch: onOpenSearch,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _WeatherReport extends StatelessWidget {
  const _WeatherReport({
    required this.weather,
    required this.compact,
    required this.horizontalPadding,
    required this.loadStatus,
    required this.requestedCity,
    required this.onOpenSearch,
  });

  final Weather weather;
  final bool compact;
  final double horizontalPadding;
  final WeatherLoadStatus loadStatus;
  final String requestedCity;
  final VoidCallback onOpenSearch;

  @override
  Widget build(BuildContext context) {
    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: compact ? 70 : 86,
              height: compact ? 70 : 86,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .32),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: .58)),
              ),
              alignment: Alignment.center,
              child: PhosphorIcon(
                _conditionIcon(weather),
                size: compact ? 43 : 54,
                color: const Color(0xFF151515),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                '${weather.temperature.round()}°',
                style: GoogleFonts.manrope(
                  fontSize: compact ? 50 : 62,
                  height: .9,
                  fontWeight: FontWeight.w300,
                  letterSpacing: -3,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: compact ? 34 : 72),
        Text(
          'CURRENT WEATHER',
          style: GoogleFonts.manrope(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 2.1,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 12),
        Text.rich(
          TextSpan(
            text: 'It’s ',
            children: [
              TextSpan(
                text: weather.description.toLowerCase(),
                style: const TextStyle(fontStyle: FontStyle.italic),
              ),
              const TextSpan(text: ' now.'),
            ],
          ),
          style: GoogleFonts.fraunces(
            fontSize: compact ? 47 : 66,
            height: .94,
            fontWeight: FontWeight.w500,
            letterSpacing: -2.2,
            color: const Color(0xFF171717),
          ),
        ),
        SizedBox(height: compact ? 32 : 56),
        Container(
          padding: const EdgeInsets.fromLTRB(18, 14, 10, 14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .42),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white.withValues(alpha: .7)),
            boxShadow: const [
              BoxShadow(color: Color(0x12000000), blurRadius: 30, offset: Offset(0, 14)),
            ],
          ),
          child: Row(
            children: [
              const PhosphorIcon(PhosphorIconsRegular.mapPin, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  weather.city,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ),
              ClipOval(
                child: BackdropFilter(
                  filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: IconButton(
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: .65),
                      minimumSize: const Size(48, 48),
                    ),
                    onPressed: onOpenSearch,
                    tooltip: 'Choose a city',
                    icon: const PhosphorIcon(PhosphorIconsRegular.caretRight, size: 22),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (loadStatus != WeatherLoadStatus.success) ...[
          const SizedBox(height: 10),
          Text(
            _staleStatus(loadStatus, requestedCity),
            style: GoogleFonts.manrope(fontSize: 13, color: Colors.black54),
          ),
        ],
      ],
    );

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(horizontalPadding, compact ? 18 : 30, horizontalPadding, 20),
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: constraintsHeight(context, compact)),
        child: body,
      ),
    );
  }

  double constraintsHeight(BuildContext context, bool compact) {
    final height = MediaQuery.sizeOf(context).height - MediaQuery.paddingOf(context).vertical;
    return (height - (compact ? 38 : 50)).clamp(0, double.infinity);
  }
}

class WeatherSearchScreen extends StatefulWidget {
  const WeatherSearchScreen({super.key, required this.repository});

  final WeatherRepository repository;

  @override
  State<WeatherSearchScreen> createState() => _WeatherSearchScreenState();
}

class _WeatherSearchScreenState extends State<WeatherSearchScreen>
    with AtelierVmMixin<WeatherSearchViewModel, WeatherSearchScreen> {
  late final _controller = textController();
  late final _focusNode = focusNode();
  String _query = '';
  bool _isClosing = false;

  @override
  WeatherSearchViewModel createViewModel(BuildContext context) {
    return WeatherSearchViewModel(widget.repository);
  }

  void _search(String value) {
    setState(() => _query = value);
    unawaited(viewModel.search(value));
  }

  void _retry() => unawaited(viewModel.search(_query));

  void _select(String suggestion) => _requestExit(suggestion);

  void _close() => _requestExit();

  void _requestExit([String? city]) {
    if (_isClosing) return;
    _isClosing = true;
    Navigator.of(context).pop<String>(city);
  }

  @override
  Widget build(BuildContext context) {
    final search = watchSelect(
      viewModel.state,
      (state) => (suggestions: state.suggestions, status: state.searchStatus),
    );

    return PopScope<String?>(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _requestExit(result);
      },
      child: Scaffold(
        key: const Key('weather-search-route'),
        resizeToAvoidBottomInset: true,
        body: WeatherBackground(
          paintKey: const Key('weather-search-background-grain'),
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final header = Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Find your weather',
                        style: const TextStyle(
                          fontSize: 34,
                          height: 1,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -1.2,
                        ),
                      ),
                    ),
                    IconButton(
                      key: const Key('weather-search-close'),
                      onPressed: _close,
                      tooltip: 'Close search',
                      icon: const Icon(Icons.close_rounded, size: 30),
                    ),
                  ],
                );
                final field = _SearchField(
                  controller: _controller,
                  focusNode: _focusNode,
                  query: _query,
                  onChanged: _search,
                  onClear: () {
                    _controller.clear();
                    _search('');
                    _focusNode.requestFocus();
                  },
                );

                final children = [
                  header,
                  const SizedBox(height: 18),
                  if (constraints.maxHeight < 520)
                    SizedBox(height: 240, child: _buildResults(search.suggestions, search.status))
                  else
                    Expanded(child: _buildResults(search.suggestions, search.status)),
                  const SizedBox(height: 12),
                  field,
                ];
                final content = Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: children,
                );

                return constraints.maxHeight < 520
                    ? SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                        child: content,
                      )
                    : Padding(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                        child: content,
                      );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResults(List<String> suggestions, WeatherSearchStatus status) {
    if (_query.trim().isEmpty) {
      return const _SearchMessage(
        key: Key('weather-search-prompt'),
        icon: PhosphorIconsLight.mapPin,
        title: 'Search for a city',
        message: 'Enter a place name to check its current weather.',
      );
    }
    if (status == WeatherSearchStatus.loading) {
      return const Center(
        key: Key('weather-search-loading'),
        child: CircularProgressIndicator(color: Colors.black),
      );
    }
    if (status == WeatherSearchStatus.failed) {
      return _SearchMessage(
        key: const Key('weather-search-error'),
        icon: PhosphorIconsLight.cloudWarning,
        title: 'Search is unavailable',
        message: 'Check your connection and try again.',
        action: TextButton(
          key: const Key('weather-search-retry'),
          onPressed: _retry,
          child: const Text('Try again'),
        ),
      );
    }
    if (suggestions.isEmpty) {
      return const _SearchMessage(
        key: Key('weather-search-no-results'),
        icon: PhosphorIconsLight.magnifyingGlass,
        title: 'No cities found',
        message: 'Try another place name or check the spelling.',
      );
    }

    return ListView.separated(
      key: const Key('weather-search-results'),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.only(top: 4, bottom: 8),
      itemCount: suggestions.length,
      separatorBuilder: (context, index) => const Divider(height: 1, color: Colors.black12),
      itemBuilder: (context, index) {
        final suggestion = suggestions[index];
        return Semantics(
          button: true,
          label: 'Load weather for $suggestion',
          child: ListTile(
            key: ValueKey('weather-search-suggestion-$suggestion'),
            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            title: Text(suggestion, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w500)),
            trailing: const Icon(Icons.arrow_forward_rounded),
            onTap: () => _select(suggestion),
          ),
        );
      },
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.focusNode,
    required this.query,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String query;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.9)),
        boxShadow: const [
          BoxShadow(color: Color(0x18000000), blurRadius: 24, offset: Offset(0, 10)),
        ],
      ),
      child: TextField(
        key: const Key('weather-search-field'),
        controller: controller,
        focusNode: focusNode,
        autofocus: true,
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Search city',
          prefixIcon: const Icon(Icons.search_rounded),
          suffixIcon: query.isEmpty
              ? null
              : IconButton(
                  key: const Key('weather-search-clear'),
                  onPressed: onClear,
                  tooltip: 'Clear search',
                  icon: const Icon(Icons.close_rounded),
                ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 17),
        ),
      ),
    );
  }
}

class _SearchMessage extends StatelessWidget {
  const _SearchMessage({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PhosphorIcon(icon, size: 44, color: Colors.black54),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 14, height: 1.4, color: Colors.black54),
            ),
            if (action case final action?) ...[const SizedBox(height: 10), action],
          ],
        ),
      ),
    );
  }
}

class _WeatherUnavailable extends StatelessWidget {
  const _WeatherUnavailable({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(message, style: GoogleFonts.inter(fontSize: 16)),
        const SizedBox(height: 12),
        TextButton(onPressed: onRetry, child: const Text('Try again')),
      ],
    );
  }
}

String _staleStatus(WeatherLoadStatus status, String requestedCity) {
  return switch (status) {
    WeatherLoadStatus.loading => 'Updating weather…',
    WeatherLoadStatus.notFound => 'Couldn’t update $requestedCity. Showing the last report.',
    WeatherLoadStatus.serviceUnavailable => 'Couldn’t update $requestedCity. Showing the last report.',
    WeatherLoadStatus.emptyInput => 'Showing the last weather report.',
    _ => '',
  };
}

IconData _conditionIcon(Weather weather) {
  return switch (weather.condition) {
    WeatherCondition.clear => weather.isDay ? PhosphorIconsLight.sun : PhosphorIconsLight.moon,
    WeatherCondition.partlyCloudy => weather.isDay ? PhosphorIconsLight.cloudSun : PhosphorIconsLight.cloudMoon,
    WeatherCondition.overcast => PhosphorIconsLight.cloud,
    WeatherCondition.fog => PhosphorIconsLight.cloudFog,
    WeatherCondition.drizzle || WeatherCondition.rain || WeatherCondition.rainShowers => PhosphorIconsLight.cloudRain,
    WeatherCondition.snow || WeatherCondition.snowShowers => PhosphorIconsLight.cloudSnow,
    WeatherCondition.thunderstorm => PhosphorIconsLight.cloudLightning,
    WeatherCondition.unknown => PhosphorIconsLight.cloudWarning,
  };
}

class WeatherBackground extends StatefulWidget {
  const WeatherBackground({
    super.key,
    required this.child,
    this.weather,
    this.paintKey = const Key('weather-background-grain'),
  });
  final Widget child;
  final Weather? weather;
  final Key paintKey;

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
        key: widget.paintKey,
        painter: _NoisePainter(
          program: _program,
          devicePixelRatio: pixelRatio,
          palette: _paletteFor(widget.weather),
        ),
        child: widget.child,
      ),
    );
  }
}

typedef _WeatherPalette = ({Color edge, Color accent});
typedef _AdaptivePalette = ({_WeatherPalette day, _WeatherPalette night});

const _neutralPalette = (edge: Colors.white, accent: Colors.blueAccent);

_WeatherPalette _paletteFor(Weather? weather) {
  if (weather == null) return _neutralPalette;

  final _AdaptivePalette palettes = switch (weather.condition) {
    WeatherCondition.clear => const (
      day: (edge: Color(0xFFFFF8E8), accent: Color(0xFF67B8F7)),
      night: (edge: Color(0xFFE8EBFF), accent: Color(0xFF8796E8)),
    ),
    WeatherCondition.partlyCloudy || WeatherCondition.overcast || WeatherCondition.fog => const (
      day: (edge: Color(0xFFF7F9FC), accent: Color(0xFFA9BCD0)),
      night: (edge: Color(0xFFE8ECF4), accent: Color(0xFF8EA1BD)),
    ),
    WeatherCondition.drizzle || WeatherCondition.rain || WeatherCondition.rainShowers => const (
      day: (edge: Color(0xFFEDF8FA), accent: Color(0xFF62B2C3)),
      night: (edge: Color(0xFFE3EFF4), accent: Color(0xFF5795AC)),
    ),
    WeatherCondition.snow || WeatherCondition.snowShowers => const (
      day: (edge: Color(0xFFFFFFFF), accent: Color(0xFFB9DDF1)),
      night: (edge: Color(0xFFEBF2F8), accent: Color(0xFFA3C4DC)),
    ),
    WeatherCondition.thunderstorm => const (
      day: (edge: Color(0xFFF3EEFA), accent: Color(0xFF9D89CC)),
      night: (edge: Color(0xFFEAE5F3), accent: Color(0xFF8978B5)),
    ),
    WeatherCondition.unknown => const (
      day: (edge: Color(0xFFF5F7F8), accent: Color(0xFF9FB4C2)),
      night: (edge: Color(0xFFE9ECEF), accent: Color(0xFF899BA7)),
    ),
  };
  return weather.isDay ? palettes.day : palettes.night;
}

class _NoisePainter extends CustomPainter {
  const _NoisePainter({
    required this.program,
    required this.devicePixelRatio,
    required this.palette,
  });

  final ui.FragmentProgram? program;
  final double devicePixelRatio;
  final _WeatherPalette palette;

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
            palette.edge,
            Color.lerp(palette.edge, palette.accent, 0.156)!,
            Color.lerp(palette.edge, palette.accent, 0.5)!,
            Color.lerp(palette.edge, palette.accent, 0.844)!,
            palette.accent,
            Color.lerp(palette.accent, palette.edge, 0.156)!,
            Color.lerp(palette.accent, palette.edge, 0.5)!,
            Color.lerp(palette.accent, palette.edge, 0.844)!,
            palette.edge,
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
      oldDelegate.program != program ||
      oldDelegate.devicePixelRatio != devicePixelRatio ||
      oldDelegate.palette != palette;
}
