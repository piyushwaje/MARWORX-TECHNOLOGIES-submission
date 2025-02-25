import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:managejob/user/login.dart';

class SignUpPageuser extends StatefulWidget {
  @override
  _SignUpPageuserState createState() => _SignUpPageuserState();
}

class _SignUpPageuserState extends State<SignUpPageuser> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _educationController = TextEditingController();
  final TextEditingController _skillsController = TextEditingController();
  final TextEditingController _experienceYearsController = TextEditingController();
  final TextEditingController _experienceMonthsController = TextEditingController();

  Future<void> _signUp() async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      String uid = userCredential.user!.uid;

      await _firestore.collection('user').doc(uid).set({
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'uid': uid,
        'education': _educationController.text.trim(),
        'skills': _skillsController.text.trim(),
        'experience_years': int.tryParse(_experienceYearsController.text.trim()) ?? 0,
        'experience_months': int.tryParse(_experienceMonthsController.text.trim()) ?? 0,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Account created successfully!')),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginPageUser()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
    double width = size.width;

    return Scaffold(
      appBar: AppBar(title: Text('User Sign Up'),
      ),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildTextField(_nameController, 'Full Name', Icons.person),
              _buildTextField(_emailController, 'Email', Icons.email, TextInputType.emailAddress),
              _buildTextField(_passwordController, 'Password', Icons.lock, TextInputType.text, ),
              _buildTextField(_educationController, 'Education', Icons.school),
              _buildTextField(_skillsController, 'Skills (comma-separated)', Icons.build),
              _buildTextField(_experienceYearsController, 'Experience (Years)', Icons.timelapse, TextInputType.number),
              _buildTextField(_experienceMonthsController, 'Experience (Months)', Icons.timelapse, TextInputType.number),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _signUp,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 50, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: TextStyle(fontSize: 18),
                ),
                child: Text('Sign Up'),
              ),
              SizedBox(height: 10),
              TextButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => LoginPageUser()),
                  );
                },
                child: Text(
                  'Already have an account? Login',
                  style: TextStyle(fontSize: 16, color: Colors.blueAccent),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, [TextInputType keyboardType = TextInputType.text, bool obscureText = false]) {
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.55,
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.blueAccent),
          filled: true,
          fillColor: Colors.grey[100],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
        keyboardType: keyboardType,
        obscureText: obscureText,
      ),
    );
  }
}
