import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:url_launcher/url_launcher.dart';

class JobDashboard extends StatefulWidget {
  final String uid;

  JobDashboard({required this.uid});

  @override
  _JobDashboardState createState() => _JobDashboardState();
}

class _JobDashboardState extends State<JobDashboard> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = Uuid();

  void _addOrEditJob({String? jobId, String? existingTitle, String? existingDescription, String? existingSalary, String? existingCompany}) {
    TextEditingController titleController = TextEditingController(text: existingTitle);
    TextEditingController descriptionController = TextEditingController(text: existingDescription);
    TextEditingController salaryController = TextEditingController(text: existingSalary);
    TextEditingController companyController = TextEditingController(text: existingCompany);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(jobId == null ? 'Add Job' : 'Edit Job'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: titleController, decoration: InputDecoration(labelText: 'Job Title')),
              TextField(controller: descriptionController, decoration: InputDecoration(labelText: 'Job Description')),
              TextField(controller: salaryController, decoration: InputDecoration(labelText: 'Salary')),
              TextField(controller: companyController, decoration: InputDecoration(labelText: 'Company Name')),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.isNotEmpty &&
                    descriptionController.text.isNotEmpty &&
                    salaryController.text.isNotEmpty &&
                    companyController.text.isNotEmpty) {

                  String newJobId = jobId ?? _uuid.v4();

                  await _firestore.collection('jobs').doc(widget.uid).set({
                    'jobs': {
                      newJobId: {
                        'title': titleController.text,
                        'description': descriptionController.text,
                        'salary': salaryController.text,
                        'companyName': companyController.text,
                        'createdAt': Timestamp.now(),
                      }
                    }
                  }, SetOptions(merge: true));

                  Navigator.pop(context);
                }
              },
              child: Text(jobId == null ? 'Add' : 'Update'),
            ),
          ],
        );
      },
    );
  }

  void _deleteJob(String jobId) async {
    DocumentReference docRef = _firestore.collection('jobs').doc(widget.uid);

    await docRef.update({
      'jobs.$jobId': FieldValue.delete(),
    });
  }

  void _openJobDetails(String jobId, Map<String, dynamic> job) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => JobDetailsScreen(jobId: jobId, job: job),
      ),
    );
  }
  void _navigateToApplications(String companyName, String jobTitle) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ApplicationsPage(companyName: companyName, jobTitle: jobTitle),
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Job Dashboard')),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _firestore.collection('jobs').doc(widget.uid).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists || snapshot.data!['jobs'] == null) {
            return Center(child: Text('No Jobs Available'));
          }

          Map<String, dynamic> jobs = snapshot.data!['jobs'];

          return ListView(
            padding: EdgeInsets.all(16),
            children: jobs.entries.map((entry) {
              String jobId = entry.key;
              var job = entry.value;

              return Card(
                elevation: 4,
                margin: EdgeInsets.only(bottom: 16),
                child: ListTile(
                  title: Text(job['title'], style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(job['description']),
                      SizedBox(height: 5),
                      Text('Salary: ${job['salary']}'),
                      Text('Company: ${job['companyName']}'),
                    ],
                  ),
                  onTap: () => _navigateToApplications(job['companyName'], job['title']),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _addOrEditJob(
                          jobId: jobId,
                          existingTitle: job['title'],
                          existingDescription: job['description'],
                          existingSalary: job['salary'],
                          existingCompany: job['companyName'],
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteJob(jobId),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addOrEditJob(),
        child: Icon(Icons.add),
      ),
    );
  }
}

class JobDetailsScreen extends StatelessWidget {
  final String jobId;
  final Map<String, dynamic> job;

  JobDetailsScreen({required this.jobId, required this.job});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(job['title'])),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Description: ${job['description']}', style: TextStyle(fontSize: 16)),
            SizedBox(height: 10),
            Text('Salary: ${job['salary']}', style: TextStyle(fontSize: 16)),
            SizedBox(height: 10),
            Text('Company: ${job['companyName']}', style: TextStyle(fontSize: 16)),
            SizedBox(height: 20),
            Text('Downloads:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ...?job['downloads']?.map((download) => ListTile(
              title: Text(download['name']),
              trailing: IconButton(
                icon: Icon(Icons.download),
                onPressed: () async {
                  if (await canLaunch(download['url'])) {
                    await launch(download['url']);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Could not open download link')),
                    );
                  }
                },
              ),
            )).toList() ?? [],
          ],
        ),
      ),
    );
  }
}









class ApplicationsPage extends StatelessWidget {
  final String companyName;
  final String jobTitle;

  ApplicationsPage({required this.companyName, required this.jobTitle});



  void downloadFile(String url) async {
    final taskId = await FlutterDownloader.enqueue(
      url: url,
      savedDir: (await getExternalStorageDirectory())!.path,
      showNotification: true,
      openFileFromNotification: true,
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Applications for $jobTitle')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection(companyName)
            .doc(jobTitle)
            .collection('applications')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No Applications Available'));
          }

          return ListView(
            padding: EdgeInsets.all(16),
            children: snapshot.data!.docs.map((doc) {
              var application = doc.data() as Map<String, dynamic>;
              return Card(
                elevation: 4,
                margin: EdgeInsets.only(bottom: 16),
                child: ListTile(
                  title: Text(application['name'] ?? 'Unknown Applicant'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Email: ${application['email']}'),
                      Text('Education: ${application['education']}'),
                      Text('Experience: ${application['experience_years']} years, ${application['experience_months']} months'),
                      Text('Skills: ${application['skills']}'),
                      Text('Job Title: ${application['jobTitle']}'),
                      SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: () => downloadFile(application['resumeUrl']),
                        child: Text('Open Resume'),
                      ),
                      Text('Applied At: ${application['appliedAt']}'),
                    ],
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

