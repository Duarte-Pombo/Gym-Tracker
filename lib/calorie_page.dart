import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:fl_chart/fl_chart.dart';

class CaloriePage extends StatefulWidget {
  const CaloriePage({super.key});

  @override
  State<CaloriePage> createState() => _CaloriePageState();
}

class _CaloriePageState extends State<CaloriePage> {
  final Box _calorieBox = Hive.box('calorieBox');
  final Box _settingsBox = Hive.box('settingsBox');

  final TextEditingController _addController = TextEditingController();
  final TextEditingController _goalController = TextEditingController();

  int _dailyGoal = 2500;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _dailyGoal = _settingsBox.get('calorieGoal', defaultValue: 2500);
  }

  // Helper: Get key for date
  String _getKey(DateTime date) => "${date.year}-${date.month}-${date.day}";

  // Get calories for specific date
  int _getCalories(DateTime date) {
    return _calorieBox.get(_getKey(date), defaultValue: 0);
  }

  void _addCalories() {
    if (_addController.text.isEmpty) return;
    int amount = int.tryParse(_addController.text) ?? 0;

    setState(() {
      String key = _getKey(_selectedDate);
      int current = _getCalories(_selectedDate);
      _calorieBox.put(key, current + amount);
    });
    _addController.clear();
  }

  void _updateGoal() {
    if (_goalController.text.isEmpty) return;
    int newGoal = int.tryParse(_goalController.text) ?? 2500;
    setState(() {
      _dailyGoal = newGoal;
      _settingsBox.put('calorieGoal', newGoal);
    });
    Navigator.pop(context); // Close dialog
  }

  @override
  Widget build(BuildContext context) {
    int todayCalories = _getCalories(_selectedDate);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Nutrition Tracker"),
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showGoalDialog,
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              // 1. TODAY'S SUMMARY
              _buildBigCounter(todayCalories),

              const SizedBox(height: 30),

              // 2. CHART
              Container(
                height: 250,
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: _buildWeeklyChart(),
              ),

              const SizedBox(height: 30),

              // 3. INPUT AREA
              _buildInputArea(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBigCounter(int current) {
    double progress = (current / _dailyGoal).clamp(0.0, 1.0);

    return Column(
      children: [
        Text(
          "$current / $_dailyGoal kcal",
          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 10,
            backgroundColor: Colors.grey[800],
            color: progress > 1.0 ? Colors.red : const Color(0xFFE65100),
          ),
        ),
      ],
    );
  }

  Widget _buildWeeklyChart() {
    DateTime now = DateTime.now();
    // Generate data for last 7 days
    List<BarChartGroupData> barGroups = [];

    for (int i = 6; i >= 0; i--) {
      DateTime day = now.subtract(Duration(days: i));
      int cals = _getCalories(day);

      barGroups.add(
        BarChartGroupData(
          x: 6 - i, // 0 to 6
          barRods: [
            BarChartRodData(
              toY: cals.toDouble(),
              color: cals >= _dailyGoal ? Colors.greenAccent : const Color(0xFFE65100),
              width: 12,
              borderRadius: BorderRadius.circular(4),
              backDrawRodData: BackgroundBarChartRodData(
                show: true,
                toY: _dailyGoal.toDouble() * 1.2, // Slightly higher than goal
                color: Colors.black26,
              ),
            ),
          ],
        ),
      );
    }

    return BarChart(
      BarChartData(
        barGroups: barGroups,
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                DateTime day = now.subtract(Duration(days: 6 - value.toInt()));
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    "${day.day}/${day.month}",
                    style: const TextStyle(color: Colors.grey, fontSize: 10),
                  ),
                );
              },
            ),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) => FlLine(color: Colors.white10, strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        // Add a line for the Goal
        extraLinesData: ExtraLinesData(
          horizontalLines: [
            HorizontalLine(
              y: _dailyGoal.toDouble(),
              color: Colors.white30,
              strokeWidth: 1,
              dashArray: [5, 5],
              label: HorizontalLineLabel(
                show: true,
                labelResolver: (line) => 'Goal',
                style: const TextStyle(color: Colors.white30, fontSize: 10),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _addController,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: "Add Calories (e.g. 500)",
              hintStyle: TextStyle(color: Colors.grey[600]),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        const SizedBox(width: 15),
        FloatingActionButton(
          onPressed: _addCalories,
          backgroundColor: Theme.of(context).primaryColor,
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ],
    );
  }

  void _showGoalDialog() {
    _goalController.text = _dailyGoal.toString();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2C2927),
        title: const Text("Set Calorie Baseline"),
        content: TextField(
          controller: _goalController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: "Daily Goal"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(onPressed: _updateGoal, child: const Text("Save")),
        ],
      ),
    );
  }
}