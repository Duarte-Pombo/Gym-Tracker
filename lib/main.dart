import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'progress_gallery_page.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'routine_page.dart';
import 'calorie_page.dart'; // Import the new page

void main() async {
  await Hive.initFlutter();

  await Hive.openBox('settingsBox');
  await Hive.openBox('workoutBox');
  await Hive.openBox('calorieBox');
  await Hive.openBox('progressBox');

  runApp(const GymTrackerApp());
}

class GymTrackerApp extends StatelessWidget {
  const GymTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Gym Tracker',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF1E1C1A),
        primaryColor: const Color(0xFFE65100),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFE65100),
          secondary: Color(0xFFFF8A65),
          surface: Color(0xFF2C2927),
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

class _GymTrackerHomeState extends State<GymTrackerHome> with SingleTickerProviderStateMixin {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  // Database references
  final Box _settingsBox = Hive.box('settingsBox');
  final Box _workoutBox = Hive.box('workoutBox');
  final Box _calorieBox = Hive.box('calorieBox');

  // Local state
  List<String> _currentRoutine = [];
  DateTime _routineAnchorDate = DateTime.now();

  // Animation for Streak Fire
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _loadRoutineData();

    // Pulse animation for the fire streak
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _loadRoutineData() {
    setState(() {
      _currentRoutine = _settingsBox.get('currentRoutine', defaultValue: <String>[])?.cast<String>() ?? [];
      _routineAnchorDate = _settingsBox.get('anchorDate', defaultValue: DateTime.now());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          const SizedBox(height: 10),

          // 1. DASHBOARD HEADER (Streak - Frequency - Calories)
          _buildDashboardRow(),

          const SizedBox(height: 25),

          // 2. CALENDAR
          Expanded(child: _buildCalendar()),

          // 3. BOTTOM ACTION BUTTONS
          _buildBottomActions(),
        ],
      ),
    );
  }

  Widget _buildDashboardRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // LEFT: STREAK
          Expanded(child: _buildStreakWidget()),

          // CENTER: FREQUENCY (Accuracy)
          _buildAccuracyWidget(),

          // RIGHT: CALORIES
          Expanded(child: _buildCalorieSummaryWidget()),
        ],
      ),
    );
  }

  // --- WIDGETS ---

  Widget _buildStreakWidget() {
    int streak = _calculateStreak();
    return Column(
      children: [
        AnimatedBuilder(
          animation: _animController,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: const Icon(Icons.local_fire_department, color: Colors.orangeAccent, size: 36),
            );
          },
        ),
        const SizedBox(height: 5),
        Text("$streak Day Streak", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white70)),
      ],
    );
  }

  Widget _buildAccuracyWidget() {
    double accuracy = _calculateAccuracy();
    return CircularPercentIndicator(
      radius: 65.0,
      lineWidth: 10.0,
      animation: true,
      percent: accuracy,
      center: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "${(accuracy * 100).toStringAsFixed(0)}%",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22.0, color: Colors.white),
          ),
          const Text("Freq.", style: TextStyle(fontSize: 10, color: Colors.grey)),
        ],
      ),
      circularStrokeCap: CircularStrokeCap.round,
      progressColor: _getAccuracyColor(accuracy),
      backgroundColor: Colors.grey[800]!,
    );
  }

  Widget _buildCalorieSummaryWidget() {
    final DateTime today = DateTime.now();
    final String key = "${today.year}-${today.month}-${today.day}";
    final int calories = _calorieBox.get(key, defaultValue: 0);
    final int goal = _settingsBox.get('calorieGoal', defaultValue: 2500);

    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const CaloriePage()),
        );
        setState(() {}); // Refresh when returning
      },
      child: Column(
        children: [
          const Icon(Icons.pie_chart, color: Colors.greenAccent, size: 36),
          const SizedBox(height: 5),
          Text("$calories / $goal", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white70)),
          const Text("kcal", style: TextStyle(fontSize: 10, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildBottomActions() {
    return Container(
      padding: const EdgeInsets.only(bottom: 30.0, left: 20, right: 20, top: 20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
      ),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton.icon(
              onPressed: () => _toggleTrainingDay(DateTime.now()),
              icon: const Icon(Icons.fitness_center),
              label: Text(_isDayTrained(DateTime.now()) ? "UN-LOG WORKOUT" : "LOG WORKOUT"),
              style: ElevatedButton.styleFrom(
                backgroundColor: _isDayTrained(DateTime.now()) ? Colors.grey : Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ),

          const SizedBox(height: 15),

          // --- NEW GALLERY BUTTON ---
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ProgressGalleryPage()),
                );
              },
              icon: const Icon(Icons.photo_library),
              label: const Text("PROGRESS GALLERY"),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white24),
              ),
            ),
          ),
          // --------------------------

          const SizedBox(height: 15),

          TextButton(
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const RoutineSetupPage()),
              );
              _loadRoutineData();
            },
            child: Text(
              "Configure Split",
              style: TextStyle(color: Colors.grey[400], decoration: TextDecoration.underline),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: TableCalendar(
        firstDay: DateTime.utc(2020, 1, 1),
        lastDay: DateTime.utc(2030, 12, 31),
        focusedDay: _focusedDay,
        calendarFormat: CalendarFormat.month,
        rowHeight: 55,
        headerStyle: const HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          titleTextStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        calendarStyle: const CalendarStyle(outsideDaysVisible: false),
        calendarBuilders: CalendarBuilders(
          defaultBuilder: (context, day, focusedDay) => _buildCustomDayCell(day, textColor: Colors.white),
          todayBuilder: (context, day, focusedDay) => _buildCustomDayCell(day, textColor: Theme.of(context).primaryColor, borderColor: Theme.of(context).primaryColor.withOpacity(0.5)),
          selectedBuilder: (context, day, focusedDay) => _buildCustomDayCell(day, textColor: Colors.black, backgroundColor: Theme.of(context).primaryColor),
          singleMarkerBuilder: (context, day, event) => const SizedBox.shrink(), // Hide default dots
        ),
        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
        onDaySelected: (selectedDay, focusedDay) {
          setState(() {
            _selectedDay = selectedDay;
            _focusedDay = focusedDay;
          });
        },
        onPageChanged: (focusedDay) => _focusedDay = focusedDay,
      ),
    );
  }

  Widget _buildCustomDayCell(DateTime day, {required Color textColor, Color? backgroundColor, Color? borderColor}) {
    String splitName = _getSplitForDate(day);
    bool isRestDay = splitName.toLowerCase() == 'rest';
    bool isTrained = _isDayTrained(day);

    // If day is trained, override background (unless it's selected, we keep selection visible)
    if (isTrained && backgroundColor == null) {
      backgroundColor = Colors.white10;
      borderColor = Colors.green;
    }

    return Container(
      margin: const EdgeInsets.all(4.0),
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
        border: borderColor != null ? Border.all(color: borderColor, width: 2) : null,
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('${day.day}', style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 14)),
            if (splitName.isNotEmpty)
              Text(
                splitName,
                style: TextStyle(
                  color: isRestDay ? Colors.greenAccent : Colors.grey,
                  fontSize: 8,
                ),
                maxLines: 1,
                overflow: TextOverflow.clip,
              ),
          ],
        ),
      ),
    );
  }

  // --- LOGIC HELPER METHODS ---

  String _getSplitForDate(DateTime date) {
    if (_currentRoutine.isEmpty) return "";
    final DateTime normalizedDate = DateTime(date.year, date.month, date.day);
    final DateTime normalizedAnchor = DateTime(_routineAnchorDate.year, _routineAnchorDate.month, _routineAnchorDate.day);
    int daysDifference = normalizedDate.difference(normalizedAnchor).inDays;

    if (daysDifference < 0) {
      int cycleLength = _currentRoutine.length;
      int remainder = daysDifference % cycleLength;
      daysDifference = (remainder == 0) ? 0 : (cycleLength + remainder);
    }

    return _currentRoutine[daysDifference % _currentRoutine.length];
  }

  String _getKey(DateTime day) => "${day.year}-${day.month}-${day.day}";

  bool _isDayTrained(DateTime day) => _workoutBox.containsKey(_getKey(day));

  void _toggleTrainingDay(DateTime day) {
    final key = _getKey(day);
    setState(() {
      if (_workoutBox.containsKey(key)) {
        _workoutBox.delete(key);
      } else {
        _workoutBox.put(key, true);
      }
    });
  }

  double _calculateAccuracy() {
    final now = DateTime.now();
    int totalDaysPossible = now.day;
    if (totalDaysPossible == 0) return 0.0;

    int daysTrainedThisMonth = 0;
    for (int i = 1; i <= now.day; i++) {
      if (_workoutBox.containsKey(_getKey(DateTime(now.year, now.month, i)))) {
        daysTrainedThisMonth++;
      }
    }
    return (daysTrainedThisMonth / totalDaysPossible).clamp(0.0, 1.0);
  }

  Color _getAccuracyColor(double percent) {
    if (percent >= 0.8) return const Color(0xFFE65100);
    if (percent >= 0.5) return const Color(0xFFFFB74D);
    return Colors.redAccent;
  }

  // Counts consecutive days going backwards from today/yesterday
  int _calculateStreak() {
    DateTime checkDate = DateTime.now();
    int streak = 0;

    // If we haven't trained today yet, start checking from yesterday
    // But if we HAVE trained today, include it.
    if (!_isDayTrained(checkDate)) {
      checkDate = checkDate.subtract(const Duration(days: 1));
    }

    while (true) {
      if (_isDayTrained(checkDate)) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    return streak;
  }
}