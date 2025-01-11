import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class Patient {
  Patient({
    required this.lastName,
    required this.firstName,
    required this.patientCode,
    required this.parentQuestions,
    required this.teacherQuestions,
    required this.teacherCanViewParentAnswers
  });

  List<dynamic> parentQuestions = [], teacherQuestions = [];
  String path = '';
  final String lastName, firstName, patientCode;
  final bool teacherCanViewParentAnswers;

  factory Patient.fromJson(Map<String, dynamic> json) =>
      Patient(lastName: json['lastName'],
        firstName: json['firstName'],
        patientCode: json['patientCode'],
        parentQuestions: json['parentQuestions'],
        teacherQuestions: json['teacherQuestions'],
        teacherCanViewParentAnswers: json['teacherCanViewParentAnswers']
      );

  factory Patient.fromDocumentSnapshot({required DocumentSnapshot<Map<String, dynamic>> doc}) {
    return Patient(
      lastName: doc['lastName'],
      firstName: doc['firstName'],
      patientCode: doc['patientCode'],
      parentQuestions: doc['parentQuestions'],
      teacherQuestions: doc['teacherQuestions'],
      teacherCanViewParentAnswers: doc['teacherCanViewParentAnswers']
    );
  }
}