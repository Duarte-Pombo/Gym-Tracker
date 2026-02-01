import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class RoutineSetupPage extends StatefulWidget {
  const RoutineSetupPage({super.key});

  @override
  State<RoutineSetupPage> createState() => _RoutineSetupPageState();
}

class _RoutineSetupPageState extends State<RoutineSetupPage> with SingleTickerProviderStateMixin {
  String _selectedSplit = 'PPL';
  List<String> _currentRoutine = ['Push', 'Pull', 'Legs', 'Rest'];

  final List<String> _availableBlocks = [
    'Upper',
    'Lower',
    'Push',
    'Pull',
    'Legs',
    'Chest',
    'Back',
    'Arms',
    'Shoulders',
    'Cardio',
    'Full Body',
    'Rest'
  ];

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
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
              // Custom App Bar
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 3,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      "ROUTINE",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeader("CHOOSE A PRESET"),
                          const SizedBox(height: 15),

                          _buildPresetCard(
                            title: "Push Pull Legs",
                            subtitle: "4 Day Cycle",
                            description: "Push • Pull • Legs • Rest",
                            value: "PPL",
                            routine: ['Push', 'Pull', 'Legs', 'Rest'],
                            icon: Icons.fitness_center,
                          ),

                          const SizedBox(height: 12),

                          _buildPresetCard(
                            title: "Upper Lower",
                            subtitle: "3 Day Cycle",
                            description: "Upper • Lower • Rest",
                            value: "UL",
                            routine: ['Upper', 'Lower', 'Rest'],
                            icon: Icons.accessibility_new,
                          ),

                          const SizedBox(height: 12),

                          _buildPresetCard(
                            title: "Arnold Split",
                            subtitle: "4 Day Cycle",
                            description: "Chest/Back • Arms/Delts • Legs • Rest",
                            value: "Arnold",
                            routine: ['Chest/Back', 'Arms/Delts', 'Legs', 'Rest'],
                            icon: Icons.sports_gymnastics,
                          ),

                          const SizedBox(height: 12),

                          _buildPresetCard(
                            title: "Custom Split",
                            subtitle: "Your Choice",
                            description: "Build your own sequence",
                            value: "Custom",
                            routine: [],
                            icon: Icons.tune,
                          ),

                          if (_selectedSplit == 'Custom') ...[
                            const SizedBox(height: 30),
                            _buildHeader("BUILD YOUR CYCLE"),
                            const SizedBox(height: 10),
                            Text(
                              "Tap to add blocks to your routine",
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 20),

                            _buildBlockSelector(),

                            const SizedBox(height: 25),

                            _buildRoutinePreview(),
                          ],

                          const SizedBox(height: 40),
                          _buildSaveButton(),
                          const SizedBox(height: 30),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.5,
        color: Colors.white54,
      ),
    );
  }

  Widget _buildPresetCard({
    required String title,
    required String subtitle,
    required String description,
    required String value,
    required List<String> routine,
    required IconData icon,
  }) {
    bool isSelected = _selectedSplit == value;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedSplit = value;
          if (value != 'Custom') {
            _currentRoutine = List.from(routine);
          } else {
            _currentRoutine = [];
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).primaryColor.withOpacity(0.2),
              Theme.of(context).primaryColor.withOpacity(0.1),
            ],
          )
              : LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF2C2927),
              const Color(0xFF2C2927).withOpacity(0.6),
            ],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).primaryColor
                : Colors.white.withOpacity(0.05),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: Theme.of(context).primaryColor.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              )
            else
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected
                    ? Theme.of(context).primaryColor.withOpacity(0.2)
                    : Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isSelected
                    ? Theme.of(context).primaryColor
                    : Colors.white.withOpacity(0.6),
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: isSelected ? Colors.white : Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Theme.of(context).primaryColor.withOpacity(0.2)
                              : Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? Theme.of(context).primaryColor
                                : Colors.white54,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: Theme.of(context).primaryColor,
                size: 24,
              )
            else
              Icon(
                Icons.circle_outlined,
                color: Colors.white.withOpacity(0.2),
                size: 24,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBlockSelector() {
    return Wrap(
      spacing: 10.0,
      runSpacing: 10.0,
      children: _availableBlocks.map((block) {
        bool isRest = block == 'Rest';
        return ActionChip(
          label: Text(
            block,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          backgroundColor: isRest
              ? Colors.greenAccent.withOpacity(0.1)
              : const Color(0xFF2C2927),
          side: BorderSide(
            color: isRest
                ? Colors.greenAccent.withOpacity(0.5)
                : Theme.of(context).primaryColor.withOpacity(0.3),
            width: 1.5,
          ),
          labelStyle: TextStyle(
            color: isRest ? Colors.greenAccent : Colors.white,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          onPressed: () {
            setState(() {
              _currentRoutine.add(block);
            });
          },
        );
      }).toList(),
    );
  }

  Widget _buildRoutinePreview() {
    return Container(
      padding: const EdgeInsets.all(20),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.list_alt,
                  color: Theme.of(context).primaryColor,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                "YOUR ROUTINE",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: Colors.white54,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _currentRoutine.isEmpty
              ? Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Column(
                children: [
                  Icon(
                    Icons.playlist_add,
                    size: 40,
                    color: Colors.grey[700],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "No blocks added yet",
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          )
              : ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _currentRoutine.length,
            onReorder: (oldIndex, newIndex) {
              setState(() {
                if (oldIndex < newIndex) newIndex -= 1;
                final item = _currentRoutine.removeAt(oldIndex);
                _currentRoutine.insert(newIndex, item);
              });
            },
            itemBuilder: (context, i) {
              bool isRest = _currentRoutine[i] == 'Rest';
              return Container(
                key: ValueKey('item_$i'),
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: isRest
                      ? Colors.greenAccent.withOpacity(0.05)
                      : Colors.white.withOpacity(0.03),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isRest
                        ? Colors.greenAccent.withOpacity(0.2)
                        : Colors.white.withOpacity(0.05),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: isRest
                            ? Colors.greenAccent.withOpacity(0.2)
                            : Theme.of(context).primaryColor.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          "${i + 1}",
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                            color: isRest
                                ? Colors.greenAccent
                                : Theme.of(context).primaryColor,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        _currentRoutine[i],
                        style: TextStyle(
                          color: isRest ? Colors.greenAccent : Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.drag_indicator,
                      color: Colors.grey[700],
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(
                        Icons.remove_circle,
                        color: Colors.redAccent,
                      ),
                      iconSize: 22,
                      onPressed: () {
                        setState(() {
                          _currentRoutine.removeAt(i);
                        });
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: () {
          if (_currentRoutine.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text("Please add at least one day to the routine"),
                backgroundColor: Colors.redAccent,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
            return;
          }

          var box = Hive.box('settingsBox');
          box.put('currentRoutine', _currentRoutine);
          box.put('anchorDate', DateTime.now());

          Navigator.pop(context);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text("Routine saved! Cycle starts today."),
              backgroundColor: Theme.of(context).primaryColor,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.check_circle, size: 22),
            SizedBox(width: 12),
            Text(
              "SAVE ROUTINE",
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}