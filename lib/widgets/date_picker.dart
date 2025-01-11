

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class DatePicker extends StatefulWidget {
  const DatePicker({super.key, required this.initialValue, required this.onchanged,
    required this.labelText});

  final DateTime initialValue;
  final ValueChanged<DateTime> onchanged;
  final String labelText;

  @override
  State<StatefulWidget> createState() => _DatePickerState();

}

class _DatePickerState extends State<DatePicker> {

  DateTime? _currentDateTime;
  TextEditingController _dateController = TextEditingController();

  Future<void> _selectDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _currentDateTime,
      firstDate: DateTime(2020),
      lastDate: DateTime(2050)
    );

    if (picked != null) {
      setState(() {
        _dateController.text = picked.toString().split(" ")[0];
        _currentDateTime = picked;
      });

      widget.onchanged(picked);
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    _currentDateTime = widget.initialValue;
    _dateController.text = _currentDateTime.toString().split(" ")[0];
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Padding(
      padding: EdgeInsets.all(10),
      child: TextField(
        controller: _dateController,
        decoration: InputDecoration(
          labelText: widget.labelText,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(8.0)),
            borderSide: BorderSide(
              color: Theme.of(context).primaryColor,
              width: 1
            )
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 5),
          prefixIcon: const Icon(Icons.calendar_today),
        ),
        readOnly: true,
        onTap: () {
          _selectDate();
        },
      ),
    );
  }
}