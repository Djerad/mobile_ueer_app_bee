import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  List<dynamic> alerts = [];
  bool loading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    fetchAlerts();
  }

  // Fetch admin alerts
  Future<void> fetchAlerts() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString("access_token");

      final url = Uri.parse("http://ip:8000/api/admin/alerts/");
      final response = await http.get(url, headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          // Handle both paginated and non-paginated responses
          if (data is Map && data.containsKey("results")) {
            alerts = List.from(data["results"] ?? []);
          } else if (data is List) {
            alerts = List.from(data);
          } else {
            alerts = [];
          }
          loading = false;
        });
      } else {
        setState(() {
          loading = false;
          errorMessage = "فشل في تحميل التنبيهات: ${response.statusCode}";
        });
        print("Failed to load alerts: ${response.statusCode}");
        print("Response body: ${response.body}");
      }
    } catch (e) {
      setState(() {
        loading = false;
        errorMessage = "خطأ في الاتصال بالخادم";
      });
      print("Error fetching alerts: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Container(
            height: 100,
            decoration: BoxDecoration(
              color: Colors.orange,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Center(
              child: Text(
                'التنبيهات',
                style: GoogleFonts.cairo(
                  fontSize: 20,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          // Use Expanded to allow ListView to fill remaining space
          Expanded(
            child: loading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.orange))
                : errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline,
                                size: 60, color: Colors.grey),
                            const SizedBox(height: 16),
                            Text(
                              errorMessage!,
                              style: const TextStyle(
                                  fontSize: 16, color: Colors.grey),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  loading = true;
                                  errorMessage = null;
                                });
                                fetchAlerts();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                              ),
                              child: const Text('إعادة المحاولة'),
                            ),
                          ],
                        ),
                      )
                    : alerts.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.notifications_off,
                                    size: 60, color: Colors.grey),
                                const SizedBox(height: 16),
                                Text(
                                  'لا توجد تنبيهات',
                                  style: GoogleFonts.cairo(
                                    fontSize: 18,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: fetchAlerts,
                            color: Colors.orange,
                            child: ListView.builder(
                              physics: const AlwaysScrollableScrollPhysics(),
                              itemCount: alerts.length,
                              itemBuilder: (context, index) {
                                if (index >= alerts.length) return const SizedBox();
                                final alert = alerts[index];
                                if (alert == null) return const SizedBox();
                                return _notificationItem(alert);
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _notificationItem(dynamic alert) {
    // Add null check at the start
    if (alert == null) {
      return const SizedBox.shrink();
    }

    String message = alert["message"]?.toString() ?? "لا توجد رسالة";
    String severity = alert["severity"]?.toString() ?? "info";
    String createdAt = alert["created_at"]?.toString() ?? "";
    String date = createdAt.length >= 10 ? createdAt.substring(0, 10) : "";
    String time = createdAt.length >= 16 ? createdAt.substring(11, 16) : "";
    
    // Get hive name if available
    String hiveName = "";
    try {
      if (alert["hive"] != null && alert["hive"] is Map) {
        hiveName = alert["hive"]["name"]?.toString() ?? 
                   alert["hive"]["hive_id"]?.toString() ?? 
                   "";
      }
    } catch (e) {
      print("Error parsing hive name: $e");
    }

    // Determine icon and color based on severity
    IconData icon;
    Color color;
    String title;

    switch (severity) {
      case "critical":
        icon = Icons.error;
        color = Colors.red;
        title = "تنبيه حرج";
        break;
      case "warning":
        icon = Icons.warning;
        color = Colors.orange;
        title = "تحذير";
        break;
      default:
        icon = Icons.info;
        color = Colors.blue;
        title = "معلومات";
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
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
              Icon(icon, color: color),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    if (hiveName.isNotEmpty)
                      Text(
                        hiveName,
                        style: TextStyle(
                            fontSize: 14, color: Colors.grey.shade700),
                      ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(time, style: const TextStyle(color: Colors.grey)),
                  Text(date,
                      style:
                          TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: const TextStyle(fontSize: 15),
          ),
        ],
      ),
    );
  }
}
