import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:questionmakerteacher/main.dart';
import 'package:questionmakerteacher/models/answerer.dart';
import 'package:questionmakerteacher/models/report.dart';

import 'package:questionmakerteacher/models/patient.dart';
import 'package:questionmakerteacher/models/questionnaire.dart';
import 'package:questionmakerteacher/models/theme_data.dart';
import 'package:questionmakerteacher/screens/patient_dataview_screen.dart';
import 'package:questionmakerteacher/screens/patient_report_screen.dart';
import 'package:questionmakerteacher/stringextension.dart';

final _authenticatedUser = FirebaseAuth.instance.currentUser!;

enum _TimeOfDay {
  morning,
  afternoon,
  evening,
  all
}

class PatientReportsListScreen extends StatefulWidget {
  const PatientReportsListScreen({super.key, required this.currentPatientString,
    required this.parentOrTeacher, required this.teacherCanViewParentReports,
    required this.currentPatientFirstName
  });

  final String currentPatientString;
  final ParentOrTeacher parentOrTeacher;
  final bool teacherCanViewParentReports;
  final String currentPatientFirstName;

  @override
  State<StatefulWidget> createState() => _PatientReportsListScreenState();
}

class _PatientReportsListScreenState extends State<PatientReportsListScreen> {

  final _noAnswersWidget = const Center(child:
  Text("No data available.\n Maybe adjust your search parameters?",
    textAlign: TextAlign.center,)
  );

  bool _isFetchingData = false;
  List<Report> _reportsList = [], _reports2Show = [];
  DateTime _toDate = DateTime.now();
  DateTime? _fromDate;
  //DateTime _toDate = DateTime.now(), _fromDate = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);

  String _selectedParentTeacherFilter = "All";
  _TimeOfDay _selectedTimeOfDay = _TimeOfDay.all;
  
  int _pointsEarned = 0, _totalPoints = 0;
  String _pointsEarnedStatement = "";
  Lookback _lookback = Lookback.allTime;


  Future<List<Report>> _getReportListFromDatabase() async {
    List<Report> reportsList = [];

    final CollectionReference crList = FirebaseFirestore.instance.collection("Patients")
      .doc(widget.currentPatientString).collection("Answers");

    /*
    * Alright. So what do we need in this case?
    * So for the title card of what's going to be in the list, we would probably want
    * The $name ($relation), $date?
    * Or something like that.
    *
    * Can any of our existing classes from the model directory be used here?
    *
    * Additionally, we need to set our from and to dates like we did in patient_dataview
    * Should we have a filter for parent and teacher as well? If so, then we'll need
    * to figure out how to "stylize" the list so that we can differentiate it from
    * the regular background.
    */

    //Should we do out Lookback thing up here as well? We'll come back to that
    Query reportQuery = crList//.where("Timestamp", isGreaterThanOrEqualTo: _fromDate)
      .where("Timestamp", isLessThanOrEqualTo: _toDate)
      .orderBy("Timestamp", descending: true);

    if (widget.parentOrTeacher == ParentOrTeacher.teacher && widget.teacherCanViewParentReports == false) {
      reportQuery = reportQuery.where("parentOrTeacher", isEqualTo: "teacher");
    } else if (_selectedParentTeacherFilter != "All") {
      reportQuery = reportQuery.where("parentOrTeacher", isEqualTo: (_selectedParentTeacherFilter == "Parent") ? "parent" : "teacher");
    }

    if (_selectedTimeOfDay != _TimeOfDay.all) {
      reportQuery = reportQuery.where("timeOfDay", isEqualTo: _selectedTimeOfDay.name);
    }

    //Catches for sorting date range. We're probably going to want some kind of settings dropdown
    //menu thing but at least it looks like we were thinking ahead a bit for this stuff.

    final QuerySnapshot reportQuerySnapshot = await reportQuery.get();
    print("Made it to here");

    for (var docSnapshot in reportQuerySnapshot.docs) {
      Map<String, dynamic> documentFields = docSnapshot.data() as Map<String, dynamic>;

      Report report = Report.fromJSON(documentFields);
      print(report);
      reportsList.add(report);
    }

    return reportsList;
  }

