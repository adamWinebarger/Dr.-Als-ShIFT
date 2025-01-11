import 'package:flutter/material.dart';

enum ParentOrTeacher {
  parent,
  teacher
}

class Answerer {
    Answerer({
      required this.firstName,
      required this.lastName,
      required this.parentOrTeacher
    });

    final String firstName, lastName;
    final ParentOrTeacher parentOrTeacher;

    factory Answerer.fromJSON(Map<String, dynamic> json) =>
        Answerer(
            firstName: json['firstName'],
            lastName: json['lastName'],
            parentOrTeacher: ParentOrTeacher.values.firstWhere((element) =>
              element.toString() == "ParentOrTeacher.${json['parentOrTeacher']}")
        );
}