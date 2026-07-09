# Atelier Weather

A minimal feature-oriented Flutter app demonstrating Atelier with real weather
data.

The app uses:

- Open-Meteo Geocoding API to resolve a city;
- Open-Meteo Forecast API for current temperature and weather conditions;
- abortable HTTP requests connected to Atelier cancellation tokens;
- `WeatherViewModel`, immutable state, effects, `watch`, and `listen`.

No API key is required.

## Run

```sh
flutter pub get
flutter run
```

Weather data is provided by [Open-Meteo](https://open-meteo.com/).
