

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

  Answer(Question question, this.answer) : super(question.question, question.isReverseScored);

  factory Answer.fromDynamic(Map<String, dynamic> item) {
    String question;
    bool isReverseScored;
    Answers answer;

    if (!item.containsKey("question")) {
      question = item.keys.first;
      answer = Answers.values.firstWhere((e) => e.toString() == item["question"],
        orElse: () => Answers.notAtAll);

      return Answer(Question(question, false), answer);
    } else {
      question = item["question"].toString();
      isReverseScored = item.containsKey("isReversedScoring") ? item["isReverseScoring"] as bool : false;
      answer = Answers.values.firstWhere((e) => e.toString() == item["answer"],
        orElse: () => Answers.notAtAll);
      return Answer(Question(question, isReverseScored), answer);
    }
  }

}