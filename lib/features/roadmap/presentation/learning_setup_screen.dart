import 'package:flutter/material.dart';
import '../../roadmap/data/roadmap_local_service.dart';
import '../../plan_draft/presentation/day_plan_editor_screen.dart';

class LearningSetupScreen extends StatefulWidget {
  final String skill;
  final Map<String, dynamic> roadmap;

  const LearningSetupScreen({
    super.key,
    required this.skill,
    required this.roadmap,
  });

  @override
  State<LearningSetupScreen> createState() => _LearningSetupScreenState();
}

class _LearningSetupScreenState extends State<LearningSetupScreen> {
  DateTime _startDate = DateTime.now();
  bool _isLoading = false;
  final TextEditingController _dailyHoursController = TextEditingController();

  @override
  void dispose() {
    _dailyHoursController.dispose();
    super.dispose();
  }

  Future<void> _submitConfig() async {
    print("Initializing learning state");
    setState(() => _isLoading = true);

    final String startDateStr = _startDate.toIso8601String().split('T')[0];

    try {
      // 1. Init Learning State
      final inputHours = int.tryParse(_dailyHoursController.text.trim());
      final dailyHours = (inputHours != null && inputHours > 0) ? inputHours : 2;
      await RoadmapLocalService.instance.initLearningState(
        widget.skill,
        startDateStr,
        dailyHours,
      );

      // 2. Set Active Skill
      await RoadmapLocalService.instance.setActiveSkill(widget.skill);

      // 3. Clear any stale plans
      await RoadmapLocalService.instance.clearPlansForSkill(widget.skill);

      print("Navigating to DayPlanEditorScreen");
      if (!mounted) return;

      // Navigate to Day Plan Editor Screen (Day 1)
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => DayPlanEditorScreen(
            skill: widget.skill,
            roadmap: widget.roadmap,
            initialDay: 1,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving configuration: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    
    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: const Text('Schedule Configuration'),
        backgroundColor: cs.primaryContainer,
        foregroundColor: cs.onPrimaryContainer,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              Icon(
                Icons.calendar_month_rounded,
                size: 72,
                color: cs.primary.withAlpha(89),
              ),
              const SizedBox(height: 20),
              Text(
                'When do you want to start?',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Select a start date so we can map out your roadmap onto a calendar.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 40),

              // Date Picker
              Card(
                elevation: 0,
                color: cs.surfaceContainerHighest,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListTile(
                  leading: const Icon(Icons.date_range),
                  title: const Text('Start Date'),
                  subtitle: Text(_startDate.toLocal().toString().split(' ')[0]),
                  trailing: TextButton(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _startDate,
                        firstDate: DateTime.now().subtract(const Duration(days: 365)),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) {
                        setState(() => _startDate = picked);
                      }
                    },
                    child: const Text('Change'),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Daily Hours Input
              Card(
                elevation: 0,
                color: cs.surfaceContainerHighest,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: TextField(
                    controller: _dailyHoursController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      icon: Icon(Icons.timer),
                      labelText: 'Daily Study Hours (Optional)',
                      hintText: 'Defaults to 2 hours',
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 48),

              // Submit Button
              FilledButton.icon(
                onPressed: _isLoading ? null : _submitConfig,
                icon: _isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.5, color: Colors.white),
                      )
                    : const Icon(Icons.check_circle_outline),
                label: Text(_isLoading ? 'Configuring...' : 'Start Learning'),
                style: FilledButton.styleFrom(
                  backgroundColor: cs.primary,
                  foregroundColor: cs.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
