import 'dart:convert';
import 'package:bee_care/Hive_deatilsPagr.dart';
import 'package:bee_care/notifications.dart';
import 'package:bee_care/profile.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class HomePage extends StatefulWidget {
  final String username;

  const HomePage({Key? key, required this.username}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 2; // Home selected by default
  
  // Hive data
  List<dynamic> hives = [];
  dynamic selectedHive;
  bool loading = true;
  
  // Chart data
  List<Map<String, dynamic>> weeklyReadings = [];

  @override
  void initState() {
    super.initState();
    fetchHives();
  }

  // Fetch all hives
  Future<void> fetchHives() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString("access_token");

      final url = Uri.parse("http://192.168.15.125:8000/api/hives/");
      final response = await http.get(url, headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List<dynamic> fetchedHives = [];
        
        if (data is List) {
          fetchedHives = data;
        } else if (data is Map && data.containsKey("results")) {
          fetchedHives = data["results"];
        }

        setState(() {
          hives = fetchedHives;
          // Select first hive by default
          if (hives.isNotEmpty) {
            selectedHive = hives[0];
            fetchWeeklyData(selectedHive["id"]);
          }
          loading = false;
        });
      } else {
        setState(() => loading = false);
        print("Failed to load hives: ${response.statusCode}");
      }
    } catch (e) {
      setState(() => loading = false);
      print("Error fetching hives: $e");
    }
  }

  // Fetch weekly readings for chart
  Future<void> fetchWeeklyData(int hiveId) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString("access_token");

      final url = Uri.parse(
          "http://192.168.15.125:8000/api/hives/$hiveId/readings/?days=7");
      final response = await http.get(url, headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List<dynamic> readings = [];
        
        if (data is List) {
          readings = data;
        } else if (data is Map && data.containsKey("results")) {
          readings = data["results"];
        }

        // Process readings for chart (group by day and get average weight)
        Map<String, List<double>> dailyWeights = {};
        
        for (var reading in readings) {
          if (reading["timestamp"] != null && reading["weight"] != null) {
            String date = reading["timestamp"].toString().substring(0, 10);
            if (!dailyWeights.containsKey(date)) {
              dailyWeights[date] = [];
            }
            dailyWeights[date]!.add((reading["weight"] as num).toDouble());
          }
        }

        // Calculate average for each day
        List<Map<String, dynamic>> processed = [];
        dailyWeights.forEach((date, weights) {
          double avg = weights.reduce((a, b) => a + b) / weights.length;
          processed.add({"date": date, "weight": avg});
        });

        // Sort by date
        processed.sort((a, b) => a["date"].compareTo(b["date"]));

        setState(() {
          weeklyReadings = processed;
        });
      }
    } catch (e) {
      print("Error fetching weekly data: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      AaccountPage(),
      NotificationsPage(),
      _mainHomeUI(),
      HiveDashboardPage(),
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      body: pages[_selectedIndex],
      bottomNavigationBar: _bottomNavBar(),
    );
  }

  Widget _bottomNavBar() {
    return BottomNavigationBar(
      currentIndex: _selectedIndex,
      onTap: (index) {
        setState(() {
          _selectedIndex = index;
        });
      },
      selectedItemColor: Colors.orange,
      unselectedItemColor: Colors.grey,
      backgroundColor: Colors.white,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: "الحساب",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.notifications),
          label: "تنبيهات",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: "رئيسية",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.grid_view),
          label: "الخلايا",
        ),
      ],
    );
  }

  Widget _mainHomeUI() {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: SafeArea(
        child: loading
            ? const Center(child: CircularProgressIndicator(color: Colors.orange))
            : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _header(widget.username),
                    const SizedBox(height: 20),
                    _cellSelector(),
                    const SizedBox(height: 10),
                    _title("إحصائيات"),
                    const SizedBox(height: 10),
                    _statsGrid(),
                    const SizedBox(height: 20),
                    _weightSection(),
                    const SizedBox(height: 50),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _header(String username) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: const BoxDecoration(
        color: Colors.orange,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(35),
          bottomRight: Radius.circular(35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                "مرحباً ب $username 👋",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _cellSelector() {
    if (hives.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(25),
          color: Colors.white,
        ),
        child: const Text("لا توجد خلايا"),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(25),
        color: Colors.white,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<dynamic>(
          value: selectedHive,
          isExpanded: true,
          icon: const Icon(Icons.arrow_drop_down),
          style: const TextStyle(fontSize: 15, color: Colors.black),
          onChanged: (dynamic newValue) {
            setState(() {
              selectedHive = newValue;
              if (selectedHive != null) {
                fetchWeeklyData(selectedHive["id"]);
              }
            });
          },
          items: hives.map<DropdownMenuItem<dynamic>>((hive) {
            String hiveName = hive["name"]?.toString() ?? 
                             "خلية ${hive["id"]}";
            return DropdownMenuItem<dynamic>(
              value: hive,
              child: Text(hiveName),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _title(String text) {
    return Text(
      text,
      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
    );
  }

  Widget _statsGrid() {
    if (selectedHive == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Text("اختر خلية لعرض الإحصائيات"),
        ),
      );
    }

    final latest = selectedHive["latest_reading"];
    
    String vibration = "--";
    String temperature = "--";
    String humidity = "--";
    String co2 = "--";

    if (latest != null && latest is Map) {
      vibration = latest["vibration"]?.toString() ?? "--";
      temperature = latest["temperature"] != null 
          ? "${latest["temperature"]}°" 
          : "--";
      humidity = latest["humidity"]?.toString() ?? "--";
      co2 = latest["co2"]?.toString() ?? "--";
    }

    return GridView.count(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      crossAxisCount: 2,
      childAspectRatio: 1.1,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      children: [
        _statCard("الإهتزاز", vibration, Icons.monitor_heart),
        _statCard("درجة الحرارة", temperature, Icons.thermostat),
        _statCard("الرطوبة", humidity, Icons.water_drop),
        _statCard("CO₂", co2, Icons.cloud),
      ],
    );
  }

  Widget _statCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 8,
            offset: const Offset(2, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(child: Text(title, overflow: TextOverflow.ellipsis)),
              Icon(icon, color: Colors.orange),
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _weightSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(25),
                color: Colors.white,
              ),
              child: const Text("آخر 7 أيام"),
            ),
            const Text(
              "الوزن",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 260,
          child: weeklyReadings.isEmpty
              ? const Center(child: Text("لا توجد بيانات للعرض"))
              : _barChart(),
        ),
      ],
    );
  }

  Widget _barChart() {
    if (weeklyReadings.isEmpty) {
      return const Center(child: Text("لا توجد بيانات"));
    }

    List<String> dayNames = [];
    for (var reading in weeklyReadings) {
      try {
        DateTime date = DateTime.parse(reading["date"]);
        const arabicDays = [
          "الإثنين",
          "الثلاثاء",
          "الأربعاء",
          "الخميس",
          "الجمعة",
          "السبت",
          "الأحد"
        ];
        dayNames.add(arabicDays[date.weekday - 1]);
      } catch (e) {
        dayNames.add("");
      }
    }

    return BarChart(
      BarChartData(
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, _) {
                return Text(
                  value.toInt().toString(),
                  style: const TextStyle(fontSize: 10),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, _) {
                int index = value.toInt();
                if (index < 0 || index >= dayNames.length) {
                  return const Text('');
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    dayNames[index],
                    style: const TextStyle(fontSize: 11),
                  ),
                );
              },
            ),
          ),
        ),
        barGroups: List.generate(
          weeklyReadings.length,
          (index) => _bar(index, weeklyReadings[index]["weight"]),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 5,
        ),
      ),
    );
  }

  BarChartGroupData _bar(int index, double value) {
    return BarChartGroupData(
      x: index,
      barRods: [
        BarChartRodData(
          toY: value,
          width: 18,
          color: Colors.orange,
          borderRadius: BorderRadius.circular(8),
        ),
      ],
    );
  }
}
