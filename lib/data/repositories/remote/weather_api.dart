import 'package:smart_vision_application/core/constants/app_constants.dart';
import 'package:smart_vision_application/core/utils/api_helper.dart';
import 'package:smart_vision_application/data/models/weather.dart';

class WeatherApi {
    static Future<Weather> getWeather(String city) async {
        final url = "https://api.weatherapi.com/v1/forecast.json?key=$weatherApiKey&q=$city&days=1";
        final data = await ApiHelper.getData('', url: url);

        return Weather.fromApi(data);
    }
}