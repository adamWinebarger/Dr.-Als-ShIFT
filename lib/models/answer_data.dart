//import 'dart:js_interop';

import 'package:questionmakerteacher/models/questionnaire.dart';

import '../data/answer_map.dart';

Map<String, Answers> answerSelection = {
  "Not at All" : Answers.notAtAll,
  "Sometimes" : Answers.sometimes,
  "A Lot" : Answers.alot,
  "Always" : Answers.always
};

class AnswerValues {
  AnswerValues(this.answer, this.value);

  final Answers answer;
  int value;

  bool answersMatch(Answers answer) => this.answer == answer;
  bool namesMatch(String name) => answer.name == name;
  bool answerValuesMatch(AnswerValues av) => answer == av.answer;

  void increment() {
    value++;
  }

  void incrementBy(int inc) {
    value += inc;
  }

  void setValue(int set) {
    value = set;
  }
}

/*
* So essentially, a few things need to happen in the process here when bringing in data
* from the Answers subcollection within a given Patient's document.
*
* First, it needs to do a query for Answers and only pull back the Documents within Answers that
* fall within the Date range determined by the query (Default will be last 7 Days but we will have options
* within there for others.
*
* Secondly, once we've grabbed the requsite Answers docs from the Collection, we'll
* turn each Document that we've grabbed from Answers into a Questionnaire (gets us
* using that class again anyways).
*
* Then for each question within our Questionnaire object, we'll need to check if it
* already has a corresponding _AnswerData object (would be good to have a list for these),
* and if not create one.
*
* In any case, we will need to increment the corresponding answer based on how it was answered in the questionnaire
*
* With that info, we should be able to make a simple List of our _AnswerData class and have that be usable for these
* infographics.
*/

//So _AnswerData should essentially model the Answers sub-document for a given Patient
//in our firestore database. But given the fact that... actually, no, shit, this needs a rewrite
class AnswerData {
  AnswerData.withMap(this.question, this.answers);

  final String question;
  List<AnswerValues> answers = [];

  AnswerData(this.question) {
    for (var key in AnswerMap.keys) {
      answers.add(AnswerValues(key, 0));
    }
  }

  AnswerData.withStringSelection(this.question, String selection) {
    Answers? a = answerSelection[selection];

    if (a != null) {
      if (answers.contains(a)) {
        //print("In with String Selection. Question: ${this.question}, Selection: $selection");
        print(answers.where((element) => false));
      } else {
        //print("In with String Selection. Question: ${this.question}, Selection: $selection");
        answers.add(AnswerValues(answerSelection[selection]!, 1)); //Adds our specified enum value and increments it by 1
      }
    }
  }

  void add1(dynamic which) {
    //print("Which = $which");
    //answers.firstWhere((element) => element.answer.name == which.toString()).value++;
    for (final answer in answers) {
      if (answer.answer.name == which.toString()) {
        answer.value++;
      }
    }
  }

  void _addAnswerToData(String response) {
    if (answers.contains(response)) {
      //print(answers.where((element) => false));
      print("Answer didn't contain $response");

    } else {
      //print("Adding answer $response to the thing");
      answers.add(AnswerValues(answerSelection[response]!, 1)); //Adds our specified enum value and increments it by 1
    }
  }

  //Since we're lazy, we essentially want == to compare question values in order to
  //check if a question is already in our list. Or something.
  bool questionsMatch(String question) {
    return this.question == question;
  }

//We'll likely need a function to convert the answer data...
//fuck, so we need some sort of constructor here that will essnetially

}