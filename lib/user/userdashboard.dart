import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart'; // Required for kIsWeb
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class JobDashboarduser extends StatefulWidget {
  final String uid;

  JobDashboarduser({required this.uid});

  @override
  _JobDashboarduserState createState() => _JobDashboarduserState();
}

class _JobDashboarduserState extends State<JobDashboarduser> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  TextEditingController _searchController = TextEditingController();
  String searchQuery = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Job Dashboard', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search by Job Title',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value.toLowerCase();
                });
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('jobs').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Text('No Jobs Available', style: TextStyle(fontSize: 16)));
                }

                List<Map<String, dynamic>> allJobs = [];
                for (var doc in snapshot.data!.docs) {
                  Map<String, dynamic> jobs = doc['jobs'];
                  allJobs.addAll(jobs.values.map((e) => Map<String, dynamic>.from(e)));
                }

                List<Map<String, dynamic>> filteredJobs = allJobs.where((job) {
                  return job['title'].toLowerCase().contains(searchQuery);
                }).toList();

                return ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: filteredJobs.length,
                  itemBuilder: (context, index) {
                    var job = filteredJobs[index];
                    DateTime createdAt = (job['createdAt'] as Timestamp).toDate();
                    String formattedDate = DateFormat('yyyy-MM-dd').format(createdAt);

                    return Card(
                      elevation: 4,
                      margin: EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(job['title'], style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            SizedBox(height: 4),
                            Text(job['companyName'], style: TextStyle(fontSize: 16, color: Colors.grey[700])),
                            SizedBox(height: 4),
                            Text('Posted on: $formattedDate', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                            SizedBox(height: 10),
                            Align(
                              alignment: Alignment.centerRight,
                              child: ElevatedButton(
                                onPressed: () {
                                  _showApplyDialog(context, job['companyName'], job['title']);
                                },
                                style: ElevatedButton.styleFrom(
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  backgroundColor: Colors.blue,
                                ),
                                child: Text('Apply', style: TextStyle(color: Colors.white)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showApplyDialog(BuildContext context, String companyName, String jobTitle) {
    Uint8List? fileBytes;
    File? resumeFile;
    String? fileName;
    bool isUploading = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Apply for $jobTitle'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton(
                    onPressed: () async {
                      FilePickerResult? result = await FilePicker.platform.pickFiles(
                        type: FileType.custom,
                        allowedExtensions: ['pdf'],
                      );

                      if (result != null) {
                        setState(() {
                          fileName = result.files.single.name;

                          if (kIsWeb) {
                            fileBytes = result.files.single.bytes; // Web uses bytes
                          } else {
                            resumeFile = File(result.files.single.path!); // Mobile uses File
                          }
                        });
                      }
                    },
                    child: Text(fileName == null ? 'Upload Resume' : 'Resume Selected'),
                  ),
                  if (fileName != null) Text(fileName!, style: TextStyle(color: Colors.green)),
                  SizedBox(height: 10),
                  if (isUploading) CircularProgressIndicator(),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: fileName == null
                      ? null
                      : () async {
                    setState(() {
                      isUploading = true;
                    });

                    try {
                      // Fetch user data
                      DocumentSnapshot userDoc =
                      await _firestore.collection('user').doc(widget.uid).get();
                      Map<String, dynamic>? userData =
                      userDoc.data() as Map<String, dynamic>?;

                      if (userData == null) {
                        throw Exception("User data not found");
                      }

                      // Construct the file name
                      String storagePath =
                          'resumes/${companyName}/${userData['name']}/${jobTitle}/${DateTime.now().millisecondsSinceEpoch}.pdf';

                      print("Before upload");

                      // Upload resume to Firebase Storage
                      TaskSnapshot snapshot;
                      if (kIsWeb) {
                        snapshot = await _storage.ref(storagePath).putData(fileBytes!);
                      } else {
                        snapshot = await _storage.ref(storagePath).putFile(resumeFile!);
                      }

                      print("After upload");

                      // Retrieve download URL
                      String downloadURL = await snapshot.ref.getDownloadURL();
                      print("Download URL: $downloadURL");

                      // Store application data in Firestore
                      await _firestore
                          .collection(companyName) // Company name as collection
                          .doc(jobTitle)
                          .collection("applications")
                          .add({
                        'userId': widget.uid,
                        'name': userData['name'],
                        'email': userData['email'],
                        'education': userData['education'],
                        'experience_months':userData['experience_months'],
                        'experience_years': userData['experience_years'],
                        'skills': userData['skills'],
                        'jobTitle': jobTitle,
                        'resumeUrl': downloadURL,
                        'appliedAt': FieldValue.serverTimestamp(),
                      });

                      print("Data saved successfully");

                      setState(() {
                        isUploading = false;
                      });

                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Application Submitted Successfully!')),
                      );
                    } catch (e) {
                      setState(() {
                        isUploading = false;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $e')),
                      );
                    }
                  },
                  child: Text('Submit'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
