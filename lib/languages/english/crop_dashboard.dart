import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hacksprint_mandya/languages/english/chatbot.dart';
import 'package:hacksprint_mandya/pages/fertilizer.dart';
import 'package:hacksprint_mandya/utils/model.dart';
import 'package:hacksprint_mandya/pages/byproduct.dart';
import 'package:hacksprint_mandya/pages/governmentschemes.dart';
import 'package:hacksprint_mandya/pages/insurance.dart';
import 'package:hacksprint_mandya/pages/marketrate.dart';
import 'package:hacksprint_mandya/pages/shapeshift.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with AutomaticKeepAliveClientMixin {
  String? _location;
  double? _temperature;
  int? _humidity;
  String? _condition;
  bool _isLoading = false;
  String? _error;

  final String _openWeatherApiKey = 'e227b5cc1d93809394d60d8db9aba89e';

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _fetchLocationAndWeather();
  }

  Future<void> _fetchLocationAndWeather() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      Position position = await _determinePosition();
      String cityName = await _reverseGeocode(
        position.latitude,
        position.longitude,
      );
      final weatherData = await _fetchWeatherData(
        position.latitude,
        position.longitude,
      );

      setState(() {
        _location = cityName;
        _temperature = weatherData['temp'];
        _humidity = weatherData['humidity'];
        _condition = weatherData['condition'];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load weather: ${e.toString()}')),
      );
    }
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) throw 'Please enable location services';

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied)
        throw 'Location permissions are denied';
    }
    if (permission == LocationPermission.deniedForever) {
      throw 'Location permissions are permanently denied. Please enable them in app settings.';
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.low,
    );
  }

  Future<String> _reverseGeocode(double latitude, double longitude) async {
    try {
      final url =
          'https://nominatim.openstreetmap.org/reverse?format=json&lat=$latitude&lon=$longitude'; // Fixed space
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        final address = decoded['address'];
        return address['city'] ??
            address['town'] ??
            address['village'] ??
            address['county'] ??
            'Unknown location';
      } else {
        throw 'Reverse geocode failed with status: ${response.statusCode}';
      }
    } catch (e) {
      debugPrint('Reverse geocode error: $e');
      return 'Unknown location';
    }
  }

  Future<Map<String, dynamic>> _fetchWeatherData(
    double latitude,
    double longitude,
  ) async {
    try {
      // Fixed space in URL
      final url =
          'https://api.openweathermap.org/data/2.5/weather?lat=$latitude&lon=$longitude&appid=$_openWeatherApiKey&units=metric';
      debugPrint('Fetching weather from: $url');

      // Validate coordinates first
      if (latitude < -90 ||
          latitude > 90 ||
          longitude < -180 ||
          longitude > 180) {
        throw 'Invalid coordinates: lat=$latitude, lon=$longitude';
      }

      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        return {
          'temp': decoded['main']['temp'],
          'humidity': decoded['main']['humidity'],
          'condition': decoded['weather'][0]['main'],
        };
      } else {
        throw 'Failed to fetch weather: ${response.statusCode} - ${response.body}';
      }
    } catch (e) {
      debugPrint('Weather API error: $e');
      throw 'Failed to fetch weather data: $e';
    }
  }

  IconData _getWeatherIcon(String? condition) {
    if (condition == null) return Icons.cloud_queue;
    switch (condition.toLowerCase()) {
      case 'clear':
        return Icons.wb_sunny;
      case 'clouds':
        return Icons.cloud;
      case 'rain':
        return Icons.water_drop;
      case 'snow':
        return Icons.ac_unit;
      default:
        return Icons.cloud_queue;
    }
  }

  Widget _buildGridItem(BuildContext context, String title, Widget screen) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => screen),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: null,
        backgroundColor: Colors.green.shade100,
        elevation: 0,
        actions: [
          IconButton(
            icon: FaIcon(FontAwesomeIcons.robot), // Chatbot icon
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ChatScreen()),
              );
            },
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Weather Info Section
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: screenWidth > 400 ? 16 : 8,
                        vertical: 12,
                      ),
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child:
                          _isLoading
                              ? const Center(child: CircularProgressIndicator())
                              : _buildWeatherRow(screenWidth),
                    ),

                    // Plant Analysis Flow
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: screenWidth > 400 ? 16 : 8,
                        vertical: 16,
                      ),
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: _buildPlantAnalysisRow(screenWidth),
                    ),

                    // Scan Button
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade800,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ClassifierScreen(),
                          ),
                        );
                      },
                      child: const Text(
                        "SCAN",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Explore More Section
                    Text(
                      "Explore More",
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade900,
                      ),
                      textAlign: TextAlign.left,
                    ),
                    const SizedBox(height: 12),

                    Expanded(
                      child: SizedBox(
                        height: 200,
                        child: GridView.count(
                          crossAxisCount: 2,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 2.5,
                          children: [
                            _buildGridItem(
                              context,
                              "Crop Insurance",
                              const InsurancePage(),
                            ),
                            _buildGridItem(
                              context,
                              "Fertilizers",
                              const FertilizerApp(),
                            ),
                            _buildGridItem(
                              context,
                              "Shape Shifting",
                              const ShapeShiftPAge(),
                            ),
                            _buildGridItem(
                              context,
                              "By-Product Farming",
                              const ByProductScreen(),
                            ),
                            _buildGridItem(
                              context,
                              "Market Rates",
                              CropHistoryScreen(),
                            ),
                            _buildGridItem(
                              context,
                              "Government Schemes",
                              CropSchemesDropdownPage(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildWeatherRow(double screenWidth) {
    final isWideScreen = screenWidth > 400;

    return Flex(
      direction: isWideScreen ? Axis.horizontal : Axis.vertical,
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildWeatherItem(
          icon: Icons.location_on,
          color: Colors.green.shade800,
          value: _location ?? '--',
          isWideScreen: isWideScreen,
        ),
        if (isWideScreen)
          const SizedBox(width: 8)
        else
          const SizedBox(height: 8),
        _buildWeatherItem(
          icon: Icons.thermostat,
          color: Colors.red.shade800,
          value:
              _temperature != null
                  ? "${_temperature!.toStringAsFixed(1)}°C"
                  : "--",
          isWideScreen: isWideScreen,
        ),
        if (isWideScreen)
          const SizedBox(width: 8)
        else
          const SizedBox(height: 8),
        _buildWeatherItem(
          icon: Icons.water_drop,
          color: Colors.blue.shade800,
          value: _humidity != null ? "$_humidity%" : "--%",
          isWideScreen: isWideScreen,
        ),
        if (isWideScreen)
          const SizedBox(width: 8)
        else
          const SizedBox(height: 8),
        Icon(
          _getWeatherIcon(_condition),
          color: Colors.orange.shade800,
          size: 20,
        ),
        if (isWideScreen)
          const SizedBox(width: 8)
        else
          const SizedBox(height: 8),
        IconButton(
          icon: Icon(Icons.refresh, color: Colors.blue.shade600, size: 20),
          onPressed: _fetchLocationAndWeather,
        ),
      ],
    );
  }

  Widget _buildWeatherItem({
    required IconData icon,
    required Color color,
    required String value,
    required bool isWideScreen,
  }) {
    return Row(
      mainAxisAlignment:
          isWideScreen ? MainAxisAlignment.start : MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 14),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
      ],
    );
  }

  Widget _buildPlantAnalysisRow(double screenWidth) {
    final isWideScreen = screenWidth > 500;

    return Flex(
      direction: isWideScreen ? Axis.horizontal : Axis.vertical,
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        FaIcon(
          FontAwesomeIcons.seedling,
          color: Colors.green.shade800,
          size: 30,
        ),
        if (isWideScreen)
          const SizedBox(width: 8)
        else
          const SizedBox(height: 8),
        const Icon(Icons.arrow_downward, color: Colors.grey),
        if (isWideScreen)
          const SizedBox(width: 8)
        else
          const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            "AI Analysis",
            style: TextStyle(
              color: Colors.blue.shade800,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        if (isWideScreen)
          const SizedBox(width: 8)
        else
          const SizedBox(height: 8),
        const Icon(Icons.arrow_downward, color: Colors.grey),
        if (isWideScreen)
          const SizedBox(width: 8)
        else
          const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            "Disease Prediction",
            style: TextStyle(
              color: Colors.orange.shade900,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
