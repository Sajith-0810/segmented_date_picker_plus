import 'package:flutter/material.dart';
import 'package:segmented_date_picker_plus/segmented_date_picker_plus.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Date Picker Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.light,
        ),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
      ),
      themeMode: ThemeMode.light,
      home: const PickerDemoScreen(),
    );
  }
}

class PickerDemoScreen extends StatefulWidget {
  const PickerDemoScreen({super.key});

  @override
  State<PickerDemoScreen> createState() => _PickerDemoScreenState();
}

class _PickerDemoScreenState extends State<PickerDemoScreen> {
  DateTime? _selectedDate;

  Future<void> _pickDate() async {
    final DateTime? picked = await showSegmentedDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      // Optional: Customizing colors. Remove this to use the default adaptive theme.
      pickerColors: const SegmentedPickerColors(accent: Colors.deepPurple),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Compact Date Picker')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _selectedDate == null
                  ? 'No date selected'
                  : 'Selected: ${_selectedDate?.year}-${_selectedDate?.month.toString().padLeft(2, '0')}-${_selectedDate?.day.toString().padLeft(2, '0')}',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _pickDate,
              child: const Text('Pick a Date'),
            ),
          ],
        ),
      ),
    );
  }
}
