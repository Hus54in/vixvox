
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:email_validator/email_validator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:vixvox/login/Sign_up_model.dart';


class SignUpWidget extends StatefulWidget {
  const SignUpWidget({super.key});

  @override
  State<SignUpWidget> createState() => _SignUpWidgetState();
}



class _SignUpWidgetState extends State<SignUpWidget> {
  late SignUpModel _model;
  late bool valid = false;
  final formkey = GlobalKey<FormState>();
  final scaffoldKey = GlobalKey<ScaffoldState>();
  late StreamSubscription<bool> _keyboardVisibilitySubscription;
  final bool _isKeyboardVisible = false;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => SignUpModel());

   

    _model.textController1 ??= TextEditingController();
    _model.textFieldFocusNode1 ??= FocusNode();

    _model.emailController ??= TextEditingController();
    _model.textFieldFocusNode2 ??= FocusNode();

    _model.passwordController ??= TextEditingController();
    _model.textFieldFocusNode3 ??= FocusNode();

    _model.confirmpasswordController ??= TextEditingController();
    _model.usernameFocusNode ??= FocusNode();

    _model.usernameController ??= TextEditingController();
    _model.usernameFocusNode ??= FocusNode();

  }
  String _username = '';
String _passwordError = '';
String _EmailError = '';

  @override
  void dispose() {
    _model.dispose();

   
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () { FocusScope.of(context).unfocus();},
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          automaticallyImplyLeading: false,
          leading: IconButton(
            hoverColor: Colors.transparent,
           
            iconSize: 60,
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: Color(0xFF101213),
              size: 30,
            ),
            onPressed: () async {
             Navigator.of(context).pop();
            },
          ),
          actions: const [],
          centerTitle: false,
          elevation: 0,
        ),
        body: SafeArea(
          top: true,
          child: Align(
            alignment: const AlignmentDirectional(0, 0),
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(
                maxWidth: 670,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsetsDirectional.fromSTEB(12, 0, 12, 0),
                      child: SingleChildScrollView(
                        child: 
                        Form(
                          key: formkey,
                          child:
                        Column(
                          mainAxisSize: MainAxisSize.max,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding:
                                  EdgeInsetsDirectional.fromSTEB(12, 32, 0, 8),
                              child: Text(
                                'Join us & cook with confidence',
                                textAlign: TextAlign.start,
                                style:TextStyle(
                                      fontFamily: 'Urbanist',
                                      color: Color(0xFF101213),
                                      fontSize: 48,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ),
                            const Padding(
                              padding:
                                  EdgeInsetsDirectional.fromSTEB(12, 0, 0, 12),
                              child: Text(
                                'Save delicious recipes and get personalized content.',
                                textAlign: TextAlign.start,
                                style:TextStyle(
                                      fontFamily: 'Plus Jakarta Sans',
                                      color: Color(0xFF57636C),
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                              ),
                            ),
                            Padding(
  padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 16, 0),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      TextFormField(
        controller: _model.usernameController,
        focusNode: _model.usernameFocusNode,
        textCapitalization: TextCapitalization.none,
        obscureText: false,
        decoration: const InputDecoration(
          labelText: 'Username',
          labelStyle: TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            color: Color(0xFF57636C),
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(
              color: Color(0xFFE0E3E7),
              width: 2,
            ),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(4.0),
              topRight: Radius.circular(4.0),
            ),
          ),
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(
              color: Color(0xFF4B39EF),
              width: 2,
            ),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(4.0),
              topRight: Radius.circular(4.0),
            ),
          ),
          errorBorder: UnderlineInputBorder(
            borderSide: BorderSide(
              color: Color(0xFFFF5963),
              width: 2,
            ),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(4.0),
              topRight: Radius.circular(4.0),
            ),
          ),
          focusedErrorBorder: UnderlineInputBorder(
            borderSide: BorderSide(
              color: Color(0xFFFF5963),
              width: 2,
            ),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(4.0),
              topRight: Radius.circular(4.0),
            ),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsetsDirectional.fromSTEB(0, 16, 16, 8),
        ),
        style: const TextStyle(
          fontFamily: 'Plus Jakarta Sans',
          color: Color(0xFF101213),
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Add your button here
          ElevatedButton(
            onPressed: () async {
            setState(() {
              _username = _model.usernameController?.text.trim() ?? '';
            });
            await isUsernameExists();
            },
            child: const Text('Your Button'),
          ),
          Text(
            '${_model.usernameController?.text.trim() ?? ''} is ${valid ? 'taken' : 'available'}',
            style: TextStyle(
              color: valid ? Colors.red : Colors.green,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    ],
  ),
),

                            Padding(
                              padding:
                                  const EdgeInsetsDirectional.fromSTEB(16, 12, 16, 0),
                              child: TextFormField(
                                controller: _model.textController1,
                                focusNode: _model.textFieldFocusNode1,
                                textCapitalization: TextCapitalization.words,
                                obscureText: false,
                                decoration: const InputDecoration(
                                  labelText: 'Display Name',
                                  labelStyle: TextStyle(
                                        fontFamily: 'Plus Jakarta Sans',
                                        color: Color(0xFF57636C),
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                  enabledBorder: UnderlineInputBorder(
                                    borderSide: BorderSide(
                                      color: Color(0xFFE0E3E7),
                                      width: 2,
                                    ),
                                    borderRadius: BorderRadius.only(
                                      topLeft: Radius.circular(4.0),
                                      topRight: Radius.circular(4.0),
                                    ),
                                  ),
                                  focusedBorder: UnderlineInputBorder(
                                    borderSide: BorderSide(
                                      color: Color(0xFF4B39EF),
                                      width: 2,
                                    ),
                                    borderRadius: BorderRadius.only(
                                      topLeft: Radius.circular(4.0),
                                      topRight: Radius.circular(4.0),
                                    ),
                                  ),
                                  errorBorder: UnderlineInputBorder(
                                    borderSide: BorderSide(
                                      color: Color(0xFFFF5963),
                                      width: 2,
                                    ),
                                    borderRadius: BorderRadius.only(
                                      topLeft: Radius.circular(4.0),
                                      topRight: Radius.circular(4.0),
                                    ),
                                  ),
                                  focusedErrorBorder: UnderlineInputBorder(
                                    borderSide: BorderSide(
                                      color: Color(0xFFFF5963),
                                      width: 2,
                                    ),
                                    borderRadius: BorderRadius.only(
                                      topLeft: Radius.circular(4.0),
                                      topRight: Radius.circular(4.0),
                                    ),
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                  contentPadding:
                                      EdgeInsetsDirectional.fromSTEB(
                                          0, 16, 16, 8),
                                ),
                                style: const TextStyle(
                                      fontFamily: 'Plus Jakarta Sans',
                                      color: Color(0xFF101213),
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      
                                    ),
                                
                              ),
                            ),
                            Padding(
                              padding:
                                  const EdgeInsetsDirectional.fromSTEB(16, 12, 16, 0),
                              child: TextFormField(
                                controller: _model.emailController,
                                focusNode: _model.textFieldFocusNode2,
                                obscureText: false,
                                autovalidateMode: AutovalidateMode.onUserInteraction, validator: (email) {
                                    if (email != null && !EmailValidator.validate(email)) {
                                        return 'Enter a valid email';
                                    }
                                    else if ( _EmailError.isNotEmpty){
                                      return _EmailError;
                                    }
                                    return null;
                                  },
                                decoration: const InputDecoration(
                                  labelText: 'Email Address',
                                  labelStyle: TextStyle(
                                        fontFamily: 'Plus Jakarta Sans',
                                        color: Color(0xFF57636C),
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                  enabledBorder: UnderlineInputBorder(
                                    borderSide: BorderSide(
                                      color: Color(0xFFE0E3E7),
                                      width: 2,
                                    ),
                                    borderRadius: BorderRadius.only(
                                      topLeft: Radius.circular(4.0),
                                      topRight: Radius.circular(4.0),
                                    ),
                                  ),
                                  focusedBorder: UnderlineInputBorder(
                                    borderSide: BorderSide(
                                      color: Color(0xFF4B39EF),
                                      width: 2,
                                    ),
                                    borderRadius: BorderRadius.only(
                                      topLeft: Radius.circular(4.0),
                                      topRight: Radius.circular(4.0),
                                    ),
                                  ),
                                  errorBorder: UnderlineInputBorder(
                                    borderSide: BorderSide(
                                      color: Color(0xFFFF5963),
                                      width: 2,
                                    ),
                                    borderRadius: BorderRadius.only(
                                      topLeft: Radius.circular(4.0),
                                      topRight: Radius.circular(4.0),
                                    ),
                                  ),
                                  focusedErrorBorder: UnderlineInputBorder(
                                    borderSide: BorderSide(
                                      color: Color(0xFFFF5963),
                                      width: 2,
                                    ),
                                    borderRadius: BorderRadius.only(
                                      topLeft: Radius.circular(4.0),
                                      topRight: Radius.circular(4.0),
                                    ),
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                  contentPadding:
                                      EdgeInsetsDirectional.fromSTEB(
                                          0, 16, 16, 8),
                                ),
                                style: const TextStyle(
                                      fontFamily: 'Plus Jakarta Sans',
                                      color: Color(0xFF101213),
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                     
                                    ),
                               
                              ),
                            ),
                            
                            Padding(
                              padding:
                                  const EdgeInsetsDirectional.fromSTEB(16, 12, 16, 0),
                              child: TextFormField(
                                controller: _model.passwordController,
                                focusNode: _model.textFieldFocusNode3,
                                autovalidateMode: AutovalidateMode.onUserInteraction,   validator: (password) {
                                    if ( password != null && password.length < 6) {
                                        return 'Enter atleast 6 characters';
                                    }
                                    else if ( _passwordError.isNotEmpty){
                                      return _passwordError;
                                    }
                                    return null;
                                  },
                                  

                                textCapitalization: TextCapitalization.none,
                                obscureText: !_model.passwordVisibility,
                                decoration: InputDecoration(
                                  labelText: 'Password',
                                  labelStyle: const TextStyle(
                                        fontFamily: 'Plus Jakarta Sans',
                                        color: Color(0xFF57636C),
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                  enabledBorder: const UnderlineInputBorder(
                                    borderSide: BorderSide(
                                      color: Color(0xFFE0E3E7),
                                      width: 2,
                                    ),
                                    borderRadius: BorderRadius.only(
                                      topLeft: Radius.circular(4.0),
                                      topRight: Radius.circular(4.0),
                                    ),
                                  ),
                                  focusedBorder: const UnderlineInputBorder(
                                    borderSide: BorderSide(
                                      color: Color(0xFF4B39EF),
                                      width: 2,
                                    ),
                                    borderRadius: BorderRadius.only(
                                      topLeft: Radius.circular(4.0),
                                      topRight: Radius.circular(4.0),
                                    ),
                                  ),
                                  errorBorder: const UnderlineInputBorder(
                                    borderSide: BorderSide(
                                      color: Color(0xFFFF5963),
                                      width: 2,
                                    ),
                                    borderRadius: BorderRadius.only(
                                      topLeft: Radius.circular(4.0),
                                      topRight: Radius.circular(4.0),
                                    ),
                                  ),
                                  focusedErrorBorder: const UnderlineInputBorder(
                                    borderSide: BorderSide(
                                      color: Color(0xFFFF5963),
                                      width: 2,
                                    ),
                                    borderRadius: BorderRadius.only(
                                      topLeft: Radius.circular(4.0),
                                      topRight: Radius.circular(4.0),
                                    ),
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                  contentPadding:
                                      const EdgeInsetsDirectional.fromSTEB(
                                          0, 16, 16, 8),
                                  suffixIcon: InkWell(
                                    onTap: () => setState(
                                      () => _model.passwordVisibility =
                                          !_model.passwordVisibility,
                                    ),
                                    focusNode: FocusNode(skipTraversal: true),
                                    child: Icon(
                                      _model.passwordVisibility
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                      color: const Color(0xFF101213),
                                      size: 24,
                                    ),
                                  ),
                                ),
                                style: const TextStyle(
                                      fontFamily: 'Plus Jakarta Sans',
                                      color: Color(0xFF101213),
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                     
                                    ),
                              
                              ),
                              
                            ),
                            Padding(
                              padding:
                                  const EdgeInsetsDirectional.fromSTEB(16, 12, 16, 0),
                              child: TextFormField(
                                controller: _model.confirmpasswordController,
                                focusNode: _model.ConfirmPasswordFocusNode,
                                autovalidateMode: AutovalidateMode.onUserInteraction,   validator: (password) {
                                    if ( password != null && password != _model.passwordController!.text.trim()) {
                                        return "Passwords don't match!";
                                    }
                                    return null;
                                  },
                                textCapitalization: TextCapitalization.none,
                                obscureText: !_model.confirmpasswordVisibility,
                                decoration: InputDecoration(
                                  labelText: 'Confirm Password',
                                  labelStyle: const TextStyle(
                                        fontFamily: 'Plus Jakarta Sans',
                                        color: Color(0xFF57636C),
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                  enabledBorder: const UnderlineInputBorder(
                                    borderSide: BorderSide(
                                      color: Color(0xFFE0E3E7),
                                      width: 2,
                                    ),
                                    borderRadius: BorderRadius.only(
                                      topLeft: Radius.circular(4.0),
                                      topRight: Radius.circular(4.0),
                                    ),
                                  ),
                                  focusedBorder: const UnderlineInputBorder(
                                    borderSide: BorderSide(
                                      color: Color(0xFF4B39EF),
                                      width: 2,
                                    ),
                                    borderRadius: BorderRadius.only(
                                      topLeft: Radius.circular(4.0),
                                      topRight: Radius.circular(4.0),
                                    ),
                                  ),
                                  errorBorder: const UnderlineInputBorder(
                                    borderSide: BorderSide(
                                      color: Color(0xFFFF5963),
                                      width: 2,
                                    ),
                                    borderRadius: BorderRadius.only(
                                      topLeft: Radius.circular(4.0),
                                      topRight: Radius.circular(4.0),
                                    ),
                                  ),
                                  focusedErrorBorder: const UnderlineInputBorder(
                                    borderSide: BorderSide(
                                      color: Color(0xFFFF5963),
                                      width: 2,
                                    ),
                                    borderRadius: BorderRadius.only(
                                      topLeft: Radius.circular(4.0),
                                      topRight: Radius.circular(4.0),
                                    ),
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                  contentPadding:
                                      const EdgeInsetsDirectional.fromSTEB(
                                          0, 16, 16, 8),
                                  suffixIcon: InkWell(
                                    onTap: () => setState(
                                      () => _model.passwordVisibility =
                                          !_model.passwordVisibility,
                                    ),
                                    focusNode: FocusNode(skipTraversal: true),
                                    child: Icon(
                                      _model.passwordVisibility
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                      color: const Color(0xFF101213),
                                      size: 24,
                                    ),
                                  ),
                                ),
                                style: const TextStyle(
                                      fontFamily: 'Plus Jakarta Sans',
                                      color: Color(0xFF101213),
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                     
                                    ),
                              
                              ),
                              
                            ),
                            Theme(
                              data: ThemeData(
                                unselectedWidgetColor: const Color(0xFF57636C),
                              ),
                              child: CheckboxListTile(
                                value: _model.checkboxListTileValue ??= true,
                                onChanged: (newValue) async {
                                  setState(() =>
                                      _model.checkboxListTileValue = newValue!);
                                },
                                title: const Text(
                                  'I would like to receive inspriation emails.',
                                  style: TextStyle(
                                        fontFamily: 'Plus Jakarta Sans',
                                        color: Color(0xFF57636C),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                ),
                                tileColor: Colors.white,
                                activeColor: const Color(0xFF101213),
                                checkColor: Colors.white,
                                dense: false,
                                controlAffinity:
                                    ListTileControlAffinity.leading,
                                contentPadding: const EdgeInsetsDirectional.fromSTEB(
                                    16, 0, 16, 0),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  ),
                    Padding(
  padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 16, 24),
  child: SizedBox(
    width: double.infinity,
    height: 60,
    child: TextButton(
      onPressed: () {
       signup ();
      },
      style: TextButton.styleFrom(
        backgroundColor: const Color(0xFF101213),
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(50),
        ),
      ),
      child: const Text(
        'Create Account',
        style: TextStyle(
          fontFamily: 'Plus Jakarta Sans',
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),
  ),
),

                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  


  Future signup () async {
    if (!formkey.currentState!.validate()) {
      return;
    }

    setState(() {
      _passwordError = '';
      _EmailError = '';
    
    });
    showDialog(context: context, barrierDismissible: false,builder: (context)=> const Center(child: CircularProgressIndicator()));
    try{
      await FirebaseAuth.instance.createUserWithEmailAndPassword(email: _model.emailController!.text.trim(), password: _model.passwordController!.text.trim());
      await FirebaseAuth.instance.currentUser!.updateDisplayName( _model.textController1!.text.trim());
      await addUserToDatabase();
    }
   on FirebaseAuthException catch (e) {
    if (e.code == 'weak-password') {
      setState(() {
        _passwordError = 'The password provided is too weak';
      });
    } else if (e.code == 'email-already-in-use') {
      setState(() {
        _EmailError = 'The account already exists for that email.';
      });
    }
    else {
    print(e);
  }
  } 
    Navigator.pop(context); // Close the dialog
    final user = FirebaseAuth.instance.currentUser!;
    await user.sendEmailVerification();
    await FirebaseAuth.instance.currentUser!.reload();
    Navigator.pop(context);

  }
Future<void> addUserToDatabase() async {
  try {
    // Get the current user

    // Store user data in Firestore
    await FirebaseFirestore.instance.collection('username').doc(_model.usernameController!.text.trim().toLowerCase()).set({});
    await FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser!.uid).set({
      'username': _model.usernameController!.text.trim(),
      'email': _model.emailController!.text.trim(),
      'displayName': _model.textController1!.text.trim(),
    });
  } catch (e) {
    print("Error adding user to database: $e");
  }
}


Future isUsernameExists() async {
  
  try {
    // Initialize Firebase
    // Get a reference to the users collection
    DocumentSnapshot documentSnapshot = await FirebaseFirestore.instance.collection('username').doc(_username.toLowerCase()).get();
    // Check if a document with the given username exists
    print(_username);
    setState(() {
      valid = documentSnapshot.exists;
    });



  } catch (e) {
    return ; // Return false in case of an error
  }
}

  SignUpModel createModel(BuildContext context, SignUpModel Function() param1) {
    // Function body
    return SignUpModel(); // Replace with the appropriate return statement
  }
}
