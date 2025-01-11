import 'package:flutter/material.dart';

enum TimeOfInteraction {
  morning,
  afternoon,
  evening
}

enum Answers {
  notAtAll,
  sometimes,
  alot,
  always
}

//My Dumbass probably should have left better comments or more readable code.
//But in theory, this is more or less what's being sent up. So it'll be a map of the
//string, the answer that they answered, and then some additional data for reference
class Questionnaire {
  Questionnaire({
    required this.lastName, required this.firstName,
    required this.timeOfDay
  });

  final String lastName, firstName;
  TimeOfDay timeOfDay;
  Map<String, Answers> answers = {};

}