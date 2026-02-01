import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'progress_gallery_page.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'routine_page.dart';
import 'calorie_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
        fontFamily: 'SF Pro Display',
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

class _GymTrackerHomeState extends State<GymTrackerHome> with TickerProviderStateMixin {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  // Database references
  final Box _settingsBox = Hive.box('settingsBox');
  final Box _workoutBox = Hive.box('workoutBox');
  final Box _calorieBox = Hive.box('calorieBox');

  // Local state
  List<String> _currentRoutine = [];
  DateTime _routineAnchorDate = DateTime.now();

  // Animations
  late AnimationController _streakAnimController;
  late Animation<double> _scaleAnimation;
  late AnimationController _fadeAnimController;
  late Animation<double> _fadeAnimation;
  late AnimationController _buttonPressController;

  @override
  void initState() {
    super.initState();
    _loadRoutineData();

    // Streak pulse animation
    _streakAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _streakAnimController, curve: Curves.easeInOut),
    );

    // Fade in animation for dashboard
    _fadeAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeAnimController, curve: Curves.easeOut),
    );
    _fadeAnimController.forward();

    // Button press animation
    _buttonPressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
  }

  @override
  void dispose() {
    _streakAnimController.dispose();
    _fadeAnimController.dispose();
    _buttonPressController.dispose();
    super.dispose();
  }

  void _loadRoutineData() {
    setState(() {
      _currentRoutine = _settingsBox.get('currentRoutine', defaultValue: <String>[])?.cast<String>() ?? [];

      // Bug fix: Properly handle DateTime from Hive
      var anchorData = _settingsBox.get('anchorDate');
      if (anchorData is DateTime) {
        _routineAnchorDate = anchorData;
      } else {
        _routineAnchorDate = DateTime.now();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF1E1C1A),
              const Color(0xFF2C2927).withOpacity(0.5),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 20),

              // App Title with subtle animation
              FadeTransition(
                opacity: _fadeAnimation,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Row(
                    children: [
                      Container(
                        width: 4,
                        height: 28,
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        "PROGRESS",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 2,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // Dashboard with staggered fade-in
              FadeTransition(
                opacity: _fadeAnimation,
                child: _buildDashboardRow(),
              ),

              const SizedBox(height: 25),

              // Calendar
              Expanded(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: _buildCalendar(),
                ),
              ),

              // Bottom Actions
              _buildBottomActions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDashboardRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: _buildStreakWidget()),
          const SizedBox(width: 15),
          _buildAccuracyWidget(),
          const SizedBox(width: 15),
          Expanded(child: _buildCalorieSummaryWidget()),
        ],
      ),
    );
  }

  Widget _buildStreakWidget() {
    int streak = _calculateStreak();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF2C2927),
            const Color(0xFF2C2927).withOpacity(0.6),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.05),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          AnimatedBuilder(
            animation: _streakAnimController,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Colors.orangeAccent.withOpacity(0.3),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: const Icon(
                    Icons.local_fire_department,
                    color: Colors.orangeAccent,
                    size: 36,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          Text(
            "$streak",
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const Text(
            "DAY STREAK",
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
              color: Colors.white54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccuracyWidget() {
    double accuracy = _calculateAccuracy();
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF2C2927),
            const Color(0xFF2C2927).withOpacity(0.6),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.05),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: CircularPercentIndicator(
        radius: 60.0,
        lineWidth: 8.0,
        animation: true,
        animationDuration: 1200,
        percent: accuracy,
        center: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "${(accuracy * 100).toStringAsFixed(0)}%",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 24.0,
                color: Colors.white,
              ),
            ),
            const Text(
              "FREQ.",
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                letterSpacing: 1,
                color: Colors.white54,
              ),
            ),
          ],
        ),
        circularStrokeCap: CircularStrokeCap.round,
        progressColor: _getAccuracyColor(accuracy),
        backgroundColor: Colors.grey[900]!,
      ),
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
        setState(() {});
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF2C2927),
              const Color(0xFF2C2927).withOpacity(0.6),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withOpacity(0.05),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.greenAccent.withOpacity(0.2),
                    Colors.transparent,
                  ],
                ),
              ),
              child: const Icon(
                Icons.restaurant,
                color: Colors.greenAccent,
                size: 36,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "$calories",
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              "/ $goal KCAL",
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 1,
                color: Colors.white54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomActions() {
    bool isLogged = _isDayTrained(DateTime.now());

    return Container(
      padding: const EdgeInsets.only(bottom: 30.0, left: 20, right: 20, top: 25),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2927),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Main Log Button
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  _buttonPressController.forward().then((_) {
                    _buttonPressController.reverse();
                  });
                  _toggleTrainingDay(DateTime.now());
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isLogged
                      ? Colors.grey[700]
                      : Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isLogged ? Icons.check_circle : Icons.fitness_center,
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      isLogged ? "WORKOUT LOGGED" : "LOG WORKOUT",
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 50,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ProgressGalleryPage(),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(
                        color: Colors.white.withOpacity(0.2),
                        width: 1.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.photo_library, size: 18),
                        SizedBox(width: 8),
                        Text(
                          "GALLERY",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 50,
                  child: OutlinedButton(
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const RoutineSetupPage(),
                        ),
                      );
                      _loadRoutineData();
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(
                        color: Colors.white.withOpacity(0.2),
                        width: 1.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.edit_calendar, size: 18),
                        SizedBox(width: 8),
                        Text(
                          "ROUTINE",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCalendar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF2C2927),
            const Color(0xFF2C2927).withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: Colors.white.withOpacity(0.05),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: TableCalendar(
        firstDay: DateTime.utc(2020, 1, 1),
        lastDay: DateTime.utc(2030, 12, 31),
        focusedDay: _focusedDay,
        calendarFormat: CalendarFormat.month,
        rowHeight: 58,
        headerStyle: const HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          titleTextStyle: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
          ),
        ),
        daysOfWeekStyle: DaysOfWeekStyle(
          weekdayStyle: TextStyle(
            color: Colors.white.withOpacity(0.6),
            fontWeight: FontWeight.w600,
            fontSize: 11,
          ),
          weekendStyle: TextStyle(
            color: Colors.white.withOpacity(0.6),
            fontWeight: FontWeight.w600,
            fontSize: 11,
          ),
        ),
        calendarStyle: const CalendarStyle(outsideDaysVisible: false),
        calendarBuilders: CalendarBuilders(
          defaultBuilder: (context, day, focusedDay) =>
              _buildCustomDayCell(day, textColor: Colors.white),
          todayBuilder: (context, day, focusedDay) =>
              _buildCustomDayCell(
                day,
                textColor: Theme.of(context).primaryColor,
                borderColor: Theme.of(context).primaryColor,
              ),
          selectedBuilder: (context, day, focusedDay) =>
              _buildCustomDayCell(
                day,
                textColor: Colors.black,
                backgroundColor: Theme.of(context).primaryColor,
              ),
        ),
        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
        onDaySelected: (selectedDay, focusedDay) {
          setState(() {
            _selectedDay = selectedDay;
            _focusedDay = focusedDay;
          });
        },
        onPageChanged: (focusedDay) {
          setState(() {
            _focusedDay = focusedDay;
          });
        },
      ),
    );
  }

  Widget _buildCustomDayCell(
      DateTime day, {
        required Color textColor,
        Color? backgroundColor,
        Color? borderColor,
      }) {
    String splitName = _getSplitForDate(day);
    bool isRestDay = splitName.toLowerCase() == 'rest';
    bool isTrained = _isDayTrained(day);

    if (isTrained && backgroundColor == null) {
      backgroundColor = Theme.of(context).primaryColor.withOpacity(0.15);
      borderColor = Theme.of(context).primaryColor.withOpacity(0.6);
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.all(3.0),
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
        border: borderColor != null
            ? Border.all(color: borderColor, width: 2)
            : null,
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${day.day}',
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
            if (splitName.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  splitName,
                  style: TextStyle(
                    color: isRestDay ? Colors.greenAccent : Colors.grey[600],
                    fontSize: 7,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.clip,
                ),
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
    final DateTime normalizedAnchor = DateTime(
      _routineAnchorDate.year,
      _routineAnchorDate.month,
      _routineAnchorDate.day,
    );
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

  int _calculateStreak() {
    DateTime checkDate = DateTime.now();
    int streak = 0;

    // Start from today if trained, otherwise yesterday
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