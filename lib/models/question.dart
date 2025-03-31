

import 'package:questionmakerteacher/models/answer_data.dart';
import 'package:questionmakerteacher/models/questionnaire.dart';

class Question {

  final String question;
  final bool isReverseScored;

  Question(this.question, this.isReverseScored);

  factory Question.fromDynamic(dynamic item) {
    String question;
    bool isReverseScored;

    if (item is Map<String, dynamic>) {
      if (item.containsKey("question")) {
        question = item["question"].toString();
      } else {
        question = "";
      }

      if (item.containsKey("isReverseScoring")) {
        isReverseScored = item["isReverseScoring"] as bool;
      } else {
        isReverseScored = false;
      }
      return Question(question, isReverseScored);
    } else {
      return Question(item.toString() ?? "", false);
    }
  }
}

class Answer extends Question {

  final Answers answer;
  final int points;

  Answer(Question question, this.answer, this.points) : super(question.question, question.isReverseScored);

  Map<String, dynamic> toJson() {
    print("In toJSON");
    return {
      "question" : this.question,
      "answer" : this.answer.name,
      "isReverseScoring" : this.isReverseScored,
      "points" : this.points
    };
  }

  factory Answer.fromDynamic(Map<String, dynamic> item) {
    String question;
    bool isReverseScored;
    Answers answer;

    if (!item.containsKey("question")) {
      question = item.keys.first;
      answer = Answers.values.firstWhere((e) => e.toString() == item[question],
        orElse: () => Answers.notAtAll);

      final points = answer.index;



      return Answer(Question(question, false), answer, points);
    } else {
      question = item["question"].toString();
      isReverseScored = item.containsKey("isReversedScoring") ? item["isReverseScoring"] as bool : false;
      answer = Answers.values.firstWhere((e) => e.toString() == item["answer"],
        orElse: () => Answers.notAtAll);

      int points = item.containsKey("points") ? item["points"] as int : answer.index;

      return Answer(Question(question, isReverseScored), answer, points);
    }
  }

}