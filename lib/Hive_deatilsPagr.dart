import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class HiveDashboardPage extends StatefulWidget {
  const HiveDashboardPage({super.key});

  @override
  State<HiveDashboardPage> createState() => _HiveDashboardPageState();
}

class _HiveDashboardPageState extends State<HiveDashboardPage> {
  List<dynamic> hives = [];
  List<dynamic> recentHives = [];
  List<dynamic> alerts = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchHives();
    fetchAlerts();
  }

  // Fetch user-specific hives
  Future<void> fetchHives() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString("access_token");

      final url = Uri.parse("http://ip:8000/api/hives/");
      final response = await http.get(url, headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          // Handle both paginated and non-paginated responses
          if (data is Map && data.containsKey("results")) {
            hives = List.from(data["results"] ?? []);
          } else if (data is List) {
            hives = List.from(data);
          } else {
            hives = [];
          }
          recentHives = hives.length > 2 ? hives.sublist(0, 2) : hives;
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

  // Fetch user-specific alerts
  Future<void> fetchAlerts() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString("access_token");

      final url = Uri.parse("http://192.168.15.125:8000/api/alerts/");
      final response = await http.get(url, headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Handle both paginated and non-paginated responses
        if (data is Map && data.containsKey("results")) {
          setState(() => alerts = List.from(data["results"] ?? []));
        } else if (data is List) {
          setState(() => alerts = List.from(data));
        }
      } else {
        print("Failed to load alerts: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching alerts: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: loading
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.orange))
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _header(),
                      const SizedBox(height: 15),
                      _searchBar(),
                      const SizedBox(height: 20),
                      if (recentHives.isNotEmpty) ...[
                        _sectionTitle("الخلايا الحديثة"),
                        SizedBox(
                          height: 230,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: recentHives.length,
                            padding: const EdgeInsets.only(left: 16),
                            itemBuilder: (context, i) =>
                                _hiveCard(recentHives[i], context),
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                      _sectionTitle("جميع الخلايا"),
                      hives.isEmpty
                          ? const Padding(
                              padding: EdgeInsets.all(16),
                              child: Center(child: Text("لا توجد خلايا")),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: hives.length,
                              padding: const EdgeInsets.all(16),
                              itemBuilder: (context, i) =>
                                  _hiveCard(hives[i], context),
                            ),
                      const SizedBox(height: 20),
                      _sectionTitle("التنبيهات"),
                      _alertsSection(),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _header() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.orange,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: const [
          Icon(Icons.hive, color: Colors.white, size: 28),
          Text("الخلايا",
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold))
        ],
      ),
    );
  }

  Widget _searchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const TextField(
          textAlign: TextAlign.right,
          decoration: InputDecoration(
            hintText: "بحث",
            prefixIcon: Icon(Icons.search),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(vertical: 14, horizontal: 10),
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Text(title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
    );
  }

  Widget _hiveCard(dynamic hive, BuildContext context) {
    // Safety check - ensure hive is a Map
    if (hive == null || hive is! Map) {
      return const SizedBox.shrink();
    }

    // Safely extract data with null checks
    String hiveName = hive["name"]?.toString() ?? "خلية ${hive["id"] ?? ""}";
    int hiveId = hive["id"] is int ? hive["id"] : 0;
    
    final latest = hive["latest_reading"];
    String temp = "--";
    String humidity = "--";
    String weight = "--";
    
    if (latest != null && latest is Map) {
      temp = latest["temperature"] != null ? "${latest["temperature"]}°" : "--";
      humidity = latest["humidity"] != null ? "${latest["humidity"]}%" : "--";
      weight = latest["weight"] != null ? "${latest["weight"]} kg" : "--";
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => HiveDetailsPage(
                hiveId: hiveId, hiveName: hiveName),
          ),
        );
      },
      child: Container(
        width: 220,
        margin: const EdgeInsets.only(right: 16, bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF1C9),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(hiveName,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis),
                ),
                const Icon(Icons.hive, color: Colors.orange),
              ],
            ),
            const SizedBox(height: 10),
            Row(children: const [
              Icon(Icons.thermostat, size: 18),
              SizedBox(width: 5),
              Text("درجة الحرارة"),
            ]),
            Text(temp,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            Row(children: const [
              Icon(Icons.water_drop, size: 18),
              SizedBox(width: 5),
              Text("الرطوبة"),
            ]),
            Text(humidity,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
              decoration: BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.monitor_weight,
                      color: Colors.white, size: 18),
                  const SizedBox(width: 5),
                  Text("الوزن: $weight",
                      style: const TextStyle(color: Colors.white)),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _alertsSection() {
    if (alerts.isEmpty) {
      return const SizedBox(
          height: 50, child: Center(child: Text("لا توجد تنبيهات")));
    }

    return Column(
      children: alerts.map((alert) => _alertItem(alert)).toList(),
    );
  }

  Widget _alertItem(dynamic alert) {
    // Safety check
    if (alert == null || alert is! Map) {
      return const SizedBox.shrink();
    }

    String hiveName = "Unknown";
    
    // Handle both cases: hive as object or hive as ID
    if (alert["hive"] != null) {
      if (alert["hive"] is Map) {
        hiveName = alert["hive"]["name"]?.toString() ?? 
                   alert["hive"]["hive_id"]?.toString() ?? 
                   "خلية ${alert["hive"]["id"]}";
      } else if (alert["hive"] is int) {
        hiveName = "خلية ${alert["hive"]}";
      }
    }
    
    String message = alert["message"]?.toString() ?? "";
    String severity = alert["severity"]?.toString() ?? "info";
    String createdAt = alert["created_at"]?.toString() ?? "";
    String date = createdAt.length >= 10 ? createdAt.substring(0, 10) : "";
    String time = createdAt.length >= 16 ? createdAt.substring(11, 16) : "";

    Color color;
    switch (severity.toLowerCase()) {
      case "critical":
        color = Colors.red;
        break;
      case "warning":
        color = Colors.orange;
        break;
      default:
        color = Colors.blue;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning, color: color),
              const SizedBox(width: 10),
              Expanded(
                child: Text(hiveName,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
              Text(time, style: const TextStyle(color: Colors.grey)),
              const SizedBox(width: 10),
              Text(date, style: const TextStyle(color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 8),
          Text(message, style: const TextStyle(fontSize: 15)),
        ],
      ),
    );
  }
}

