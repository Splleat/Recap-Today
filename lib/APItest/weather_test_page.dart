import 'package:flutter/material.dart';
import '../api/weather_service.dart';
import '../model/full_weather_model.dart';

class WeatherTestPage extends StatefulWidget {
  const WeatherTestPage({super.key});

  @override
  State<WeatherTestPage> createState() => _WeatherTestPageState();
}

class _WeatherTestPageState extends State<WeatherTestPage> {
  final WeatherService _weatherService = WeatherService();
  List<FullWeather> _weatherList = [];
  String? _error;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWeather();
  }

  Future<void> _loadWeather() async {
    try {
      final data = await _weatherService.fetchFullWeather();
      setState(() {
        _weatherList = data;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('날씨 테스트'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('오류 발생: $_error'))
              : ListView.builder(
                  itemCount: _weatherList.length,
                  itemBuilder: (context, index) {
                    final day = _weatherList[index];
                    return ExpansionTile(
                      title: Text('${day.date} (${day.weather.length}시간치)'),
                      children: day.weather.map((w) {
                        return ListTile(
                          title: Text('${w.time}'),
                          subtitle: Text(
                            '${w.temperature} | ${w.sky} | 강수확률: ${w.precipitationProbability}',
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
    );
  }
}
