import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:fl_chart/fl_chart.dart'; // 📊 High-performance charting backend

void main() {
  runApp(const RespiTrackApp());
}

class RespiTrackApp extends StatelessWidget {
  const RespiTrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF040710),
        colorScheme: const ColorScheme.dark(
          primary: Colors.cyanAccent,
          secondary: Colors.purpleAccent,
        ),
      ),
      home: const DashboardScreen(),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String? selectedPersona; 
  bool hasChosenProfile = false;

  String serverResponseText = "BIOMETRIC LINK ENGAGED // Standby for execution stream...";
  int streakCounter = 5;
  bool isLoading = false;
  
  double peakFlowProgress = 0.0;
  double lungVolProgress = 0.0;
  String peakFlowStr = "0 L/min";
  String lungVolStr = "0.00 L";
  String classificationResult = "STATION IDLE";

  // 🎛️ Dynamic multi-tier parameter controls
  double peakEffortMultiplier = 1.0; 
  List<int> rawCoordinates = [];

  Future<void> sendMockBreath() async {
    if (selectedPersona == null) return;
    setState(() { 
      isLoading = true; 
      rawCoordinates = []; // Reset visual graph canvas
    });

    final url = Uri.parse('http://127.0.0.1:8000/analyze_breath');
    
    int peakValue = 510; 
    if (selectedPersona == 'ATHLETE') {
      peakValue = 1020;
    } else if (selectedPersona == 'SINGER') {
      peakValue = 680;
    }

    // ⚡ Calculate fluid boundary limits from slider position
    peakValue = (peakValue * peakEffortMultiplier).toInt();

    List<int> mockBreathCurve = List.generate(150, (index) {
      return (index > 25 && index < 85) ? peakValue : 110;
    });

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "raw_stream": mockBreathCurve,
          "persona": selectedPersona!.toLowerCase(),
          "current_baseline_age": 22
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          if (data['status'] == 'success') {
            serverResponseText = data['display_text'] ?? "SUCCESSFUL ANALYSIS";
            streakCounter += 1;
            
            // Map generated array stream back to graph UI state container
            rawCoordinates = mockBreathCurve;

            final metrics = data['metrics'];
            if (metrics != null) {
              int rawPeak = metrics['peak_expiratory_flow'] ?? 0;
              int rawVol = metrics['forced_volume_1s'] ?? 0;
              
              peakFlowProgress = (rawPeak / 1200).clamp(0.0, 1.0);
              lungVolProgress = ((rawVol / 1000) / 6.0).clamp(0.0, 1.0);

              peakFlowStr = "$rawPeak L/min";
              lungVolStr = "${(rawVol / 1000).toStringAsFixed(2)} L";
            }
            
            if (data['rewards'] != null) {
              classificationResult = data['rewards']['badge'].toString().toUpperCase();
            }
          } else {
            serverResponseText = data['message'] ?? "ANALYSIS ERROR";
            classificationResult = "FAIL_LOW_EFFORT";
          }
        });
      }
    } catch (e) {
      setState(() {
        serverResponseText = "NETWORK ERROR: Check connection to local Python backend.";
      });
    } finally {
      setState(() { isLoading = false; });
    }
  }

  Widget _buildSelectionCard(String profileTitle, String subtitle, IconData icon, Color themeColor) {
    bool isSelected = selectedPersona == profileTitle;
    return GestureDetector(
      onTap: () {
        setState(() { selectedPersona = profileTitle; });
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? themeColor.withValues(alpha: 0.1) : const Color(0xFF0E1322),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? themeColor : Colors.white.withValues(alpha: 0.05)),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? themeColor : Colors.white24),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(profileTitle, style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? themeColor : Colors.white)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(fontSize: 10, color: Colors.white38)),
                ],
              ),
            ),
            if (isSelected) Icon(Icons.check_circle_rounded, color: themeColor, size: 20)
          ],
        ),
      ),
    );
  }

  Widget _buildDopamineMetricCard(String title, String stateValue, double linearValue, Color accentColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1424),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 10, color: Colors.white38)),
          const SizedBox(height: 5),
          Text(stateValue, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: accentColor, fontFamily: 'Courier')),
          const SizedBox(height: 10),
          LinearProgressIndicator(value: linearValue, backgroundColor: Colors.white10, color: accentColor, minHeight: 2),
        ],
      ),
    );
  }

  // 📈 Custom Diagnostic Telemetry Component Line Matrix Compiler
  Widget _buildLiveTelemetryChart() {
    List<FlSpot> chartDataPoints = [];
    if (rawCoordinates.isEmpty) {
      chartDataPoints = List.generate(50, (i) => FlSpot(i.toDouble(), 110));
    } else {
      for (int i = 0; i < rawCoordinates.length; i += 2) {
        chartDataPoints.add(FlSpot(i.toDouble(), rawCoordinates[i].toDouble()));
      }
    }

    return Container(
      height: 130,
      padding: const EdgeInsets.only(top: 20, right: 20, left: 10, bottom: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF070B19),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.1)),
      ),
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          minY: 0,
          maxY: 1200,
          lineBarsData: [
            LineChartBarData(
              spots: chartDataPoints,
              isCurved: true,
              color: Colors.cyanAccent,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: Colors.cyanAccent.withValues(alpha: 0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOnboardingScreen() {
    return Padding(
      key: const ValueKey('onboarding_view'),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text("RESPITRACK // CORE ENGINE", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          const Text("Initialize biometric profile nodes to lock algorithms.", style: TextStyle(color: Colors.white38, fontSize: 13)),
          const SizedBox(height: 30),
          
          _buildSelectionCard("ATHLETE", "Peak performance tracking.", Icons.bolt, Colors.cyanAccent),
          const SizedBox(height: 15),
          _buildSelectionCard("SINGER", "Air control stability.", Icons.music_note_rounded, Colors.purpleAccent),
          const SizedBox(height: 15),
          _buildSelectionCard("SMOKER", "Tissue recovery metrics.", Icons.smoke_free_rounded, Colors.greenAccent),
          
          const Spacer(),
          
          ElevatedButton(
            onPressed: selectedPersona == null ? null : () {
              setState(() { hasChosenProfile = true; });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              minimumSize: const Size.fromHeight(55),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text("LAUNCH CORE MATRIX", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
          ),
        ],
      ),
    );
  }

  Widget _buildCoreDashboard() {
    return Padding(
      key: const ValueKey('dashboard_view'),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("NODE: $selectedPersona", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const Text("SYSTEM ONLINE // BIO-CORE SECURE", style: TextStyle(fontSize: 8, color: Colors.cyanAccent)),
                ],
              ),
              GestureDetector(
                onTap: () {
                  setState(() { hasChosenProfile = false; });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF152A20),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Text("🔥 ", style: TextStyle(fontSize: 13)),
                      Text("$streakCounter DAYS", style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 12)),
                    ],
                  ),
                ),
              )
            ],
          ),
          const SizedBox(height: 15),
          
          _buildLiveTelemetryChart(),
          
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(child: _buildDopamineMetricCard("AIR VELOCITY", peakFlowStr, peakFlowProgress, Colors.cyanAccent)),
              const SizedBox(width: 15),
              Expanded(child: _buildDopamineMetricCard("VOLUME", lungVolStr, lungVolProgress, Colors.purpleAccent)),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF0F1424),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
            child: Row(
              children: [
                const Text("AI EARNED SHIELD", style: TextStyle(fontSize: 9, color: Colors.white38)),
                const Spacer(),
                Text(classificationResult, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.greenAccent)),
              ],
            ),
          ),
          const SizedBox(height: 15),
          
          // 🎛️ Interactive Modifier Input Node Engine Array
          const Text(
            "SIMULATED LUNG EFFORT MULTIPLIER", 
            style: TextStyle(fontSize: 9, color: Colors.white38, letterSpacing: 1),
            textAlign: TextAlign.center,
          ),
          Slider(
            value: peakEffortMultiplier,
            min: 0.3,
            max: 1.5,
            divisions: 12,
            label: "${(peakEffortMultiplier * 100).toInt()}% Power",
            activeColor: Colors.cyanAccent,
            onChanged: (value) {
              setState(() {
                peakEffortMultiplier = value;
              });
            },
          ),
          
          const Spacer(),
          Center(
            child: GestureDetector(
              onTap: isLoading ? null : sendMockBreath,
              child: Container(
                height: 125, width: 125,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.cyanAccent, width: 2),
                  boxShadow: [BoxShadow(color: Colors.cyanAccent.withValues(alpha: 0.2), blurRadius: 20)],
                ),
                child: Center(
                  child: isLoading 
                    ? const CircularProgressIndicator() 
                    : const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.air_rounded, color: Colors.cyanAccent),
                          Text("RUN CAPTURE", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        ],
                      ),
                ),
              ),
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(15)),
            child: Text(serverResponseText, style: const TextStyle(fontFamily: 'Courier', fontSize: 11)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          child: !hasChosenProfile ? _buildOnboardingScreen() : _buildCoreDashboard(),
        ),
      ),
    );
  }
}