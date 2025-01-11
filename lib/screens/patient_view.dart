import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:questionmakerteacher/models/answerer.dart';
import 'package:questionmakerteacher/models/patient.dart';
import 'package:questionmakerteacher/models/theme_data.dart';
import 'package:questionmakerteacher/screens/patient_dataview_screen.dart';
import 'package:questionmakerteacher/screens/questionnaire_screen.dart';
import 'package:questionmakerteacher/screens/view_reports_screen.dart';
import 'package:questionmakerteacher/widgets/test_widgets.dart';

class PatientView extends StatefulWidget {
  const PatientView({super.key, required this.currentPatient, required this.parentOrTeacher,
    required this.isAdmin});

  final Patient currentPatient;
  final ParentOrTeacher parentOrTeacher;
  final bool isAdmin;

  @override
  State<StatefulWidget> createState() {
    return _PatientViewState();
  }

}

class _PatientViewState extends State<PatientView> {

  late bool _parentCanViewTeacherReports = widget.currentPatient.teacherCanViewParentAnswers;

  //So this will be the function where the current user is updated in the database,
  //but since we made it so that that info is loaded into a Patient class and then we're
  //getting that information here. Things are complicated a bit and we'll need to both
  //update the variable, and update that locally as well. Will need to either
  // update the variable at the class level, or otherwise test to make sure that
  // changes made to the database get reflected at the end-user level.
  Future<String?> _setWhetherTeachersCanViewParentReports(bool setVal) async {
    await FirebaseFirestore.instance.collection('Patients')
        .doc(widget.currentPatient.path).update({
      'teacherCanViewParentAnswers' : setVal
    }).catchError((error) {
      return error;
    }).then((value) {
      return null;
    });
  }

  @override
  Widget build(context) {
    final currentPatientReferenceString = "${widget.currentPatient.lastName}, ${widget.currentPatient.firstName} (${widget.currentPatient.patientCode})";

    return Scaffold(
      appBar: AppBar(title: Text("${widget.currentPatient.lastName}, ${widget.currentPatient.firstName}"),),
      body: GradientContainer(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(top: 100, left: 24, right: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Center(
                  child: Text(
                    "What would you like to do?",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black
                    ),
                  )
              ),
              const SizedBox(height: 75,),
              // ElevatedButton(
              //   onPressed: () {},
              //   style: ElevatedButton.styleFrom(
              //     side: BorderSide(width: 1, color: Theme.of(context).colorScheme.primary),
              //     minimumSize: const Size(250, 40)
              //   ),
              //   child: const Text("View previous questionnaires"),
              // ),
              // const SizedBox(height: 15,),
              //This is the button for new questionnaires
              if (!widget.isAdmin)
                ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => QuestionnaireScreen(patientInQuestion: widget.currentPatient, parentOrTeacher:  widget.parentOrTeacher)
                          )
                      );
                    },
                    style: ElevatedButton.styleFrom(
                        side: BorderSide(width: 1, color: Theme.of(context).colorScheme.primary),
                        minimumSize: const Size(250, 40)
                    ),
                    child: Text(
                        "Rate ${widget.currentPatient.firstName}"
                    )
                ),
              const SizedBox(height: 15,),
              //This will be our data viz for answered questionnaires
              //... might merge this with the view questionnaires one
              ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => PatientDataView(patientReference: currentPatientReferenceString,
                          teacherCanViewParentReports: widget.currentPatient.teacherCanViewParentAnswers,
                          parentOrTeacher: widget.parentOrTeacher,
                          patientFirstName: widget.currentPatient.firstName,
                        ))
                    );
                  },
                  style: ElevatedButton.styleFrom(
                      side: BorderSide(width: 1, color: Theme.of(context).colorScheme.primary),
                      minimumSize: const Size(250, 40)
                  ),
                  child: Text(
                      "${widget.currentPatient.firstName}'s Report Summary"
                  )
              ),
              SizedBox(height: 15),
              //View Questionnaires button
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => PatientReportsListScreen(
                          currentPatientString: currentPatientReferenceString, parentOrTeacher: widget.parentOrTeacher,
                          teacherCanViewParentReports: widget.currentPatient.teacherCanViewParentAnswers
                      ))
                  );
                },
                style: ElevatedButton.styleFrom(
                    side: BorderSide(width: 1, color: Theme.of(context).colorScheme.primary),
                    minimumSize: const Size(250, 40)
                ),
                child: Text(
                  "View Past Reports",
                ),
              ),
              const SizedBox(height: 15,),
              ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                      side: BorderSide(width: 1, color: Theme.of(context).colorScheme.primary),
                      minimumSize: const Size(250, 40)
                  ),
                  child: const Text(
                    "Go Back",
                  )
              ),
              const SizedBox(height: 45,),
              //This will be our thing for parents that allows them to toggle whether teachers
              // can view the parent reports or not.
              if (widget.parentOrTeacher == ParentOrTeacher.parent && !widget.isAdmin)
                DropdownButtonFormField(
                  dropdownColor: Theme.of(context).colorScheme.secondary,
                  isExpanded: true,
                  decoration: InputDecoration(
                      label: const Text(
                        "Would you like teachers to be able to view parent reports?",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black
                          //color: Colors.white
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)
                      )
                  ),
                  items: [
                    for (final selection in ["Yes", "No"])
                      DropdownMenuItem(
                          value: (selection == "Yes") ? true : false,
                          child: Text(
                            selection,
                            style: TextStyle(color: Colors.white),
                          )
                      )
                  ],
                  onChanged: (value) {
                    _setWhetherTeachersCanViewParentReports(value!).then((value2) {
                      if (value2 == null) {
                        setState(() {
                          _parentCanViewTeacherReports = value;
                          print(_parentCanViewTeacherReports);
                        });
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("Error: $value2"),
                              duration: const Duration(seconds: 2),
                            )
                        );
                      }
                    });
                  },
                  value: _parentCanViewTeacherReports,
                )
            ],
          ),
        )
      )
    );
  }

}