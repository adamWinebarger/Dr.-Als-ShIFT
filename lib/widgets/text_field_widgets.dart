import 'package:flutter/material.dart';

class AuthScreenTextFormField extends StatelessWidget {
  AuthScreenTextFormField({
    super.key,
    required this.validator,
    required this.onSaved,
    required this.labelText
  });

  String? Function(String? value) validator;
  void Function(String? value) onSaved;
  String labelText;

  @override
  Widget build(context) {
    return TextFormField(

    );
  }


}