  List<Report> _showReports() {
    List<Report> reports2Show = [];
    
    reports2Show = switch(_lookback) {
      Lookback.today => _reportsList.where((report) => report.timestamp.isAfter(DateTime.now().subtract(Duration(hours: 24)))).toList(),
      Lookback.lastWeek => _reportsList.where((report) => report.timestamp.isAfter(DateTime.now().subtract(Duration(days: 7)))).toList(),
      Lookback.lastMonth => _reportsList.where((report) => report.timestamp.isAfter(DateTime.now().subtract(Duration(days: 30)))).toList(),
     _ => _reportsList
    };

    _pointsEarned = reports2Show.fold(0, (sum, report) => sum += report.pointsEarned);
    _totalPoints = reports2Show.fold(0, (sum, report) => sum += report.pointsTotal);
    _pointsEarnedStatement = "${widget.currentPatientFirstName} has earned $_pointsEarned/$_totalPoints points";

    _pointsEarnedStatement += switch(_lookback) {
      Lookback.today => " in the past 24 hours.",
      Lookback.lastWeek => " in the past week.",
      Lookback.lastMonth => " in the past month.",
      Lookback.allTime => " overall.",
      Lookback.specificTimeframe => " in the specified timeframe."
    };
    
    return reports2Show;
  }


  void _updateState() {
    setState(() {
      _isFetchingData = true;
      _reports2Show = _showReports();
    });



    setState(() {
      _isFetchingData = false;
    });
  }

  @override
  void initState() {
    // TODO: implement initState
    _getReportListFromDatabase().then((value) {
      setState(() {
        _reportsList = value;
        _updateState();
      });
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
      appBar: AppBar(
        title: const Text("View Reports"),
        actions: [
          PopupMenuButton<Lookback>(
            icon: Icon(Icons.settings),
            onSelected: (Lookback selected) {
              setState(() {
                _lookback = selected;
                _updateState();
              });

            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<Lookback>>[
              //This is the header and won't be selectable
              PopupMenuItem(
                enabled: false,
                child: Text(
                  "Select lookback interval",
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)
                )
              ),
              const PopupMenuDivider(),
              PopupMenuItem<Lookback>(
                value: Lookback.today,
                child: Text("Past day", style: Theme.of(context).popupMenuTheme.textStyle,),
              ),
              PopupMenuItem<Lookback>(
                value: Lookback.lastWeek,
                child: Text("Past week" , style: Theme.of(context).popupMenuTheme.textStyle),
              ),
              PopupMenuItem<Lookback>(
                value: Lookback.lastMonth,
                child: Text("Past month", style: Theme.of(context).popupMenuTheme.textStyle),
              ),
              PopupMenuItem<Lookback>(
                value: Lookback.allTime,
                child: Text("All time", style: Theme.of(context).popupMenuTheme.textStyle),
              )
            ]
          )
        ],
      ),
      body: GradientContainer(
          child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 15, vertical: 35),
              child: Center(
                child: Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.all(15),
                      child: RichText(
                        text: TextSpan(
                            text: _pointsEarnedStatement,
                            style: Theme.of(context).textTheme.titleMedium
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                              border: Border.all(color: Colors.blueGrey, width: 2),
                              borderRadius: BorderRadius.circular(10),
                              color: Theme.of(context).colorScheme.secondary
                          ),
                          child: ListView.builder(
                              itemCount: _reports2Show.length,
                              itemBuilder: (context, index) {
                                final selectedReport = _reports2Show[index];

                                return Container(
                                  decoration: const BoxDecoration(
                                      border:Border(
                                          bottom: BorderSide(color: Colors.blueGrey, width: 1)
                                      )
                                  ),
                                  child: ListTile(
                                    title: Text("${selectedReport.lastName}, ${selectedReport.firstName} (${selectedReport.parentOrTeacher.name.capitalize()})"),
                                    subtitle: Text("${selectedReport.timeOfDay.capitalize()} - ${selectedReport.timestamp}\nPoints Earned: ${selectedReport.pointsEarned}/${selectedReport.pointsTotal}"),
                                    onTap: () {
                                      Navigator.push(
                                          context,
                                          MaterialPageRoute(builder: (context) => PatientReportScreen(currentReport: selectedReport))
                                      );
                                    },
                                  ),
                                );
                              }
                          ),
                        )
                    ),

                  ],
                ),
              )
          ),
      )
    );
  }
}