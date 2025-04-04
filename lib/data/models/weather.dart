

import 'package:smart_vision_application/data/models/forecast.dart';

class Weather {
    final Forecast forecast;
    Weather({
        required this.forecast
    });

    factory Weather.fromApi(Map<String, String> json) {
        return Weather(
            forecast: Forecast.fromApi(json)
        );
    }
}