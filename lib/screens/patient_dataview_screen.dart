import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:questionmakerteacher/models/answerer.dart';
import 'package:questionmakerteacher/models/questionnaire.dart';
import 'package:questionmakerteacher/models/theme_data.dart';
import 'package:questionmakerteacher/stringextension.dart';
import 'package:questionmakerteacher/widgets/date_picker.dart';
import 'package:questionmakerteacher/widgets/test_widgets.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:questionmakerteacher/data/patient_test_data.dart';
import 'package:questionmakerteacher/data/answer_map.dart';
import 'package:questionmakerteacher/models/patient.dart';
import '../models/answer_data.dart';
import 'questionnaire_screen.dart';

enum _TimeOfDay {
  morning,
  afternoon,
  evening,
  all
}

enum _Lookback {
  today,
  lastWeek,
  lastMonth,
  allTime,
  specificTimeframe
}

class PatientDataView extends StatefulWidget {
  const PatientDataView({super.key, required this.patientReference,
    required this.teacherCanViewParentReports, required this.parentOrTeacher,
    required this.patientFirstName});

  final String patientReference, patientFirstName;
  final bool teacherCanViewParentReports;
  final ParentOrTeacher parentOrTeacher;

  @override
  State<StatefulWidget> createState() => _PatientDataViewState();

}

class _PatientDataViewState extends State<PatientDataView> {

  final _noAnswersWidget = const Center(child:
  Text("No data available.\n Maybe adjust your search parameters?",
    textAlign: TextAlign.center,
    style: TextStyle(color: Colors.white))
  );

  //variables that will determine what widget to display based on whether the app is fetching data.
  //whether it's found it, and should also probably handle what happens if and when it does find data
  bool _isFetchingData = false;
  int _currentQuestionNumber = 0;
  _TimeOfDay _timeOfDay = _TimeOfDay.all;
  String _selectedParentTeacherFilter = "All";
  _Lookback _currentLookbackSelection = _Lookback.today;

  List<AnswerData> _answerDataList = [];

  DateTime _fromDate = DateTime.now().subtract(const Duration(days: 7)), _toDate = DateTime.now();
  // DateTime _fromDate = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day),
  //   _toDate = DateTime.now();

  late List<AnswerData> _patientDataView;
  late String _currentQuestion;
  late final Map<String, _Lookback> _dateRangeMap = {
    "Today" : _Lookback.today,
    "Past Week" : _Lookback.lastWeek,
    "Past Month" : _Lookback.lastMonth,
    "All Time" : _Lookback.allTime,
    "Select Date Range" : _Lookback.specificTimeframe
  };

  void _nextPressed() {
    setState(() {
      //_currentQuestionNumber++;
      _currentQuestion = _answerDataList[++_currentQuestionNumber].question;
      //print(_currentQuestionNumber);
    });
  }

  void _previousPressed() {
    if (_currentQuestionNumber == 0) {
      Navigator.pop(context);
    } else {
      setState(() {
        //_currentQuestionNumber--;
        _currentQuestion = _answerDataList[--_currentQuestionNumber].question;
      });
    }
  }

