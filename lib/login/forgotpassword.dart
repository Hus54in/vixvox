
import 'package:email_validator/email_validator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ForgotPasswordWidget extends StatefulWidget {
  const ForgotPasswordWidget({super.key});

  @override
  State<ForgotPasswordWidget> createState() => _ForgotPasswordWidgetState();
}

class _ForgotPasswordWidgetState extends State<ForgotPasswordWidget> {
  late FocusNode emailAddressFocusNode;
  late TextEditingController emailAddressController;

  final scaffoldKey = GlobalKey<ScaffoldState>();
  
  bool show_conformation = false;

  @override
  void initState() {
    super.initState();
    emailAddressFocusNode = FocusNode();
    emailAddressController = TextEditingController();
  }

  @override
  void dispose() {
    emailAddressFocusNode.dispose();
    emailAddressController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: Color(0xFF15161E),
            size: 30,
          ),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        actions: const [],
        centerTitle: false,
        elevation: 0,
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: Container(
          constraints: const BoxConstraints(
            maxWidth: 570,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              
              const Padding(
                padding: EdgeInsetsDirectional.fromSTEB(16, 0, 0, 0),
                child: Text(
                  'Forgot Password',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    color: Color(0xFF15161E),
                    fontSize: 24,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsetsDirectional.fromSTEB(16, 8, 16, 16),
                child: Text(
                  'We will send you an email with a link to reset your password, please enter the email associated with your account below.',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    color: Color(0xFF606A85),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 16, 0),
                child: SizedBox(
                  width: double.infinity,
                  child: TextFormField(
                    controller: emailAddressController,
                    focusNode: emailAddressFocusNode,
                    autovalidateMode: AutovalidateMode.onUserInteraction, validator: (email) {
                                    if (email != null && !EmailValidator.validate(email)) {
                                        return 'Enter a valid email';
                                    }
                                    return null;
                                  },
                    autofillHints: const [AutofillHints.email],
                    obscureText: false,
                    decoration: InputDecoration(
                      labelText: 'Your email address...',
                      labelStyle: const TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        color: Color(0xFF606A85),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      hintText: 'Enter your email...',
                      hintStyle: const TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        color: Color(0xFF606A85),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(
                          color: Color(0xFFE5E7EB),
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(
                          color: Color(0xFF6F61EF),
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderSide: const BorderSide(
                          color: Color(0xFFFF5963),
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderSide: const BorderSide(
                          color: Color(0xFFFF5963),
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsetsDirectional.fromSTEB(24, 24, 20, 24),
                    ),
                    style: const TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      color: Color(0xFF15161E),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: null,
                    keyboardType: TextInputType.emailAddress,
                  ),
                ),
              ),
              if (show_conformation)
              Padding(padding: const EdgeInsetsDirectional.fromSTEB(16, 24, 16, 0),
                child:
              Text(
                "Email sent to ${emailAddressController.text}. Please check your inbox or your spam folder.",
                  style: const TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    color: Color(0xFF606A85),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Align(
                alignment: const AlignmentDirectional(0, 0),
                child: Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(16, 24, 16, 0),
                  
                  child: TextButton(

                    onPressed: () async {
                      if (emailAddressController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Email required!',
                            ),
                          ),
                        );
                        return;
                      }
                      resetPassword();
                    },
                    
                    style: TextButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 55, 35, 234),
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    
                    child: const Text(
                      'Send Link',
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        color: Colors.white,
                        fontSize: 16,
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
    );
  }

  Future resetPassword() async{
    await FirebaseAuth.instance.sendPasswordResetEmail(email: emailAddressController.text.trim());
    setState(() {
      show_conformation = true;
    });
  }

}
