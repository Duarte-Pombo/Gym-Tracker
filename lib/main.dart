import 'package:flutter/material.dart';
import 'routine_page.dart';
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

  // --- MOCK DATA FOR ROUTINE ---
  // In the real app, this comes from Hive
  final List<String> _currentRoutine = ['Push', 'Pull', 'Legs', 'Rest'];
  // The date the user STARTED this specific routine cycle.
  // We use this to calculate the offset.
  final DateTime _routineAnchorDate = DateTime(2023, 1, 1);

  final Set<DateTime> _trainedDays = {
    DateTime.now().subtract(const Duration(days: 1)),
    DateTime.now().subtract(const Duration(days: 3)),
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
          _buildCalendar(),
          const SizedBox(height: 20),
          _buildAccuracyMeter(),
          const Spacer(),
          // ... your bottom buttons (Log Workout / Configure Routine) ...
          Padding(
            padding: const EdgeInsets.only(bottom: 30.0, left: 20, right: 20),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton.icon(
                    onPressed: () { /* Log logic */ },
                    icon: const Icon(Icons.fitness_center),
                    label: const Text("LOG WORKOUT TODAY"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const RoutineSetupPage()),
                    );
                  },
                  child: Text("Configure Routine / Split", style: TextStyle(color: Colors.grey[400], decoration: TextDecoration.underline)),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  // --- UPDATED CALENDAR WIDGET ---

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
        // We set rowHeight a bit larger to fit the text comfortably
        rowHeight: 60,

        headerStyle: const HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          titleTextStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),

        // This removes the default styles because we are overriding them with builders
        calendarStyle: const CalendarStyle(
          outsideDaysVisible: false,
        ),

        // --- THE MAGIC HAPPENS HERE ---
        calendarBuilders: CalendarBuilders(

          // 1. DEFAULT DAY BUILDER (Not selected, not today)
          defaultBuilder: (context, day, focusedDay) {
            return _buildCustomDayCell(day, textColor: Colors.white);
          },

          // 2. TODAY BUILDER
          todayBuilder: (context, day, focusedDay) {
            return _buildCustomDayCell(
                day,
                textColor: Theme.of(context).primaryColor,
                borderColor: Theme.of(context).primaryColor.withOpacity(0.5)
            );
          },

          // 3. SELECTED DAY BUILDER
          selectedBuilder: (context, day, focusedDay) {
            return _buildCustomDayCell(
                day,
                textColor: Colors.black, // Contrast for filled circle
                backgroundColor: Theme.of(context).primaryColor
            );
          },

          // 4. MARKER BUILDER (The dot if you trained)
          singleMarkerBuilder: (context, day, event) {
            // We can customize the dot position if needed,
            // or return null to hide standard dots and handle it in the cell
            return Container(
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
              width: 6.0,
              height: 6.0,
              margin: const EdgeInsets.only(bottom: 45), // Move dot to top
            );
          },
        ),

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

  // --- CUSTOM CELL BUILDER ---

  Widget _buildCustomDayCell(DateTime day, {
    required Color textColor,
    Color? backgroundColor,
    Color? borderColor
  }) {
    // 1. Get the split name for this specific date
    String splitName = _getSplitForDate(day);
    bool isRestDay = splitName.toLowerCase() == 'rest';

    return Container(
      margin: const EdgeInsets.all(4.0),
      decoration: BoxDecoration(
        color: backgroundColor, // For selected state
        shape: BoxShape.circle,
        border: borderColor != null ? Border.all(color: borderColor, width: 2) : null,
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // The Date Number
            Text(
              '${day.day}',
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),

            // The Split Name
            const SizedBox(height: 2), // Tiny spacing
            Text(
              splitName,
              style: TextStyle(
                // Rest days get a green tint, others are dimmed grey
                // (unless selected, then black)
                color: backgroundColor != null
                    ? Colors.black.withOpacity(0.7)
                    : (isRestDay ? Colors.greenAccent : Colors.grey),
                fontSize: 10, // Small font to fit
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.clip, // Clip if too long
            ),
          ],
        ),
      ),
    );
  }

  // --- LOGIC HELPER ---

  String _getSplitForDate(DateTime date) {
    if (_currentRoutine.isEmpty) return "";

    // Normalize dates to ignore time (hours/minutes)
    final DateTime normalizedDate = DateTime(date.year, date.month, date.day);

    // Calculate difference in days from the Anchor Date
    int daysDifference = normalizedDate.difference(_routineAnchorDate).inDays;

    // Handle negative dates (if looking at calendar before anchor date)
    if (daysDifference < 0) {
      // Magic modulo math for negative numbers
      int cycleLength = _currentRoutine.length;
      int remainder = daysDifference % cycleLength;
      daysDifference = (remainder == 0) ? 0 : (cycleLength + remainder);
    }

    // Modulo to find index in the routine list
    int index = daysDifference % _currentRoutine.length;

    // Abbreviate if name is too long (optional)
    String name = _currentRoutine[index];
    if (name.length > 6) return name.substring(0, 6); // Truncate

    return name;
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

  // --- ACCURACY HELPERS ---

  Color _getAccuracyColor(double percent) {
    if (percent >= 0.8) return const Color(0xFFE65100); // Great (Orange)
    if (percent >= 0.5) return const Color(0xFFFFB74D); // Okay (Light Orange)
    return Colors.redAccent; // Needs work
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
  
}