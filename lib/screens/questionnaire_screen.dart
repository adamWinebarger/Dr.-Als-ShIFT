import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:questionmakerteacher/models/answerer.dart';

import 'package:questionmakerteacher/models/patient.dart';
import 'package:questionmakerteacher/models/questionnaire.dart';
import 'package:questionmakerteacher/models/theme_data.dart';
import 'package:questionmakerteacher/stringextension.dart';

import '../models/answer_data.dart';

final _authenticatedUser = FirebaseAuth.instance.currentUser!;

class QuestionnaireScreen extends StatefulWidget {
  const QuestionnaireScreen({super.key, required this.patientInQuestion, required this.parentOrTeacher});

  final Patient patientInQuestion;
  final ParentOrTeacher parentOrTeacher;

  @override
  State<StatefulWidget> createState() => _QuestionnaireScreenState();
}

class _QuestionnaireScreenState extends State<QuestionnaireScreen> {

  final _formKey = GlobalKey<FormState>();
  final List<Answers> _answers = [];
  final DocumentReference _currentUserDoc = FirebaseFirestore.instance.collection("users").
    doc(_authenticatedUser.uid);
  final Map<String, dynamic> _answerMap = {};

  late Answerer _currentAnswerer;
  late List<String> _questions;

  int _count = 0;
  Answers? _selectedAnswer;
  TimeOfInteraction? _selectedTimeOfInteraction;

  List<Widget> _setupAnswerRadioButtons() {
    List<Widget> widgetList = [];

      for (final category in answerSelection.entries) {
        widgetList.add(
            ListTile(
              title: Text(
                category.key,
                style: TextStyle(
                  color: Colors.white
                ),
              ),
              leading: Radio<Answers> (
                value: category.value,
                groupValue: _selectedAnswer,
                onChanged: (Answers? value) {
                  setState(() {
                    _selectedAnswer = value;
                  });
                },
                focusColor: Colors.black,
                overlayColor: WidgetStateProperty.all<Color>(Colors.grey.shade400),
              ),
            )
        );
      widgetList.add(const SizedBox(height: 20,));
    }
    return widgetList;
  }

  void _nextPressed() {
    //print(_selectedAnswer);
    final selectedQuestionsList = widget.parentOrTeacher == ParentOrTeacher.parent ?
        widget.patientInQuestion.parentQuestions : widget.patientInQuestion.teacherQuestions;

    //print("Made it to here 1");
    if (_selectedAnswer != null) {
      _answers.add(_selectedAnswer!);
      if (_count < selectedQuestionsList.length - 1) {
        setState(() {
          ++_count;
          _selectedAnswer = null;
        });
      } else {
        print("Made it to here 2");
        _submitQuestionnaire();
      }
    }
  }

  void _backPressed() {
    if (_count > 0) {
      setState(() {
        --_count;
        _selectedAnswer = _answers.isNotEmpty ? _answers.last : null;
        _answers.removeLast();
      });
    } else {
      Navigator.of(context).pop();
    }
  }

  void _submitQuestionnaire() async {
    final selectedQuestionsList = widget.parentOrTeacher == ParentOrTeacher.parent ?
    widget.patientInQuestion.parentQuestions : widget.patientInQuestion.teacherQuestions;
    print("Made it to here 3");


    for (int i = 0; i < selectedQuestionsList.length; i++) {
      _answerMap[selectedQuestionsList[i]] = _answers[i].name;
    }

    //print(_currentAnswerer.parentOrTeacher);
    final answerDocumentPath = "${_authenticatedUser.uid} ${DateTime.now()}";
    if (_formKey.currentState!.validate()) {
      await FirebaseFirestore.instance.collection('Patients')
        .doc(widget.patientInQuestion.path).collection('Answers').doc(answerDocumentPath)
        .set({
          'Timestamp' : DateTime.now(),
          'answererLastName' : _currentAnswerer.lastName,
          'answererFirstName' : _currentAnswerer.firstName,
          'parentOrTeacher' : widget.parentOrTeacher.name,
          'Answers' : _answerMap, //It looks like we aren't using any of the info from our Questionnaire class and instead are generating this all locally... wth
          'timeOfDay' : _selectedTimeOfInteraction!.name
      });

      setState(() {
        Navigator.pop(context);
      });
    }
  }

  void _setCurrentAnswerer() async {
    final DocumentSnapshot answererDocument = await _currentUserDoc.get();
    _currentAnswerer = Answerer.fromJSON(answererDocument.data() as Map<String, dynamic>);
  }

  @override
  void initState() {
    super.initState();
    setState(() {
      _setCurrentAnswerer();
      _questions = widget.parentOrTeacher == ParentOrTeacher.parent
          ? (widget.patientInQuestion.parentQuestions)
          .map((item) => item.toString())
          .toList()
          : (widget.patientInQuestion.teacherQuestions)
          .map((item) => item.toString())
          .toList();
    });
  }

  @override
  Widget build(context) {

    //print(_currentAnswerer);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Answer Screen"),
      ),
      body: GradientContainer(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                if (_count > -1)
                  Center(
                    child: Text(
                      "Question ${_count+1}",
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                if (_count > -1)
                  SizedBox(height: MediaQuery.of(context).size.height * 0.01,),
                Center(
                  child: SizedBox(
                    height: 75,
                    child: Text(
                      (_count > -1) ?
                      _questions[_count] :
                      "Select the time of day that this questionnaire reflects:",
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                ),
                Card(
                  color: Theme.of(context).colorScheme.secondary,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 15, vertical: 25),
                    child: Column(
                      children: [
                        for (final item in _setupAnswerRadioButtons())
                          item,
                        //const SizedBox(height: 25,),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton(
                                onPressed: _backPressed,
                                child: const Text("Back")
                            ),
                            const SizedBox(width: 15,),
                            ElevatedButton(
                                onPressed: _nextPressed,
                                child: Text(
                                    _count == _questions.length - 1 ?
                                    "Submit" : "Next"
                                )
                            ),
                          ],
                        ),
                        SizedBox(height: MediaQuery.of(context).size.height * 0.2 ),
                        DropdownButtonFormField(
                          dropdownColor: Theme.of(context).colorScheme.secondary,
                          decoration: const InputDecoration(
                            label: Text(
                              "Select the time of day that this questionnaire is for:",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                //color: Colors.white
                              ),
                            ),

                          ),
                          items: [
                            for (final selection in TimeOfInteraction.values)
                              DropdownMenuItem(
                                  value: selection,
                                  child: Text(
                                    selection.name.capitalize(),
                                    style: TextStyle(
                                      color: Colors.white,
                                      //backgroundColor: Colors.white
                                    ),
                                  )
                              )
                          ] ,
                          onChanged: (value) {
                            setState(() {
                              _selectedTimeOfInteraction = value!;
                            });
                          },
                          validator: (value) {
                            if (value == null) {
                              return "You must select a time of day for this interaction";
                            }
                            return null;
                          },
                        )
                      ],
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      )
    );

  }
}