  //A method for grabbing the Answers from the firebase database
  //Async method for grabbing the Answers from the firebase database
  Future<List<AnswerData>> _getAnswerDocumentsFromDatabase() async {
    //So what we need is the Answers Documents that are within the from date and the to date.
    //From there, we would want to look at the Answers subfield within, grab the question,
    //then check if the question is already in our AV list. If it is, then increment the relevant
    //enum pattern by 1; if it's not, then add the question in there and then increment the relevant
    //enum pattern by 1

    List<AnswerData> avList = [];

    final CollectionReference crList = FirebaseFirestore.instance.collection("Patients")
        .doc(widget.patientReference).collection("Answers");
    //query to look at docs within a given tim period (from and to will be adjustable)
    Query requisiteAnswersQuery = crList.where("Timestamp", isLessThanOrEqualTo: _toDate);

    if (_currentLookbackSelection != _Lookback.allTime) {
      requisiteAnswersQuery = requisiteAnswersQuery.where("Timestamp", isGreaterThanOrEqualTo: _fromDate);
    }

    if (_timeOfDay != _TimeOfDay.all) {
      //print(_timeOfDay.name);
      requisiteAnswersQuery = requisiteAnswersQuery.where("timeOfDay", isEqualTo: _timeOfDay.name.toLowerCase());
    }

    if (widget.parentOrTeacher == ParentOrTeacher.teacher && widget.teacherCanViewParentReports == false) {
      requisiteAnswersQuery = requisiteAnswersQuery.where("parentOrTeacher", isEqualTo: "teacher");
    } else if (_selectedParentTeacherFilter != "All") {
      requisiteAnswersQuery = requisiteAnswersQuery
          .where("parentOrTeacher", isEqualTo: (_selectedParentTeacherFilter == "Parent") ? "parent" : "teacher");
    }

    try {
      final QuerySnapshot requisiteAnswersQuerySnapshot = await requisiteAnswersQuery.get();
      //This for examines each individual document from our query
      for (var docSnapshot in requisiteAnswersQuerySnapshot.docs) {
        print("Doc snnapshot: ${docSnapshot.id} => ${docSnapshot.data()}");
        //gotta load them into a map before we can do anything
        Map<String, dynamic> documentData = docSnapshot.data() as Map<String, dynamic>;
        //print('Data ${documentData['Answers']}');
        //Gotta do the same with our 'Answers' attribute within the doc, which is all we really want here
        Map<String, dynamic> answers = documentData['Answers'];
        for (String key in answers.keys) {
          //print(answers[key]);
          //Now in our forLoop, we gotta check if avList contains already contains the question
          //shown in the key section, if it doesn't, then it needs to add the question into avList
          //in addition to incrementing the corresponding value; and if it does, then it only needs
          //to increment the corresponding enum value for the question

          //So key is the "question" while value is the answer - and we need to increment the
          //"Answer Map" by 1 any time a new answer pops, basically.
          //print("Key: $key; value: ${answers[key]}");

          avList.firstWhere((element) => element.question == key,
              orElse: () {
                //catchment for if it doesn't find anything
                final temp = AnswerData(key);
                //temp.add1(answers[key]);
                avList.add(temp);
                return temp;
              }).add1(answers[key]);
        }
      }
    } catch (e) {
      print(e);
      return [];
    }
    //print("AVList: $avList");
    // for (final item in avList) {
    //   print("${item.question} :");
    //   for (final answer in item.answers) {
    //     print("\t${answer.answer} : ${answer.value}");
    //   }
    // }
    return avList;
  }

  void _updateDateRange() {
    DateTime fromDate, toDate = DateTime.now();
    switch (_currentLookbackSelection) {
      case _Lookback.today:
        fromDate = DateTime(toDate.year, toDate.month, toDate.day);
        break;
      case _Lookback.lastWeek:
        fromDate = toDate.subtract(const Duration(days: 7));
        break;
      case _Lookback.lastMonth:
        fromDate = toDate.subtract(const Duration(days: 30));
        break;
      case _Lookback.allTime:
        fromDate = toDate;
        break;
      default:
        return;
    }

    setState(() {
      _fromDate = fromDate;
      _toDate = toDate;
    });
    _updateState();
  }

  void _updateState() {
    setState(() {
      _isFetchingData = true;
    });
    //_getAnswerDocumentsFromDatabase();
    _getAnswerDocumentsFromDatabase().then((value) {
      setState(() {
        //print("Value $value");
        _answerDataList = value;
        //print(_answerDataList);
        //print("Answer Data List insdide setState: $_answerDataList");
        _currentQuestion = (value.isNotEmpty) ? _answerDataList[_currentQuestionNumber].question : "";
      });
    });
    //print("Answer Data List: ${_answerDataList}");
    setState(() {
      _isFetchingData = false;
    });
  }

  @override
  void initState() {
    // TODO: implement initState
    //_patientDataView = sampleAnswers[sampleAnswers.keys.first];
    _updateState();
    //print(widget.patientReference);
    //_currentQuestion = _sampleAnswerData[_currentQuestionNumber].question;
    super.initState();
  }

