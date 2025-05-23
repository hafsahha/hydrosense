import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';

void main() => runApp(HydroponicApp());

class HydroponicApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hydroponic Monitor',
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
    with SingleTickerProviderStateMixin {
  String temperature = "--";
  String humidity = "--";
  String tds = "--";
  String light = "--";
  String ph = "--";
  bool loading = true;

  late TabController _tabController;
  Timer? _timer;

  final List<FlSpot> tempSpots = [];
  final List<FlSpot> tdsSpots = [];
  int timeIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    fetchData();
    _timer = Timer.periodic(Duration(minutes: 1), (_) => fetchData());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> fetchData() async {
    setState(() => loading = true);
    try {
      final response =
          await http.get(Uri.parse('http://localhost:8080/getSensorData'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          temperature = (data['temperature'] ?? "--").toString();
          humidity = (data['humidity'] ?? "--").toString();
          tds = (data['tds'] ?? "--").toString();
          light = (data['light'] ?? "--").toString();
          ph = (data['pH'] ?? "--").toString();
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
      }
    } catch (e) {
      setState(() => loading = false);
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

  @override
  Widget build(BuildContext context) {
    double tdsValue = double.tryParse(tds) ?? -1;
    final tdsStatus = getTdsStatus(tdsValue);

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: SizedBox(
          width: 250,
          height: 250,
          child: Image.asset('assets/logo.png'),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(icon: Icon(Icons.show_chart), text: "Grafik"),
            Tab(icon: Icon(Icons.info), text: "Data & Status"),
          ],
        ),
      ),
      body: loading
          ? Center(child: CircularProgressIndicator())
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
                ),
                Expanded(
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
                              "Humidity (%)", humidity, Icons.water_drop, Colors.blue),
                          buildCard("TDS (ppm)", tds, Icons.opacity, Colors.green),
                          buildCard("Light (LDR)", light, Icons.wb_sunny, Colors.amber),
                          buildCard("pH Level", ph, Icons.science, Colors.purple),
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
