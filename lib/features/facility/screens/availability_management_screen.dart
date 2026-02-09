import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/app_auth_provider.dart';
import '../../../core/providers/app_facility_provider.dart';
import '../../../core/theme/app_theme.dart';

class AvailabilityManagementScreen extends StatefulWidget {
  final String facilityId;
  
  const AvailabilityManagementScreen({
    super.key,
    required this.facilityId,
  });

  @override
  State<AvailabilityManagementScreen> createState() => _AvailabilityManagementScreenState();
}

class _AvailabilityManagementScreenState extends State<AvailabilityManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Operating hours for each day
  final Map<int, DaySchedule> _schedules = {};
  
  // Blocked dates
  final List<BlockedDate> _blockedDates = [];
  
  // Special rates
  final List<SpecialRate> _specialRates = [];

  bool _isLoading = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initializeSchedules();
    _loadCurrentAvailability();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _initializeSchedules() {
    for (int i = 0; i < 7; i++) {
      _schedules[i] = DaySchedule(
        dayOfWeek: i,
        isOpen: i != 0, // Closed on Sunday by default
        openTime: const TimeOfDay(hour: 7, minute: 0),
        closeTime: const TimeOfDay(hour: 22, minute: 0),
      );
    }
  }

  Future<void> _loadCurrentAvailability() async {
    setState(() => _isLoading = true);
    
    try {
      // Load existing availability from Firestore
      // This would be implemented with FacilityProvider
    } catch (e) {
      debugPrint('Error loading availability: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveAvailability() async {
    setState(() => _isLoading = true);
    
    try {
      final facilityProvider = context.read<AppFacilityProvider>();
      
      // Convert schedules to Firestore format
      final availabilityData = {
        'recurringSchedule': _schedules.map((day, schedule) => MapEntry(
          day.toString(),
          {
            'isOpen': schedule.isOpen,
            'openTime': '${schedule.openTime.hour.toString().padLeft(2, '0')}:${schedule.openTime.minute.toString().padLeft(2, '0')}',
            'closeTime': '${schedule.closeTime.hour.toString().padLeft(2, '0')}:${schedule.closeTime.minute.toString().padLeft(2, '0')}',
          },
        )),
        'blockedDates': _blockedDates.map((d) => {
          {
            'date': d.date.toIso8601String(),
            'reason': d.reason,
          }
        }).toList(),
        'specialRates': _specialRates.map((r) => {
           {
            'date': r.date.toIso8601String(),
            'startTime': '${r.startTime.hour.toString().padLeft(2, '0')}:${r.startTime.minute.toString().padLeft(2, '0')}',
            'endTime': '${r.endTime.hour.toString().padLeft(2, '0')}:${r.endTime.minute.toString().padLeft(2, '0')}',
            'rate': r.rate,
            'reason': r.reason,
          }
        }).toList(),
      };
      
      await facilityProvider.updateFacilityAvailability(
        widget.facilityId,
        availabilityData,
      );
      
      setState(() => _hasChanges = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Disponibilités mises à jour'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gérer les disponibilités'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Horaires'),
            Tab(text: 'Indisponibilités'),
            Tab(text: 'Tarifs spéciaux'),
          ],
        ),
        actions: [
          if (_hasChanges)
            TextButton.icon(
              onPressed: _isLoading ? null : _saveAvailability,
              icon: _isLoading 
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save),
              label: const Text('Sauvegarder'),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildScheduleTab(),
                _buildBlockedDatesTab(),
                _buildSpecialRatesTab(),
              ],
            ),
    );
  }

  Widget _buildScheduleTab() {
    final dayNames = ['Dimanche', 'Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi'];
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 7,
      itemBuilder: (context, index) {
        final schedule = _schedules[index]!;
        
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      dayNames[index],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Switch(
                      value: schedule.isOpen,
                      onChanged: (value) {
                        setState(() {
                          _schedules[index] = schedule.copyWith(isOpen: value);
                          _hasChanges = true;
                        });
                      },
                    ),
                  ],
                ),
                if (schedule.isOpen) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _TimeSelector(
                          label: 'Ouverture',
                          time: schedule.openTime,
                          onChanged: (time) {
                            setState(() {
                              _schedules[index] = schedule.copyWith(openTime: time);
                              _hasChanges = true;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _TimeSelector(
                          label: 'Fermeture',
                          time: schedule.closeTime,
                          onChanged: (time) {
                            setState(() {
                              _schedules[index] = schedule.copyWith(closeTime: time);
                              _hasChanges = true;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ] else
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Fermé',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBlockedDatesTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            onPressed: _addBlockedDate,
            icon: const Icon(Icons.add),
            label: const Text('Ajouter une indisponibilité'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
        ),
        Expanded(
          child: _blockedDates.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.event_available,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Aucune indisponibilité planifiée',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _blockedDates.length,
                  itemBuilder: (context, index) {
                    final blocked = _blockedDates[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.red.withOpacity(0.1),
                          child: const Icon(Icons.block, color: Colors.red),
                        ),
                        title: Text(_formatDate(blocked.date)),
                        subtitle: Text(blocked.reason),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () {
                            setState(() {
                              _blockedDates.removeAt(index);
                              _hasChanges = true;
                            });
                          },
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildSpecialRatesTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            onPressed: _addSpecialRate,
            icon: const Icon(Icons.add),
            label: const Text('Ajouter un tarif spécial'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
        ),
        Expanded(
          child: _specialRates.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.euro,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Aucun tarif spécial défini',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Ajoutez des tarifs pour des événements\nou périodes spéciales',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _specialRates.length,
                  itemBuilder: (context, index) {
                    final rate = _specialRates[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.purple.withOpacity(0.1),
                          child: const Icon(Icons.euro, color: Colors.purple),
                        ),
                        title: Text('${rate.rate.toStringAsFixed(0)}€/h'),
                        subtitle: Text(
                          '${_formatDate(rate.date)} • ${_formatTime(rate.startTime)} - ${_formatTime(rate.endTime)}\n${rate.reason}',
                        ),
                        isThreeLine: true,
                        trailing: IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () {
                            setState(() {
                              _specialRates.removeAt(index);
                              _hasChanges = true;
                            });
                          },
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _addBlockedDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (date == null) return;
    
    if (!mounted) return;
    
    final reasonController = TextEditingController();
    
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Raison de l\'indisponibilité'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(
            hintText: 'Ex: Maintenance, Événement privé...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, reasonController.text),
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );
    
    if (result != null) {
      setState(() {
        _blockedDates.add(BlockedDate(
          date: date,
          reason: result.isNotEmpty ? result : 'Indisponible',
        ));
        _hasChanges = true;
      });
    }
  }

  void _addSpecialRate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (date == null || !mounted) return;
    
    final rateController = TextEditingController();
    final reasonController = TextEditingController();
    TimeOfDay startTime = const TimeOfDay(hour: 9, minute: 0);
    TimeOfDay endTime = const TimeOfDay(hour: 21, minute: 0);
    
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Tarif spécial'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: rateController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Tarif horaire',
                    suffixText: '€/h',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _TimeSelector(
                        label: 'Début',
                        time: startTime,
                        onChanged: (time) {
                          setDialogState(() => startTime = time);
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _TimeSelector(
                        label: 'Fin',
                        time: endTime,
                        onChanged: (time) {
                          setDialogState(() => endTime = time);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: reasonController,
                  decoration: const InputDecoration(
                    labelText: 'Raison (optionnel)',
                    hintText: 'Ex: Jour férié, Événement...',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                final rate = double.tryParse(rateController.text);
                if (rate == null || rate <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Veuillez entrer un tarif valide')),
                  );
                  return;
                }
                Navigator.pop(context, {
                  'rate': rate,
                  'startTime': startTime,
                  'endTime': endTime,
                  'reason': reasonController.text,
                });
              },
              child: const Text('Ajouter'),
            ),
          ],
        ),
      ),
    );
    
    if (result != null) {
      setState(() {
        _specialRates.add(SpecialRate(
          date: date,
          startTime: result['startTime'],
          endTime: result['endTime'],
          rate: result['rate'],
          reason: result['reason'] ?? '',
        ));
        _hasChanges = true;
      });
    }
  }

  String _formatDate(DateTime date) {
    final months = [
      'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
      'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}

class _TimeSelector extends StatelessWidget {
  final String label;
  final TimeOfDay time;
  final Function(TimeOfDay) onChanged;

  const _TimeSelector({
    required this.label,
    required this.time,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        InkWell(
          onTap: () async {
            final selected = await showTimePicker(
              context: context,
              initialTime: time,
              builder: (context, child) {
                return MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    alwaysUse24HourFormat: true,
                  ),
                  child: child!,
                );
              },
            );
            if (selected != null) {
              onChanged(selected);
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
                  style: const TextStyle(fontSize: 16),
                ),
                Icon(Icons.access_time, size: 20, color: Colors.grey[600]),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class DaySchedule {
  final int dayOfWeek;
  final bool isOpen;
  final TimeOfDay openTime;
  final TimeOfDay closeTime;

  DaySchedule({
    required this.dayOfWeek,
    required this.isOpen,
    required this.openTime,
    required this.closeTime,
  });

  DaySchedule copyWith({
    int? dayOfWeek,
    bool? isOpen,
    TimeOfDay? openTime,
    TimeOfDay? closeTime,
  }) {
    return DaySchedule(
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      isOpen: isOpen ?? this.isOpen,
      openTime: openTime ?? this.openTime,
      closeTime: closeTime ?? this.closeTime,
    );
  }
}

class BlockedDate {
  final DateTime date;
  final String reason;

  BlockedDate({
    required this.date,
    required this.reason,
  });
}

class SpecialRate {
  final DateTime date;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final double rate;
  final String reason;

  SpecialRate({
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.rate,
    required this.reason,
  });
}
