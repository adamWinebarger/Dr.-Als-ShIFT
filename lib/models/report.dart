import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:questionmakerteacher/models/questionnaire.dart';
import 'answerer.dart';

class Report {
  Report({
    required this.answers,
    required this.timestamp,
    required this.lastName,
    required this.firstName,
    required this.timeOfDay,
    required this.parentOrTeacher
  });

  final Map<String, Answers> answers;
  final DateTime timestamp;
  final String lastName, firstName, timeOfDay;
  final ParentOrTeacher parentOrTeacher;

  factory Report.fromJSON(Map<String, dynamic> json) =>
      Report(
          firstName: json['answererFirstName'],
          lastName: json['answererLastName'],
          timestamp: (json['Timestamp'] as Timestamp).toDate(),
          timeOfDay: json['timeOfDay'].toString(),
          parentOrTeacher: ParentOrTeacher.values.firstWhere((element) =>
          element.name == json['parentOrTeacher']),
          answers: (json['Answers'] as Map<String, dynamic>).map((key, value) =>
              MapEntry(key, Answers.values.firstWhere((element) =>
                element.name == value.toString(),
                orElse: () => Answers.notAtAll
              )))
      );
}