import 'package:atelier_weather_example/src/features/weather/presentation/weather_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class WeatherSearch extends StatelessWidget {
  const WeatherSearch({
    required this.controller,
    required this.focusNode,
    required this.state,
    required this.onChanged,
    required this.onSubmitted,
    required this.onSelected,
    required this.onClear,
    super.key,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final WeatherState state;
  final Future<Iterable<String>> Function(String) onChanged;
  final ValueChanged<String> onSubmitted;
  final ValueChanged<String> onSelected;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.escape): DismissIntent(),
      },
      child: RawAutocomplete<String>(
        textEditingController: controller,
        focusNode: focusNode,
        displayStringForOption: (option) => option,
        optionsBuilder: (value) => onChanged(value.text),
        onSelected: onSelected,
        fieldViewBuilder: (context, textController, node, submit) => Semantics(
          label: 'Search for a city',
          child: SizedBox(
            height: 60,
            child: TextField(
              key: const Key('city-search-field'),
              controller: textController,
              focusNode: node,
              textInputAction: TextInputAction.search,
              onChanged: (_) {},
              onSubmitted: onSubmitted,
              decoration: InputDecoration(
                hintText: 'Search for a city',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: state.searchStatus == WeatherSearchStatus.loading
                    ? Semantics(
                        label: 'Searching for places',
                        child: const Center(
                          widthFactor: 1,
                          heightFactor: 1,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            constraints: BoxConstraints.tightFor(
                              width: 24,
                              height: 24,
                            ),
                          ),
                        ),
                      )
                    : controller.text.isNotEmpty
                    ? IconButton(
                        key: const Key('clear-search'),
                        tooltip: 'Clear search',
                        onPressed: onClear,
                        icon: const Icon(Icons.close),
                      )
                    : const SizedBox(width: 48),
              ),
            ),
          ),
        ),
        optionsViewBuilder: (context, select, options) => Align(
          alignment: Alignment.topLeft,
          child: Material(
            key: const Key('suggestions-menu'),
            elevation: 16,
            color: const Color(0xff202c40),
            borderRadius: BorderRadius.circular(18),
            clipBehavior: Clip.antiAlias,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 280, maxWidth: 420),
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final option = options.elementAt(index);
                  return ListTile(
                    minTileHeight: 48,
                    leading: const Icon(Icons.location_on_outlined),
                    title: Text(option),
                    onTap: () => select(option),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
