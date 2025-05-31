import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';

void main() => runApp(PantaniZzApp());

class PantaniZzApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PantaniZz Monitor',
      theme: ThemeData(primarySwatch: Colors.teal),
      home: SensorDashboard(),
    );
  }
}

class SensorDashboard extends StatefulWidget {
  @override
  _SensorDashboardState createState() => _SensorDashboardState();
}

class _SensorDashboardState extends State<SensorDashboard>
    with SingleTickerProviderStateMixin {  String temperature = "--";
  String humidity = "--";
  String tds = "--";
  String light = "--";
  String ph = "--";
  String waterTemp = "--";
  bool relayAirBersih = false;
  bool relayNutrisi = false;
  bool relayLampu = false;
  String lastUpdated = "";
  bool loading = true;

  late TabController _tabController;
  Timer? _timer;

  final List<FlSpot> tempSpots = [];
  final List<FlSpot> tdsSpots = [];
  int timeIndex = 0;
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this); // Changed from 2 to 3 tabs
    fetchData();
    _timer = Timer.periodic(Duration(seconds: 10), (_) => fetchData()); // More frequent updates
  }

  @override
  void dispose() {
    _timer?.cancel();
    _tabController.dispose();
    super.dispose();
  }
  Future<void> fetchData() async {
    if (!mounted) return;
    
    setState(() => loading = true);
    try {
      // Using 10.0.2.2 for Android emulator to access host's localhost
      // For real devices, you'll need to use actual IP address of your Go backend
      final url = 'http://localhost:8080/getSensorData';
      final response = await http.get(Uri.parse(url))
          .timeout(Duration(seconds: 5)); // Add timeout
          
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {          temperature = (data['temperature'] ?? "--").toString();
          humidity = (data['humidity'] ?? "--").toString();
          tds = (data['tds'] ?? "--").toString();
          light = (data['light'] ?? "--").toString();
          ph = (data['ph'] ?? "--").toString(); // Changed from 'pH' to 'ph' to match ESP32 format
          waterTemp = (data['water_temp'] ?? "--").toString();
          relayAirBersih = data['relay_air_bersih'] ?? false;
          relayNutrisi = data['relay_nutrisi'] ?? false;
          relayLampu = data['relay_lampu'] ?? false;
          lastUpdated = data['timestamp'] ?? DateTime.now().toString();
          loading = false;

          double tempVal = double.tryParse(temperature) ?? 0;
          double tdsVal = double.tryParse(tds) ?? 0;
          if (tempSpots.length > 20) tempSpots.removeAt(0);
          if (tdsSpots.length > 20) tdsSpots.removeAt(0);
          tempSpots.add(FlSpot(timeIndex.toDouble(), tempVal));
          tdsSpots.add(FlSpot(timeIndex.toDouble(), tdsVal));
          timeIndex++;
        });
      } else {
        setState(() => loading = false);
      }    } catch (e) {
      if (mounted) {
        setState(() => loading = false);
        
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error fetching data: $e"),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
      print("Error fetching data: $e");
    }
  }

  Map<String, dynamic> getTdsStatus(double tdsValue) {
    if (tdsValue < 800) {
      return {
        "text": "TDS rendah - Nutrisi perlu ditambah",
        "color": Colors.orange,
        "icon": Icons.warning,
      };
    } else if (tdsValue <= 1200) {
      return {
        "text": "Kondisi nutrisi baik",
        "color": Colors.green,
        "icon": Icons.check_circle,
      };
    } else {
      return {
        "text": "TDS tinggi - Larutan terlalu pekat, perlu diencerkan",
        "color": Colors.red,
        "icon": Icons.error,
      };
    }
  }

  Widget buildCard(String title, String value, IconData icon, Color color) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      elevation: 4,
      child: ListTile(
        leading: Icon(icon, size: 40, color: color),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
        trailing: Text(value, style: TextStyle(fontSize: 20)),
      ),
    );
  }

  Widget buildLineChart(
      String title, List<FlSpot> spots, Color color, String unit, double maxY) {
    return Card(
      margin: EdgeInsets.all(16),
      elevation: 6,
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          children: [
            Text(title,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(
                height: 200,
                child: LineChart(LineChartData(
                  minX: 0,
                  maxX: spots.isEmpty ? 20 : spots.last.x,
                  minY: 0,
                  maxY: maxY,
                  gridData: FlGridData(show: true),
                  borderData: FlBorderData(show: true),
                  titlesData: FlTitlesData(
                    bottomTitles:
                        AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    leftTitles:
                        AxisTitles(sideTitles: SideTitles(showTitles: true)),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: color,
                      barWidth: 3,
                      dotData: FlDotData(show: false),
                    )
                  ],
                ))),
            SizedBox(height: 4),
            Text(unit, style: TextStyle(color: color)),
          ],
        ),
      ),
    );
  }

  Widget buildRelayStatusCard(String title, bool isOn) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      elevation: 4,
      child: ListTile(
        leading: Icon(
          isOn ? Icons.power : Icons.power_off,
          size: 40,
          color: isOn ? Colors.green : Colors.red,
        ),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
        trailing: Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isOn ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            isOn ? "ON" : "OFF",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isOn ? Colors.green : Colors.red,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double tdsValue = double.tryParse(tds) ?? -1;
    final tdsStatus = getTdsStatus(tdsValue);    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Image.asset(
          'assets/logo.png',
          height: 40,
          fit: BoxFit.contain,
        ),bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(icon: Icon(Icons.show_chart), text: "Grafik"),
            Tab(icon: Icon(Icons.sensors), text: "Sensor Data"),
            Tab(icon: Icon(Icons.power_settings_new), text: "Status Kontrol"),
          ],
        ),
      ),      body: loading
          ? Center(child: CircularProgressIndicator(color: Colors.teal))
          : Column(
              children: [
                Container(
                  color: tdsStatus["color"].withOpacity(0.15),
                  padding: EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                  child: Row(
                    children: [
                      Icon(tdsStatus["icon"], color: tdsStatus["color"], size: 40),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          tdsStatus["text"],
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                              color: tdsStatus["color"]),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.refresh, color: tdsStatus["color"]),
                        onPressed: fetchData,
                        tooltip: "Refresh Data",
                      )
                    ],
                  ),
                ),                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      ListView(
                        children: [
                          buildLineChart(
                              "Temperature (°C)", tempSpots, Colors.red, "°C", 50),
                          buildLineChart("TDS (ppm)", tdsSpots, Colors.green, "ppm",
                              2000),
                        ],
                      ),
                      ListView(
                        children: [
                          buildCard(
                              "Temperature (°C)", temperature, Icons.thermostat, Colors.red),
                          buildCard(
                              "Water Temp (°C)", waterTemp, Icons.pool, Colors.cyan),
                          buildCard(
                              "Humidity (%)", humidity, Icons.water_drop, Colors.blue),
                          buildCard("TDS (ppm)", tds, Icons.opacity, Colors.green),
                          buildCard("Light (LDR)", light, Icons.wb_sunny, Colors.amber),
                          buildCard("pH Level", ph, Icons.science, Colors.purple),
                        ],
                      ),
                      ListView(
                        children: [
                          buildRelayStatusCard("Air Bersih Pump", relayAirBersih),
                          buildRelayStatusCard("Nutrisi Pump", relayNutrisi),
                          buildRelayStatusCard("Lampu Grow Light", relayLampu),
                          Card(
                            margin: EdgeInsets.symmetric(vertical: 6, horizontal: 16),
                            elevation: 4,
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("Last Updated", 
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  SizedBox(height: 8),
                                  Text(lastUpdated),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                )
              ],
            ),
    );
  }
}
