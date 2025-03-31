import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:questionmakerteacher/models/answer_data.dart';
import 'package:questionmakerteacher/models/question.dart';
import 'package:questionmakerteacher/models/questionnaire.dart';
import 'answerer.dart';

class Report {
  Report({
    required this.answers,
    required this.timestamp,
    required this.lastName,
    required this.firstName,
    required this.timeOfDay,
    required this.parentOrTeacher,
    required this.pointsEarned,
    required this.pointsTotal
  });

  //So we need to convert our Report class to run
  final List<Answer> answers;
  final DateTime timestamp;
  final String lastName, firstName, timeOfDay;
  final ParentOrTeacher parentOrTeacher;
  final int pointsEarned, pointsTotal;

  factory Report.fromJSON(Map<String, dynamic> json) {

    //So this would kinda sorta be our legacy report. Answerer. But here we need Answers to
    //now be a List<Map<String, K>> or something along those lines. Then for Answers, each
    //thing would be a templated Map<String, K> with the question, the answer, the points value, and whether
    //the thing is reverseScored I guess, and then the number of points the answer was worth.
    //
    //So how the hell should we do this? List of type answers then converted into our List<Map... etc.?
    //
    //Sure. Just remembered, this is extraction from the Document/JSON

    List<Answer> answerList = [];

    //Legacy Document catch. In this case, we're dealing with a map where the key is the question,
    //value is the answer
    if (json['Answers'] is Map<String, dynamic>) {

      for (String key in json['Answers'].keys) {
        Answers answer = Answers.values.firstWhere((e) => e.name == json['Answers'][key]
          , orElse: () => Answers.notAtAll
        );

        //Assume that legacy queestions are not reverseScored and that always will be the high value
        answerList.add(Answer(Question(key, false), answer, answer.index));

      }

    } else if (json['Answers'] is List) {
      //So this will be our standard way of working through it.
      for (Map<String, dynamic> entry in json['Answers']) {
        answerList.add(Answer.fromDynamic(entry));
      }
    }


    return Report(
        firstName: json['answererFirstName'],
        lastName: json['answererLastName'],
        timestamp: (json['Timestamp'] as Timestamp).toDate(),
        timeOfDay: json['timeOfDay'].toString(),
        parentOrTeacher: ParentOrTeacher.values.firstWhere((element) =>
        element.name == json['parentOrTeacher']),
        answers: answerList,
        pointsTotal: answerList.length * 3,
        pointsEarned: answerList.fold(0, (int sum, answer) => sum + answer.points)
    );
  }
}