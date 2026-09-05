import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_windowmanager/flutter_windowmanager.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

// --- Main Dashboard Widget ---
class OutsideSalesDashboard extends StatefulWidget {
  const OutsideSalesDashboard({Key? key}) : super(key: key);

  @override
  State<OutsideSalesDashboard> createState() => _OutsideSalesDashboardState();
}

class _OutsideSalesDashboardState extends State<OutsideSalesDashboard> {
  int _currentIndex = 1; // Defaulting to Assigned Customers view
  final AudioRecorder _audioRecorder = AudioRecorder();
  final ImagePicker _imagePicker = ImagePicker();
  bool _isRecording = false;
  bool _isCompletingVisit = false;

  @override
  void initState() {
    super.initState();
    _preventScreenshots();
  }

  Future<void> _preventScreenshots() async {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      await FlutterWindowManager.addFlags(FlutterWindowManager.FLAG_SECURE);
    }
  }

  @override
  void dispose() {
    _audioRecorder.dispose();
    super.dispose();
  }

  // Helper function to mask phone numbers
  String _maskPhone(String phone) {
    if (phone.length <= 4) return phone;
    return '**${phone.substring(phone.length - 4)}';
  }

  // Logout Logic
  Future<void> _startVisitRecording(String visitId) async {
    if (_isRecording) return;

    try {
      if (!await _audioRecorder.hasPermission()) {
        _showMessage('Microphone permission is required to record this visit.');
        return;
      }

      final directory = await getApplicationDocumentsDirectory();
      final path = '${directory.path}/visit_$visitId.m4a';
      await _audioRecorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc),
        path: path,
      );
      if (mounted) setState(() => _isRecording = true);
    } catch (error) {
      _showMessage('Unable to start recording: $error');
    }
  }

  Future<void> _completeVisit(String visitId, String customerName) async {
    if (_isCompletingVisit) return;
    setState(() => _isCompletingVisit = true);

    try {
      final audioPath = _isRecording ? await _audioRecorder.stop() : null;
      if (mounted) setState(() => _isRecording = false);
      if (audioPath == null) {
        _showMessage(
          'Start recording at the location before completing the visit.',
        );
        return;
      }

      final selfie = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );
      if (selfie == null) {
        _showMessage(
          'Selfie capture was cancelled. The visit was not completed.',
        );
        return;
      }

      final storage = FirebaseStorage.instance;
      final audioReference = storage.ref('visits/$visitId/recording.m4a');
      await audioReference.putData(
        await XFile(audioPath).readAsBytes(),
        SettableMetadata(contentType: 'audio/mp4'),
      );
      final recordingUrl = await audioReference.getDownloadURL();
      final visitReference = FirebaseFirestore.instance
          .collection('visits')
          .doc(visitId);

      // Persist the recording metadata as soon as the audio upload succeeds.
      await visitReference.update({
        'recordingPath': audioReference.fullPath,
        'recordingUrl': recordingUrl,
        'recordingUploadedAt': FieldValue.serverTimestamp(),
      });

      final selfieReference = storage.ref('visits/$visitId/selfie.jpg');
      await selfieReference.putData(
        await selfie.readAsBytes(),
        SettableMetadata(contentType: 'image/jpeg'),
      );

      await visitReference.update({
        'completedAt': FieldValue.serverTimestamp(),
        'status': 'visit_completed',
        'selfiePath': selfieReference.fullPath,
      });
      _showMessage('$customerName visit completed.');
    } catch (error) {
      _showMessage('Unable to complete the visit: $error');
    } finally {
      if (mounted) setState(() => _isCompletingVisit = false);
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _handleLogout() async {
    try {
      if (_isRecording) {
        await _audioRecorder.stop();
        _isRecording = false;
      }
      await FirebaseAuth.instance.signOut();
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    } catch (e) {
      _showMessage('Error logging out: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1B22), // Dark slate/charcoal
      appBar: AppBar(
        title: const Text('Real Estate', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF2D63ED), // Vibrant blue
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF2D63ED), // Solid blue
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white54,
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.phone), label: 'Calls'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  // Switch between the 3 views based on bottom nav index
  Widget _buildBody() {
    switch (_currentIndex) {
      case 0:
        return _buildHomeView();
      case 1:
        return _buildAssignedCustomersView();
      case 2:
        return _buildProfileView();
      default:
        return _buildAssignedCustomersView();
    }
  }

  // View 0: Home placeholder
  Widget _buildHomeView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.real_estate_agent, size: 100, color: Color(0xFF2D63ED)),
          SizedBox(height: 16),
          Text(
            'Home Dashboard',
            style: TextStyle(color: Colors.white, fontSize: 24),
          ),
        ],
      ),
    );
  }

  // View 1: Assigned Customers List
  Widget _buildAssignedCustomersView() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null)
      return _buildMessage('Please sign in to view assigned customers.');

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('visits')
          .where('outsideSalesId', isEqualTo: uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _buildMessage('Unable to load assigned customers.');
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final visits = snapshot.data?.docs ?? [];
        if (visits.isEmpty) return _buildMessage('No assigned customers yet.');

        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: visits.length,
          itemBuilder: (context, index) {
            final visit = visits[index].data();
            final customerId = visit['customerId'] as String?;
            if (customerId == null || customerId.isEmpty) {
              return _buildMessage('This visit has no customer details.');
            }

            return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              future: FirebaseFirestore.instance
                  .collection('customers')
                  .doc(customerId)
                  .get(),
              builder: (context, customerSnapshot) {
                if (customerSnapshot.hasError) {
                  return _buildMessage('Unable to load customer details.');
                }
                if (customerSnapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.only(bottom: 12.0),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final customer = customerSnapshot.data?.data();
                if (customer == null)
                  return _buildMessage('Customer record not found.');
                final name = customer['name'] as String? ?? 'Unknown customer';
                final phone = customer['phone'] as String? ?? 'Unavailable';
                final scheduledAt = _formatDate(visit['scheduledAt']);

                return Container(
                  margin: const EdgeInsets.only(bottom: 12.0),
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: const Color(0xFF242630), // Dark grey
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Customer Details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Name: $name',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Phone: ${_maskPhone(phone)}',
                              style: const TextStyle(color: Colors.white70),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Event Time: $scheduledAt',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Action Buttons
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.phone,
                              color: Color(0xFF2D63ED),
                            ),
                            onPressed: () {
                              // TODO: Implement url_launcher for phone dialer
                              _showMessage('Calling $phone');
                            },
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.location_on,
                              color: Colors.grey,
                            ),
                            onPressed: () {
                              // TODO: Implement Reached Location logic (Update Firestore + Start Audio)
                              _startVisitRecording(visits[index].id);
                            },
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.camera_alt,
                              color: Colors.green,
                            ),
                            onPressed: () {
                              // TODO: Implement Completed Visit logic (Stop Audio + Upload Selfie)
                              _completeVisit(visits[index].id, name);
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  // View 2: Profile View
  Widget _buildProfileView() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null)
      return _buildMessage('Please sign in to view your profile.');

    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: FirebaseFirestore.instance.collection('employees').doc(uid).get(),
      builder: (context, snapshot) {
        if (snapshot.hasError)
          return _buildMessage('Unable to load your profile.');
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final profile = snapshot.data?.data();
        if (profile == null) return _buildMessage('Profile not found.');
        final name = profile['name'] as String? ?? 'Unknown';
        final email = profile['email'] as String? ?? 'Unavailable';
        final phone = profile['phone'] as String? ?? 'Unavailable';
        final profileImageUrl = profile['profileImageUrl'] as String?;

        return SingleChildScrollView(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              vertical: 40.0,
              horizontal: 20.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Color(0xFF009688), // Green accent
                    shape: BoxShape.circle,
                    image: profileImageUrl != null && profileImageUrl.isNotEmpty
                        ? DecorationImage(
                            image: NetworkImage(profileImageUrl),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 24),
                // Username
                Text(
                  'Username: $name',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                // Profile Details
                _buildProfileDetailRow('Email', email),
                _buildProfileDetailRow('Phone', phone),
                const SizedBox(height: 40),
                // Logout Button
                SizedBox(
                  width: 150,
                  height: 45,
                  child: ElevatedButton(
                    onPressed: _handleLogout,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8B5CF6), // Purple
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24.0),
                      ),
                    ),
                    child: const Text(
                      'Logout',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMessage(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Text(message, style: const TextStyle(color: Colors.white70)),
      ),
    );
  }

  String _formatDate(dynamic value) {
    if (value is Timestamp) return value.toDate().toLocal().toString();
    return value?.toString() ?? 'Unavailable';
  }

  // Helper widget for profile details
  Widget _buildProfileDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        '$label: $value',
        style: const TextStyle(color: Colors.white70, fontSize: 14),
      ),
    );
  }
}
