import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:questionmakerteacher/models/question.dart';

class Patient {
  Patient({
    required this.lastName,
    required this.firstName,
    required this.patientCode,
    required this.parentQuestions,
    required this.teacherQuestions,
    required this.teacherCanViewParentAnswers
  });

  List<Question> parentQuestions = [], teacherQuestions = [];
  String path = '';
  final String lastName, firstName, patientCode;
  final bool teacherCanViewParentAnswers;

  factory Patient.fromJson(Map<String, dynamic> json) {

    List<Question> _generateQuestionList(List<dynamic> questions) {
      List<Question> questionList = [];

      if (questions.first is String) {
        //Legacy handler. In time this should never be used anymore. But here's
        return questions.map((item) => Question(item as String, false)).toList();

      } else if (questions.first is Map<String, dynamic>) {
        //This will technically be our standard case; and definitely our simplest.
        return questions.map((item) => Question.fromDynamic(item as Map<String, dynamic>)).toList();
        //Of course, I said simplest but this is definitley not going to be apparent what's going on at a glace
        //

      }

      return questionList;
    }

    List<Question> parentQuestions = _generateQuestionList(json['parentQuestions']),
      teacherQuestions = _generateQuestionList(json['teacherQuestions']);

    return Patient(lastName: json['lastName'],
        firstName: json['firstName'],
        patientCode: json['patientCode'],
        parentQuestions: parentQuestions,
        teacherQuestions: teacherQuestions,
        teacherCanViewParentAnswers: json['teacherCanViewParentAnswers']
    );
  }

  //It seems like our fromDocumentSnapshot factory doesn't get used anymore... I wonder why I even left it here
  //I'm not going to delete it until I'm sure that we definitely won't need it though.

  // factory Patient.fromDocumentSnapshot({required DocumentSnapshot<Map<String, dynamic>> doc}) {
  //
  //   //Apparently this is more like an embedded class. So our companion function needs
  //   //to be up in here to be usable in this factory
  //   List<Question> _generateQuestionList(List<dynamic> questions) {
  //     List<Question> questionList = [];
  //
  //     if (questions.first is String) {
  //       //Legacy handler. In time this should never be used anymore. But here's
  //       return questions.map((item) => Question(item as String, false)).toList();
  //
  //     } else if (questions.first is Map<String, dynamic>) {
  //       //This will technically be our standard case; and definitely our simplest.
  //       return questions.map((item) => Question.fromDynamic(item as Map<String, dynamic>)).toList();
  //       //Of course, I said simplest but this is definitley not going to be apparent what's going on at a glace
  //       //
  //
  //     }
  //
  //     return questionList;
  //   }
  //
  //   //Driver code
  //   List<Question> parentQuestions = _generateQuestionList(doc['parentQuestions']),
  //       teacherQuestions = _generateQuestionList(doc['teacherQuestions']);
  //
  //
  //
  //   return Patient(
  //     lastName: doc['lastName'],
  //     firstName: doc['firstName'],
  //     patientCode: doc['patientCode'],
  //     parentQuestions: parentQuestions,
  //     teacherQuestions: teacherQuestions,
  //     teacherCanViewParentAnswers: doc['teacherCanViewParentAnswers']
  //   );
  // }

  //Apparently this has to be embedded in the factory to be usable within the factory.
  //So this outside function might actually be useless going forward but I'm goint to leave it here
  // for now just in case
  List<Question> _generateQuestionList(List<dynamic> questions) {
    List<Question> questionList = [];

    if (questions.first is String) {
      //Legacy handler. In time this should never be used anymore. But here's
      return questions.map((item) => Question(item as String, false)).toList();

    } else if (questions.first is Map<String, dynamic>) {
      //This will technically be our standard case; and definitely our simplest.
      return questions.map((item) => Question.fromDynamic(item as Map<String, dynamic>)).toList();
      //Of course, I said simplest but this is definitley not going to be apparent what's going on at a glace
      //

    }

    return questionList;
  }
}