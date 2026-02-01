import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:percent_indicator/percent_indicator.dart';

void main() {
  runApp(const GymTrackerApp());
}

class GymTrackerApp extends StatelessWidget {
  const GymTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Gym Tracker',
      // DEFINING THE WARM DARK THEME
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF1E1C1A), // Warm Charcoal
        primaryColor: const Color(0xFFE65100), // Burnt Orange
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFE65100),
          secondary: Color(0xFFFF8A65), // Lighter warm tone
          surface: Color(0xFF2C2927), // Card background
        ),
        useMaterial3: true,
      ),
      home: const GymTrackerHome(),
    );
  }
}

class GymTrackerHome extends StatefulWidget {
  const GymTrackerHome({super.key});

  @override
  State<GymTrackerHome> createState() => _GymTrackerHomeState();
}

class _GymTrackerHomeState extends State<GymTrackerHome> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  // Mock Data: Storing dates as a Set for O(1) lookup
  // In the future, this will come from your local database
  final Set<DateTime> _trainedDays = {
    DateTime.now().subtract(const Duration(days: 1)),
    DateTime.now().subtract(const Duration(days: 3)),
    DateTime.now().subtract(const Duration(days: 4)),
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Training Frequency"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          // 1. THE CALENDAR
          _buildCalendar(),

          const SizedBox(height: 20),

          // 2. THE ACCURACY METER
          _buildAccuracyMeter(),

          const Spacer(),

          // Temporary Button to toggle today as trained
          Padding(
            padding: const EdgeInsets.only(bottom: 40.0),
            child: FloatingActionButton.extended(
              onPressed: () {
                setState(() {
                  final today = DateTime.now();
                  final normalizedToday = DateTime(today.year, today.month, today.day);

                  // Simple toggle logic for demo purposes
                  if (_isDayTrained(normalizedToday)) {
                    _removeTrainingDay(normalizedToday);
                  } else {
                    _addTrainingDay(normalizedToday);
                  }
                });
              },
              icon: const Icon(Icons.fitness_center),
              label: const Text("Log Workout"),
              backgroundColor: Theme.of(context).primaryColor,
            ),
          )
        ],
      ),
    );
  }

  // --- WIDGET BUILDERS ---

  Widget _buildCalendar() {

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: TableCalendar(
        firstDay: DateTime.utc(2020, 1, 1),
        lastDay: DateTime.utc(2030, 12, 31),
        focusedDay: _focusedDay,
        calendarFormat: CalendarFormat.month,

        // Styling the Calendar
        headerStyle: const HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          titleTextStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        calendarStyle: CalendarStyle(
          // Style for days you trained
          markerDecoration: BoxDecoration(
            color: Theme.of(context).primaryColor,
            shape: BoxShape.circle,
          ),
          todayDecoration: BoxDecoration(
            color: Theme.of(context).colorScheme.secondary.withOpacity(0.5),
            shape: BoxShape.circle,
          ),
          selectedDecoration: BoxDecoration(
            color: Theme.of(context).primaryColor,
            shape: BoxShape.circle,
          ),
        ),

        // Logic to mark dots on calendar
        eventLoader: (day) {
          return _isDayTrained(day) ? ['Trained'] : [];
        },
        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
        onDaySelected: (selectedDay, focusedDay) {
          setState(() {
            _selectedDay = selectedDay;
            _focusedDay = focusedDay;
          });
        },
        onPageChanged: (focusedDay) {
          _focusedDay = focusedDay;
        },
      ),
    );
  }

  Widget _buildAccuracyMeter() {

    double accuracy = _calculateAccuracy();

    return Column(
      children: [
        const Text(
          "Consistency Score",
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
        const SizedBox(height: 15),
        CircularPercentIndicator(
          radius: 80.0,
          lineWidth: 12.0,
          animation: true,
          percent: accuracy,
          center: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "${(accuracy * 100).toStringAsFixed(1)}%",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 32.0,
                  color: Colors.white,
                ),
              ),
              const Text("This Month", style: TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
          circularStrokeCap: CircularStrokeCap.round,
          progressColor: _getAccuracyColor(accuracy),
          backgroundColor: Colors.grey[800]!,
        ),
      ],
    );
  }

  // --- HELPERS & LOGIC ---

  bool _isDayTrained(DateTime day) {
    // Normalize date to ignore time
    DateTime normalized = DateTime(day.year, day.month, day.day);
    // Check if any date in the set matches this normalized date
    return _trainedDays.any((d) =>
    d.year == normalized.year &&
        d.month == normalized.month &&
        d.day == normalized.day
    );
  }

  void _addTrainingDay(DateTime day) {
    _trainedDays.add(DateTime(day.year, day.month, day.day));
  }

  void _removeTrainingDay(DateTime day) {
    _trainedDays.removeWhere((d) =>
    d.year == day.year &&
        d.month == day.month &&
        d.day == day.day
    );
  }

  // Calculates percentage of days trained vs days passed in current month
  double _calculateAccuracy() {
    final now = DateTime.now();
    // Get total days in current month so far (e.g. if it's 5th, days = 5)
    // Or if you prefer total days in month, change logic.
    // Here we use days passed to allow for 100% score early in the month.
    int totalDaysPossible = now.day;

    int daysTrainedThisMonth = _trainedDays.where((d) =>
    d.year == now.year && d.month == now.month && d.day <= now.day
    ).length;

    if (totalDaysPossible == 0) return 0.0;

    return (daysTrainedThisMonth / totalDaysPossible).clamp(0.0, 1.0);
  }

  Color _getAccuracyColor(double percent) {
    if (percent >= 0.8) return const Color(0xFFE65100); // Great (Orange)
    if (percent >= 0.5) return const Color(0xFFFFB74D); // Okay (Light Orange)
    return Colors.redAccent; // Needs work
  }
}