  @override
  Widget build(context) {

    //print(sampleAnswers[_sampleAnswerData[0]]);
    //print(sampleAnswers[_sampleAnswerData[0]]);
    //print("Build executes");

    return Scaffold(
      appBar: AppBar(title: Text("${widget.patientFirstName}'s Report Summary"),),
      body: GradientContainer(
          child: SingleChildScrollView(
              child: Center(child: Column(
                children: [
                  const SizedBox(height: 15,),
                  if (!_isFetchingData && _answerDataList.isNotEmpty)
                    Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 5),
                          child: Text("Question ${_currentQuestionNumber+1}: \n$_currentQuestion",
                            style: Theme.of(context).textTheme.titleLarge,
                            textAlign: TextAlign.center,
                          ),
                        ),
                        SfCircularChart(
                          tooltipBehavior: TooltipBehavior(enable: true),
                          legend: const Legend(
                            isVisible: true,
                            position: LegendPosition.right,
                            overflowMode: LegendItemOverflowMode.wrap,
                          ),
                          palette: <Color>[Colors.deepOrange.shade600, Colors.yellow.shade600, Colors.lightGreenAccent, Colors.lightBlueAccent],
                          series: <CircularSeries>[
                            PieSeries<AnswerValues, String>(
                                dataSource: _answerDataList[_currentQuestionNumber].answers,
                                xValueMapper: (AnswerValues answer, _) => AnswerMap[answer.answer],
                                yValueMapper: (AnswerValues answer, _) => answer.value,
                                // pointColorMapper: (AnswerValues answer, _) {
                                //   switch (AnswerMap[answer.answer]) {
                                //     case "Not at all" : return Color.fromARGB(255, 8, 22, 87);
                                //     case "Sometimes" : return Color.fromARGB(255, 77, 25, 27);
                                //     case "A lot" : return Color.fromARGB(255, 130, 14, 22);
                                //     case "Always" : return Color.fromARGB(255, 250, 128, 114);
                                //     default: return Colors.white;
                                //   }
                                // },
                                dataLabelSettings: const DataLabelSettings(
                                    isVisible: true,
                                    showZeroValue: false
                                ),
                                enableTooltip: true
                            )
                          ],
                        )
                      ],
                    )
                  else if (_isFetchingData)
                    Center(child: CircularProgressIndicator(),)
                  else
                    Column(
                      children: [
                        SizedBox(height: 45,),
                        _noAnswersWidget,
                        SizedBox(height: 45,)
                      ],
                    ),
                  //const SizedBox(height: 25,),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                          onPressed: (_currentQuestionNumber > 0) ? _previousPressed : (){},
                          child: const Text("Back")),
                      SizedBox(width: 15,),
                      ElevatedButton(
                          onPressed: (_currentQuestionNumber < _answerDataList.length - 1) ? _nextPressed : (){},
                          child: const Text("Next")
                      )
                    ],
                  ),
                  const SizedBox(height: 25,),
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: 200,
                      maxHeight: double.infinity
                    ),
                      child: Card(
                        color: Theme.of(context).colorScheme.secondary,
                        margin: EdgeInsets.symmetric(horizontal: 15),
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 15, vertical: 50),
                          child: Column(
                              children: [
                                DropdownButtonFormField(
                                    decoration: const InputDecoration(
                                      label: Text("Select Time of Day",
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      //color: Colors.white
                                    ),
                                    dropdownColor: Theme.of(context).colorScheme.secondary,
                                    items: _TimeOfDay.values.map((item) {
                                      return DropdownMenuItem(
                                        value: item,
                                        child: Text(
                                          item.name.capitalize(),
                                          style: TextStyle(
                                            //color: Colors.black,
                                            //backgroundColor: Colors.white
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: (value) {
                                      setState(() {
                                        _timeOfDay = value!;
                                      });
                                      _updateState();
                                    }
                                ),
                                const SizedBox(height: 25,),
                                if (widget.parentOrTeacher == ParentOrTeacher.parent || widget.teacherCanViewParentReports)
                                  DropdownButtonFormField(
                                      decoration: const InputDecoration(
                                          label: Text("Select Parent of Teacher",
                                            style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white
                                            ),)
                                      ),
                                      dropdownColor: Theme.of(context).colorScheme.secondary,

                                      items: ["Parent", "Teacher", "All"].map((String item) {
                                        return DropdownMenuItem(
                                          value: item,
                                          child: Text(
                                            item,
                                            style: TextStyle(
                                              //color: Colors.black,
                                                color: Colors.white
                                              //backgroundColor: Colors.white
                                            ),
                                          ),

                                        );
                                      }).toList(),
                                      onChanged: (item) {
                                        _selectedParentTeacherFilter = item!;
                                        _updateState();
                                      }
                                  ),
                                const SizedBox(height: 25,),
                                DropdownButtonFormField(
                                    decoration: const InputDecoration(
                                        label: Text("Select Date Range",
                                          style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white
                                          ),)
                                    ),
                                    dropdownColor: Theme.of(context).colorScheme.secondary,
                                    items: _dateRangeMap.entries.map((entry) {
                                      return DropdownMenuItem(
                                        value: entry.value,
                                        child: Text(
                                          entry.key,
                                          style: TextStyle(color: Colors.white),
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: (value) {
                                      //print(value);
                                      setState(() {
                                        _currentLookbackSelection = (value == null) ? _currentLookbackSelection : value;
                                      });
                                      _updateDateRange();

                                    }
                                ),
                                SizedBox(height: 25,),
                                if (_currentLookbackSelection == _Lookback.specificTimeframe)
                                  Row(
                                    children: [
                                      //From and To Date Pickers will need to go here
                                      Flexible(child: DatePicker(
                                          initialValue: _fromDate,
                                          onchanged: (value) {
                                            print("Made it to here. value: $value");
                                            setState(() {
                                              _fromDate = value;
                                            });
                                            _updateState();
                                          },
                                          labelText: "From:"
                                      )),
                                      Flexible(child: DatePicker(
                                          initialValue: _toDate,
                                          onchanged: (value) {
                                            setState(() {
                                              _toDate = value;
                                            });
                                            _updateState();
                                          },
                                          labelText: "To:"
                                      ))
                                    ],
                                  )
                              ]
                          ),
                        ),
                      )
                  )
                ],
              ))
            //Is fetching data catch will need to go deeper in so that we can adjust search parameters.
          )
      )
    );
  }
}

