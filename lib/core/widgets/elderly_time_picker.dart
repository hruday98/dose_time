import 'package:flutter/material.dart';

/// ElderlyTimePicker is an accessible time picker widget designed for elderly users
class ElderlyTimePicker extends StatefulWidget {
  final String label;
  final TimeOfDay? initialTime;
  final ValueChanged<TimeOfDay>? onTimeChanged;
  final String? Function(TimeOfDay?)? validator;

  const ElderlyTimePicker({
    Key? key,
    required this.label,
    this.initialTime,
    this.onTimeChanged,
    this.validator,
  }) : super(key: key);

  @override
  State<ElderlyTimePicker> createState() => _ElderlyTimePickerState();
}

class _ElderlyTimePickerState extends State<ElderlyTimePicker> {
  late TimeOfDay _selectedTime;
  late TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    _selectedTime = widget.initialTime ?? TimeOfDay.now();
    _textController = TextEditingController(
      text: _formatTime(_selectedTime),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  String _formatTime(TimeOfDay time) {
    final hours = time.hour.toString().padLeft(2, '0');
    final minutes = time.minute.toString().padLeft(2, '0');
    return '$hours:$minutes';
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            timePickerTheme: TimePickerThemeData(
              hourMinuteTextStyle: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              dayPeriodTextStyle: const TextStyle(
                fontSize: 18,
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
        _textController.text = _formatTime(_selectedTime);
      });
      widget.onTimeChanged?.call(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _textController,
          readOnly: true,
          validator: widget.validator,
          onTap: () => _selectTime(context),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            hintText: 'HH:mm',
            suffixIcon: IconButton(
              icon: const Icon(Icons.access_time, size: 28),
              onPressed: () => _selectTime(context),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                color: Colors.grey,
                width: 2,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: Colors.grey[300]!,
                width: 2,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                color: Colors.blue,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                color: Colors.red,
                width: 2,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