// -------------------- Hive Details Page --------------------
class HiveDetailsPage extends StatefulWidget {
  final int hiveId;
  final String hiveName;

  const HiveDetailsPage({super.key, required this.hiveId, required this.hiveName});

  @override
  State<HiveDetailsPage> createState() => _HiveDetailsPageState();
}

class _HiveDetailsPageState extends State<HiveDetailsPage> {
  List<dynamic> alerts = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchHiveDetails();
  }

  Future<void> fetchHiveDetails() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString("access_token");

      final hiveUrl = Uri.parse("http://192.168.15.125:8000/api/hives/${widget.hiveId}/");
      final alertUrl = Uri.parse("http://192.168.15.125:8000/api/alerts/?hive=${widget.hiveId}");

      final hiveResponse = await http.get(hiveUrl, headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      });

      final alertResponse = await http.get(alertUrl, headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      });

      if (hiveResponse.statusCode == 200 && alertResponse.statusCode == 200) {
        final alertData = jsonDecode(alertResponse.body);

        setState(() {
          // Handle both paginated and non-paginated responses
          if (alertData is Map && alertData.containsKey("results")) {
            alerts = List.from(alertData["results"] ?? []);
          } else if (alertData is List) {
            alerts = List.from(alertData);
          }
          loading = false;
        });
      } else {
        setState(() => loading = false);
        print("Failed to load hive or alerts");
      }
    } catch (e) {
      setState(() => loading = false);
      print("Error fetching hive details: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: loading
              ? const Center(child: CircularProgressIndicator(color: Colors.orange))
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _header(),
                      const SizedBox(height: 20),
                      _sectionTitle("التنبيهات"),
                      _alertsSection(),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _header() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: const BoxDecoration(
        color: Colors.orange,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(25),
          bottomRight: Radius.circular(25),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
              onTap: () => Navigator.pop(context),
              child: const Icon(Icons.arrow_back, color: Colors.white, size: 26)),
          Expanded(
            child: Text(widget.hiveName,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Colors.white, fontSize: 21, fontWeight: FontWeight.bold)),
          ),
          const Icon(Icons.hive, color: Colors.white, size: 28),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Text(title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
    );
  }

  Widget _alertsSection() {
    if (alerts.isEmpty) {
      return const SizedBox(
          height: 50, child: Center(child: Text("لا توجد تنبيهات")));
    }

    return Column(
      children: alerts.map((alert) {
        // Safety check
        if (alert == null || alert is! Map) {
          return const SizedBox.shrink();
        }

        String message = alert["message"]?.toString() ?? "";
        String severity = alert["severity"]?.toString() ?? "info";
        String createdAt = alert["created_at"]?.toString() ?? "";
        String date = createdAt.length >= 10 ? createdAt.substring(0, 10) : "";
        String time = createdAt.length >= 16 ? createdAt.substring(11, 16) : "";

        Color color;
        switch (severity.toLowerCase()) {
          case "critical":
            color = Colors.red;
            break;
          case "warning":
            color = Colors.orange;
            break;
          default:
            color = Colors.blue;
        }

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: color, width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.warning, color: color),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(message, 
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  Text(time, style: const TextStyle(color: Colors.grey)),
                  const SizedBox(width: 10),
                  Text(date, style: const TextStyle(color: Colors.grey)),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