// Scaffold(
//           body: Center(child: Column(
//             children: [
//               const SizedBox(height: 25,),
//               Text("Question ${_currentQuestionNumber+1}: $_currentQuestion",
//                 style: TextStyle(fontSize: 24),
//                 textAlign: TextAlign.center,
//

AnswerData _sample1 = AnswerData.withMap("The child did their homework",
    [
      AnswerValues(Answers.notAtAll, 4),
      AnswerValues(Answers.sometimes, 3),
      AnswerValues(Answers.alot, 6),
      AnswerValues(Answers.always, 7)
    ]
),
  _sample2 = AnswerData.withMap("The child stayed on task",
      [
        AnswerValues(Answers.notAtAll, 7),
        AnswerValues(Answers.sometimes, 4),
        AnswerValues(Answers.alot, 3),
        AnswerValues(Answers.always, 9)
      ]
  ),
  _sample3 = AnswerData.withMap("The child did things when asked the first time" ,
      [
        AnswerValues(Answers.notAtAll, 3),
        AnswerValues(Answers.sometimes, 7),
        AnswerValues(Answers.alot, 8),
        AnswerValues(Answers.always, 4)
      ]
  ),
  _sample4 = AnswerData.withMap("The child is pretty alright I guess",
      [
        AnswerValues(Answers.notAtAll, 5),
        AnswerValues(Answers.sometimes, 4),
        AnswerValues(Answers.alot, 6),
        AnswerValues(Answers.always, 5)
      ]
);

List<AnswerData> _sampleAnswerData = [_sample1, _sample2, _sample3, _sample4];