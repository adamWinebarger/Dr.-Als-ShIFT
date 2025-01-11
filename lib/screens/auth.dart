import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:email_validator/email_validator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:password_field_validator/password_field_validator.dart';
import 'package:questionmakerteacher/main.dart';
import 'package:questionmakerteacher/models/theme_data.dart';
import 'package:questionmakerteacher/screens/patient_list_screen.dart';
import 'package:sf_symbols/sf_symbols.dart';
import 'package:flutter_signin_button/flutter_signin_button.dart';

final _firebaseAuth = FirebaseAuth.instance;

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<StatefulWidget> createState() {
    return _AuthScreenState();
  }
}

class _AuthScreenState extends State<AuthScreen> {

  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();

  bool _isLogin = true, _passwordFieldSelected = false, _isAuthenticating = false,
    _isAdminLogin = false;
  String _enteredEmail = '', _enteredPassword = '', _enteredLastName = '',
    _enteredFirstName = '';
  var _sfSymbolSize = 75.0;

  void _submit() async {
    setState(() {
      _isAuthenticating = true;
    });

    //So this ios...?
    final isValid = _formKey.currentState!.validate();

    if (!isValid) {
      //Should we do an error message here?
      setState(() {
        _isAuthenticating = false;
      });
      return;
    }

    _formKey.currentState!.save();

    try {
      //might move the authenticating indicator into this try block...

      if (_isLogin) {
        /*So here, we need to implement our first check as to whether the person logging in
        * has an adminID associated with their email. In the event that that's true
        * then we're going to want to give the user a little yes/no window prompt that
        * asks whether they're trying to log into their therapist account.
        *
        * If they are, then all we need to do is set an _isAdmin boolean and then
        * that will give them different privileges within the application than their
        * normal account
        *
        * Edit: That check was moved to main since we don't actually push from here.
        * Given the sort of... pain in the ass that was being caused by trying to get the
        * alert to manifest from here, it's actually going to be easier up in main anyways
        */
        //print("In the start of isLogin");

        final userCreds = await _firebaseAuth.signInWithEmailAndPassword(
            email: _enteredEmail, password: _enteredPassword);

      } else {
        final userCreds = await _firebaseAuth.createUserWithEmailAndPassword(
            email: _enteredEmail, password: _enteredPassword);

        await FirebaseFirestore.instance.collection('users')
            .doc(userCreds.user!.uid).set({
          'firstName': _enteredFirstName,
          'lastName': _enteredLastName,
          'email': _enteredEmail,
          'parentOrTeacher': 'teacher',
          'viewablePatients' : []
        });
      }
    } on FirebaseAuthException catch (error) {
      if (error.code == 'email-already-in-use') {

      }
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(error.message ?? "Authentication Failed")
          )
      );

