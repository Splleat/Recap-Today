class WeatherData {
  final String time;
  final String temperature;
  final String sky;
  final String precipitationProbability;

  WeatherData({
    required this.time,
    required this.temperature,
    required this.sky,
    required this.precipitationProbability,
  });

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    return WeatherData(
      time: json['time'],
      temperature: json['temperature'],
      sky: json['sky'],
      precipitationProbability: json['precipitationProbability'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'time': time,
      'temperature': temperature,
      'sky': sky,
      'precipitationProbability': precipitationProbability,
    };
  }
}

class FullWeather {
  final String date;
  final List<WeatherData> weather;

  FullWeather({required this.date, required this.weather});

  factory FullWeather.fromJson(Map<String, dynamic> json) {
    var weatherList = (json['weather'] as List)
        .map((item) => WeatherData.fromJson(item))
        .toList();

    return FullWeather(
      date: json['date'],
      weather: weatherList,
    );
  }
}
