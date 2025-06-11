import 'package:flutter/widgets.dart';

class FormTextFieldModel {
  final TextEditingController controller;
  final String hintText;
  final String label;
  final IconData icon;

  FormTextFieldModel({
    required this.controller,
    required this.hintText,
    required this.label,
    required this.icon,
  });
}