      setState(() {
        _isAuthenticating = false;
      });
    }


    //Used to test the transition from the login screen to the patientList.
    //Will need to be changed later.
    // Navigator.push(
    //   context,
    //   MaterialPageRoute(builder: (context) =>  const PatientListScreen())
    // );
    //
    // setState(() {
    //   _isAuthenticating = false;
    // });
  }

  @override
  Widget build(context) {
    return Scaffold(
      //backgroundColor: Theme.of(context).primaryColor,
      appBar: AppBar(
        title: Center(
          child: Text(_isLogin ? "Login" : "Signup"),
        ),
      ),
      body: GradientContainer(
          child: Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [

                    Card(

                      color: Color(0xFF484747),
                      child: Padding(
                        padding: EdgeInsets.all(15),
                        child: Icon(
                          CupertinoIcons.search_circle_fill,
                          size: _isLogin ? 200 : 75,
                          color: Color(0xFF92b662),
                          //color: Theme.of(context).colorScheme.primary
                        ),
                      )

                    ),
                    SizedBox(height: _isLogin ? 75 : 15),
                    Card(
                      color: Color(0xFF484747),
                      margin: const EdgeInsets.all(20),
                      child: SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.all(25),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                //Last name
                                if (!_isLogin)
                                  TextFormField(
                                    decoration: const InputDecoration(
                                        labelText: "First Name:"),
                                    style: TextStyle(
                                        color: Colors.white
                                    ),
                                    validator: (value) {
                                      if (value == null || value.trim().length < 2) {
                                        return "Invalid first name detected.";
                                      }
                                      return null;
                                    },
                                    onSaved: (value) {
                                      _enteredFirstName = value!;
                                    },
                                    textInputAction: TextInputAction.next,
                                  ),
                                //First Name
                                if (!_isLogin)
                                  TextFormField(
                                    decoration: const InputDecoration(labelText: "Last Name:"),
                                    style: TextStyle(
                                        color: Colors.white
                                    ),
                                    validator: (value) {
                                      if (value == null || value.trim().length < 4) {
                                        return "Invalid last name detected.";
                                      }
                                      return null;
                                    },
                                    onSaved: (value) {
                                      _enteredLastName = value!;
                                    },
                                    textInputAction: TextInputAction.next,
                                  ),
                                //This will be for the email input
                                TextFormField(
                                  decoration: const InputDecoration(labelText: "Email"),
                                  style: TextStyle(
                                      color: Colors.white
                                  ),
                                  keyboardType: TextInputType.emailAddress,
                                  autocorrect: false,
                                  textCapitalization: TextCapitalization.none,
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty || !EmailValidator.validate(value)) {
                                      return 'Invalid email input';
                                    }
                                    return null;
                                  },
                                  onSaved: (value) {
                                    _enteredEmail = value!;
                                  },
                                  onTap: () {
                                    setState(() {
                                      _passwordFieldSelected = false;
                                    });
                                  },
                                  textInputAction: TextInputAction.next,
                                ),
                                //This one will be for the password
                                Container(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: Column(
                                    children: [
                                      //if (_isLogin)
                                      TextFormField(
                                        decoration: const InputDecoration(labelText: "Password"),
                                        style: TextStyle(
                                            color: Colors.white
                                        ),
                                        autocorrect: false,
                                        obscureText: true,
                                        validator: (value) {
                                          return (value != null && value.trim().isNotEmpty) ?
                                          null : "Password field cannot be empty";
                                        },
                                        onSaved: (value) {
                                          _enteredPassword = value!;
                                        },
                                        controller: _passwordController,
                                        onTap: () {
                                          setState(() {
                                            _passwordFieldSelected = true;
                                          });
                                        },
                                        textInputAction: TextInputAction.done,
                                        onEditingComplete: () {
                                          _passwordFieldSelected = false;
                                        },
                                        onFieldSubmitted: (_) {
                                          _submit();
                                        },
                                      ),
                                      if (!_isLogin)
                                        const SizedBox(height: 10,),
                                      if (!_isLogin)
                                        PasswordFieldValidator(
                                          minLength: 8,
                                          uppercaseCharCount: 2,
                                          lowercaseCharCount: 2,
                                          numericCharCount: 2,
                                          specialCharCount: 2,
                                          defaultColor: Colors.white,
                                          successColor: Colors.lightGreen,
                                          failureColor: Colors.red,
                                          controller: _passwordController,
                                        )
                                    ],
                                  ),
                                ),
                                // if (_isAuthenticating)
                                //   Container(
                                //     padding: const EdgeInsets.only(top: 10),
                                //     child: const CircularProgressIndicator()
                                //   )
                                // else
                                //Buttons
                                const SizedBox(height: 15,),
                                ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor: Theme.of(context).colorScheme.primary,
                                        //textStyle: TextStyle(color: Theme.of(context).primaryColor),
                                        minimumSize: Size(200, 36)
                                    ),
                                    onPressed: _submit,
                                    child: !_isAuthenticating ?
                                    Text(
                                      _isLogin ? "Login" : "Sign Up",
                                      style: TextStyle(
                                        color: Theme.of(context).colorScheme.primaryContainer,
                                      ),
                                    ) : SizedBox(
                                      height: 12,
                                      width: 12,
                                      child: CircularProgressIndicator(
                                        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                                      ),
                                    )
                                ),
                                const SizedBox(height: 5,),
                                // SignInButton(
                                //   Buttons.GoogleDark,
                                //
                                //   onPressed: () {}
                                // ),
                                // ElevatedButton(
                                //   style: ElevatedButton.styleFrom(
                                //     backgroundColor: Theme.of(context).colorScheme.background,
                                //     shape: RoundedRectangleBorder(
                                //       borderRadius: BorderRadius.circular(100),
                                //     ),
                                //     side: BorderSide(width: 1, color: Theme.of(context).colorScheme.primary),
                                //     //textStyle: TextStyle(color: Theme.of(context).primaryColor),
                                //     minimumSize: const Size(200, 40)
                                //   ),
                                //   onPressed: () {},
                                //   child: Row(
                                //     mainAxisSize: MainAxisSize.min,
                                //     mainAxisAlignment: MainAxisAlignment.center,
                                //     children: [
                                //       Container(
                                //         width: 25,
                                //         height: 25,
                                //         child: const Image(image: AssetImage('assets/images/google_circle.png'), height: 24, width: 24,),
                                //       ),
                                //       const SizedBox(width: 10,),
                                //       Text(
                                //         "Sign in With Google",
                                //         style: TextStyle(
                                //           color: Theme.of(context).colorScheme.primary,
                                //         )
                                //       )
                                //     ],
                                //   )
                                // ),
                                if (!_isAuthenticating)
                                  TextButton(
                                      onPressed: () {
                                        setState(() {
                                          _isLogin = !_isLogin;
                                          _sfSymbolSize = _isLogin ? 200 : 75;
                                        });
                                      },
                                      child: Text(
                                        _isLogin ? "Create an account" : "I already have an account",
                                        style: TextStyle(color: Color(0xFF92b662)),
                                      )
                                  )
                              ],
                            ),
                          ),
                        ),
                      ),
                    )

                  ],
                ),
              )
          ),
      )
    );
  }

}