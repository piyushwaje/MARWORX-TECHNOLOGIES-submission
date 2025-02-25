import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';


class JobDashboard extends StatefulWidget {
  final String uid;

  JobDashboard({required this.uid});

  @override
  _JobDashboardState createState() => _JobDashboardState();
}

class _JobDashboardState extends State<JobDashboard> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = Uuid();

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
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

class ApplicationsPage extends StatelessWidget {
  final String companyName;
  final String jobTitle;

  ApplicationsPage({required this.companyName, required this.jobTitle});

  void _launchResumeUrl(BuildContext context, String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not launch URL')),
      );
    }
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
                        onPressed: () => _launchResumeUrl(context, application['resumeUrl']),
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
