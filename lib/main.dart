import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(WeatherApp());
}

class WeatherApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'App clima do tempo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.lightBlue[50],
      ),
      home: WeatherHomePage(),
    );
  }
}

class WeatherHomePage extends StatefulWidget {
  @override
  _WeatherHomePageState createState() => _WeatherHomePageState();
}

class _WeatherHomePageState extends State<WeatherHomePage> {
  final TextEditingController _controller = TextEditingController();
  String _temperature = '';
  String _description = '';
  bool _isLoading = false;

  List<String> _forecastTemperatures = [];
  List<String> _forecastDescriptions = [];

  // Mapa para tradução de descrições do clima
  final Map<String, String> weatherTranslations = {
    "clear sky": "céu limpo",
    "few clouds": "poucas nuvens",
    "scattered clouds": "nuvens dispersas",
    "broken clouds": "nuvens fragmentadas",
    "shower rain": "chuva leve",
    "rain": "chuva",
    "thunderstorm": "tempestade",
    "snow": "neve",
    "mist": "névoa",
    "light rain": "chuva leve",
    "overcast clouds": "nuvens encobertas",
  };

  Future<void> fetchWeather(String city) async {
    if (city.isEmpty) {
      setState(() {
        _temperature = 'Erro';
        _description = 'Digite uma cidade válida';
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final apiKey = '4358a1a15f6498b9278b3434fecd0d7e';
    final url =
        'https://api.openweathermap.org/data/2.5/weather?q=$city&appid=$apiKey&units=metric';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Obtenha a descrição e traduza
        String description = data['weather'][0]['description'];
        String translatedDescription =
            weatherTranslations[description] ?? description;

        // Agora vamos pegar a previsão para os próximos dias (Latitude e Longitude)
        final lat = data['coord']['lat'];
        final lon = data['coord']['lon'];
        final forecastUrl =
            'https://api.openweathermap.org/data/2.5/onecall?lat=$lat&lon=$lon&appid=$apiKey&units=metric';

        final forecastResponse = await http.get(Uri.parse(forecastUrl));

        if (forecastResponse.statusCode == 200) {
          final forecastData = jsonDecode(forecastResponse.body);

          // Acessando a previsão dos próximos 7 dias
          List<String> temperatures = [];
          List<String> descriptions = [];

          for (int i = 0; i < 7; i++) {
            // Extração de temperatura e descrição com verificação
            double temp = forecastData['daily'][i]['temp']['day'] ?? 0.0;
            String forecastDescription =
                forecastData['daily'][i]['weather'][0]['description'] ?? '';

            temperatures.add('${temp.toString()}°C');
            descriptions.add(weatherTranslations[forecastDescription] ??
                forecastDescription);
          }

          setState(() {
            _forecastTemperatures = temperatures;
            _forecastDescriptions = descriptions;
            _isLoading = false;
          });
        } else {
          setState(() {
            _temperature = 'Erro';
            _description = 'Erro ao obter previsão dos próximos dias';
            _isLoading = false;
          });
        }

        setState(() {
          _temperature = '${data['main']['temp']}°C';
          _description = translatedDescription;
        });
      } else {
        setState(() {
          _temperature = 'Erro';
          _description = 'Cidade não encontrada';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _temperature = 'Erro';
        _description = 'Falha na conexão';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Clima Atual'),
        backgroundColor: Colors.green[700],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Consulta de clima',
                style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[900]),
              ),
              SizedBox(
                height: 20,
              ),
              TextField(
                controller: _controller,
                decoration: InputDecoration(
                  labelText: 'Digite o nome da cidade',
                  labelStyle: TextStyle(color: Colors.green[700]),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.green, width: 2),
                      borderRadius: BorderRadius.circular(10.0)),
                  prefixIcon:
                  Icon(Icons.location_city, color: Colors.green[700]),
                ),
              ),
              SizedBox(
                height: 20,
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[700],
                  padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                ),
                onPressed: () {
                  fetchWeather(_controller.text);
                },
                child: Text(
                  'Consultar clima',
                  style: TextStyle(fontSize: 18),
                ),
              ),
              SizedBox(
                height: 30,
              ),
              if (_isLoading)
                CircularProgressIndicator()
              else if (_temperature.isNotEmpty && _description.isNotEmpty) ...[
                Icon(
                  Icons.wb_sunny_outlined,
                  size: 80,
                  color: Colors.orange,
                ),
                SizedBox(
                  height: 10,
                ),
                Text(
                  _temperature,
                  style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
                ),
                SizedBox(
                  height: 10,
                ),
                Text(
                  _description,
                  style: TextStyle(
                      fontSize: 24,
                      color: Colors.green[900],
                      fontStyle: FontStyle.italic),
                ),
                SizedBox(
                  height: 30,
                ),
                Text(
                  'Previsão para os próximos dias:',
                  style: TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold),
                ),
                SizedBox(
                  height: 20,
                ),
                for (int i = 0; i < _forecastTemperatures.length; i++) ...[
                  Text(
                    'Dia ${i + 1}: ${_forecastTemperatures[i]} - ${_forecastDescriptions[i]}',
                    style: TextStyle(fontSize: 18, color: Colors.blue[900]),
                  ),
                  SizedBox(
                    height: 10,
                  ),
                ]
              ],
              if (_temperature == 'Erro') ...[
                Icon(
                  Icons.error_outline,
                  size: 80,
                  color: Colors.red,
                ),
                SizedBox(
                  height: 10,
                ),
                Text(
                  _description,
                  style: TextStyle(fontSize: 24, color: Colors.red),
                )
              ]
            ],
          ),
        ),
      ),
    );
  }
}
