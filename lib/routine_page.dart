import 'package:flutter/material.dart';

class RoutineSetupPage extends StatefulWidget {
  const RoutineSetupPage({super.key});

  @override
  State<RoutineSetupPage> createState() => _RoutineSetupPageState();
}

class _RoutineSetupPageState extends State<RoutineSetupPage> {
  // The selected split type
  String _selectedSplit = 'PPL'; // Default

  // The actual cycle of days.
  // We use this List to determine the sequence.
  List<String> _currentRoutine = ['Push', 'Pull', 'Legs', 'Rest'];

  // Available tags for the Custom builder
  final List<String> _availableBlocks = [
    'Upper', 'Lower', 'Push', 'Pull', 'Legs',
    'Chest', 'Back', 'Arms', 'Shoulders',
    'Cardio', 'Full Body', 'Rest'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Set Workout Routine"),
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader("Choose a Preset"),

              _buildRadioTile(
                title: "Push Pull Legs",
                subtitle: "4 Day Cycle: Push, Pull, Legs, Rest",
                value: "PPL",
                routine: ['Push', 'Pull', 'Legs', 'Rest'],
              ),

              _buildRadioTile(
                title: "Upper Lower",
                subtitle: "3 Day Cycle: Upper, Lower, Rest",
                value: "UL",
                routine: ['Upper', 'Lower', 'Rest'],
              ),

              _buildRadioTile(
                title: "Arnold Split",
                subtitle: "Chest/Back, Shoulders/Arms, Legs, Rest",
                value: "Arnold",
                routine: ['Chest/Back', 'Arms/Delts', 'Legs', 'Rest'],
              ),

              _buildRadioTile(
                title: "Custom Split",
                subtitle: "Build your own block sequence",
                value: "Custom",
                routine: [],
              ),

              const Divider(height: 40, color: Colors.white24),

              // CUSTOM BUILDER UI
              if (_selectedSplit == 'Custom') ...[
                _buildHeader("Build Your Cycle"),
                const Text(
                  "Tap tags to add them to your rotation loop.",
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
                const SizedBox(height: 15),

                Wrap(
                  spacing: 8.0,
                  runSpacing: 8.0,
                  children: _availableBlocks.map((block) {
                    return ActionChip(
                      label: Text(block),
                      backgroundColor: block == 'Rest'
                          ? Colors.green.withOpacity(0.2)
                          : Theme.of(context).colorScheme.surface,
                      side: BorderSide(
                          color: block == 'Rest'
                              ? Colors.green
                              : Theme.of(context).primaryColor.withOpacity(0.5)
                      ),
                      onPressed: () {
                        setState(() {
                          _currentRoutine.add(block);
                        });
                      },
                    );
                  }).toList(),
                ),

                const SizedBox(height: 20),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: _currentRoutine.isEmpty
                      ? const Center(child: Text("Your routine is empty"))
                      : ReorderableListView(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    onReorder: (oldIndex, newIndex) {
                      setState(() {
                        if (oldIndex < newIndex) {
                          newIndex -= 1;
                        }
                        final String item = _currentRoutine.removeAt(oldIndex);
                        _currentRoutine.insert(newIndex, item);
                      });
                    },
                    children: [
                      for (int i = 0; i < _currentRoutine.length; i++)
                        ListTile(
                          key: ValueKey('item_$i'),
                          title: Text(
                            "${i + 1}. ${_currentRoutine[i]}",
                            style: TextStyle(
                                color: _currentRoutine[i] == 'Rest'
                                    ? Colors.greenAccent
                                    : Colors.white
                            ),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent),
                            onPressed: () {
                              setState(() {
                                _currentRoutine.removeAt(i);
                              });
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              ],

              // --- CHANGED: SAVE BUTTON IS NOW HERE IN THE SCROLL VIEW ---
              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton.icon(
                  onPressed: () {
                    // TODO: Save this to local storage (Hive)
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Routine set: ${_currentRoutine.join(" - ")}"))
                    );
                  },
                  icon: const Icon(Icons.check),
                  label: const Text("SAVE ROUTINE"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 5,
                  ),
                ),
              ),
              // Add extra padding at the very bottom so it doesn't touch the screen edge
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
      // No FloatingActionButton
    );
  }

  // Helper for Headers
  Widget _buildHeader(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15.0),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
          color: Colors.grey,
        ),
      ),
    );
  }

  // Helper for Radio Tiles
  Widget _buildRadioTile({
    required String title,
    required String subtitle,
    required String value,
    required List<String> routine,
  }) {
    return RadioListTile<String>(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      value: value,
      groupValue: _selectedSplit,
      activeColor: Theme.of(context).primaryColor,
      contentPadding: EdgeInsets.zero,
      onChanged: (val) {
        setState(() {
          _selectedSplit = val!;
          if (val != 'Custom') {
            _currentRoutine = List.from(routine);
          } else {
            // When switching to custom, we can either clear it or keep the last one.
            // Let's clear it to avoid confusion, or set a default base.
            _currentRoutine = [];
          }
        });
      },
    );
  }
}