import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/user_provider.dart';
import '../../../core/providers/facility_provider.dart';
import '../../../core/providers/booking_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/models/booking_model.dart';

class BookingScreen extends StatefulWidget {
  final String facilityId;
  final String spaceId;

  const BookingScreen({super.key, required this.facilityId, required this.spaceId});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _startTime = const TimeOfDay(hour: 10, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 11, minute: 0);
  final _notesController = TextEditingController();
  bool _isLoading = false;

  DateTime get _startDateTime => DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, _startTime.hour, _startTime.minute);
  DateTime get _endDateTime => DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, _endTime.hour, _endTime.minute);
  double get _durationHours => _endDateTime.difference(_startDateTime).inMinutes / 60.0;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().add(const Duration(hours: AppConstants.minAdvanceBookingHours)),
      lastDate: DateTime.now().add(const Duration(days: AppConstants.maxAdvanceBookingDays)),
    );
    if (date != null) setState(() => _selectedDate = date);
  }

  Future<void> _selectStartTime() async {
    final time = await showTimePicker(context: context, initialTime: _startTime);
    if (time != null) setState(() => _startTime = time);
  }

  Future<void> _selectEndTime() async {
    final time = await showTimePicker(context: context, initialTime: _endTime);
    if (time != null) setState(() => _endTime = time);
  }

  Future<void> _handleBooking() async {
    setState(() => _isLoading = true);
    // Booking logic here...
    await Future.delayed(const Duration(seconds: 2));
    setState(() => _isLoading = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Réservation créée !')));
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Réserver')),
      body: Consumer<FacilityProvider>(
        builder: (context, provider, _) {
          final facility = provider.selectedFacility;
          if (facility == null) return const Center(child: CircularProgressIndicator());

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Facility card
                Card(
                  child: ListTile(
                    leading: Container(
                      width: 50, height: 50,
                      decoration: BoxDecoration(color: AppColors.surfaceVariant, borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.fitness_center),
                    ),
                    title: Text(facility.name),
                    subtitle: Text(facility.address.shortFormatted),
                  ),
                ),
                const SizedBox(height: 24),

                // Date
                Text('Date', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ListTile(
                  tileColor: AppColors.surfaceVariant,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  leading: const Icon(Icons.calendar_today, color: AppColors.primary),
                  title: Text(DateFormat('EEEE d MMMM yyyy', 'fr_FR').format(_selectedDate)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _selectDate,
                ),
                const SizedBox(height: 24),

                // Time
                Text('Horaires', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ListTile(
                        tileColor: AppColors.surfaceVariant,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        title: const Text('Début'),
                        subtitle: Text(_startTime.format(context), style: const TextStyle(fontWeight: FontWeight.bold)),
                        onTap: _selectStartTime,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ListTile(
                        tileColor: AppColors.surfaceVariant,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        title: const Text('Fin'),
                        subtitle: Text(_endTime.format(context), style: const TextStyle(fontWeight: FontWeight.bold)),
                        onTap: _selectEndTime,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Notes
                Text('Notes', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextField(controller: _notesController, maxLines: 3, decoration: const InputDecoration(hintText: 'Informations supplémentaires...')),
                const SizedBox(height: 24),

                // Price summary
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    children: [
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Durée'), Text('${_durationHours.toStringAsFixed(1)}h')]),
                      const SizedBox(height: 8),
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Tarif'), Text('${facility.hourlyRate.toInt()}€/h')]),
                      const Divider(height: 24),
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Text('Total', style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text('${(facility.hourlyRate * _durationHours * 1.15).toStringAsFixed(2)}€', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                      ]),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Submit
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleBooking,
                    child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Confirmer et payer'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
