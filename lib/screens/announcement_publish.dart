import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vizzapp/models/announcement.dart';
import 'announcement_wall.dart';

class AnnouncementPublishPage extends StatefulWidget {
  const AnnouncementPublishPage({super.key});

  @override
  State<AnnouncementPublishPage> createState() =>
      _AnnouncementPublishPageState();
}

class _AnnouncementPublishPageState extends State<AnnouncementPublishPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _linkController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _authorController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = false;
  final List<String> _selectedAnnouncements = [];

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _linkController.dispose();
    _imageUrlController.dispose();
    _authorController.dispose();
    super.dispose();
  }

  Future<void> _publishAnnouncement() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final announcement = Announcement(
        id: '',
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        imageUrl:
            _imageUrlController.text.trim().isEmpty
                ? null
                : _convertGoogleDriveLink(_imageUrlController.text.trim()),
        link:
            _linkController.text.trim().isEmpty
                ? null
                : _linkController.text.trim(),
        author: _authorController.text.trim(),
        publishDate: DateTime.now(),
      );

      await _firestore.collection('announcements').add(announcement.toMap());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Announcement published successfully'),
            backgroundColor: Colors.green,
          ),
        );
        _clearForm();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error publishing announcement: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _convertGoogleDriveLink(String url) {
    if (url.contains('drive.google.com/file/d/')) {
      final fileId = url.split('/file/d/')[1].split('/')[0];
      return 'https://drive.google.com/uc?export=view&id=$fileId';
    }
    return url;
  }

  void _clearForm() {
    _formKey.currentState?.reset();
    _titleController.clear();
    _contentController.clear();
    _linkController.clear();
    _imageUrlController.clear();
    _authorController.clear();
  }

  Future<void> _deleteSelectedAnnouncements() async {
    if (_selectedAnnouncements.isEmpty) return;

    try {
      final batch = _firestore.batch();
      for (final id in _selectedAnnouncements) {
        batch.delete(_firestore.collection('announcements').doc(id));
      }
      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Deleted ${_selectedAnnouncements.length} announcements',
            ),
            backgroundColor: Colors.green,
          ),
        );
        setState(() => _selectedAnnouncements.clear());
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting announcements: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setState) => AlertDialog(
                  title: const Text('Delete Announcements'),
                  content: SizedBox(
                    width: double.maxFinite,
                    child: StreamBuilder<QuerySnapshot>(
                      stream:
                          _firestore
                              .collection('announcements')
                              .orderBy('publishDate', descending: true)
                              .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return Text('Error: ${snapshot.error}');
                        }
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Expanded(
                              child: ListView.builder(
                                shrinkWrap: true,
                                itemCount: snapshot.data!.docs.length,
                                itemBuilder: (context, index) {
                                  final doc = snapshot.data!.docs[index];
                                  return CheckboxListTile(
                                    title: Text(doc['title']),
                                    subtitle: Text(
                                      _formatDate(doc['publishDate'].toDate()),
                                    ),
                                    value: _selectedAnnouncements.contains(
                                      doc.id,
                                    ),
                                    onChanged:
                                        (bool? value) => setState(() {
                                          value!
                                              ? _selectedAnnouncements.add(
                                                doc.id,
                                              )
                                              : _selectedAnnouncements.remove(
                                                doc.id,
                                              );
                                        }),
                                    controlAffinity:
                                        ListTileControlAffinity.leading,
                                  );
                                },
                              ),
                            ),
                            if (_selectedAnnouncements.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  '${_selectedAnnouncements.length} selected',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      onPressed: () {
                        _deleteSelectedAnnouncements();
                        Navigator.pop(context);
                      },
                      child: const Text(
                        'Delete',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
          ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/iec.png'),
                fit: BoxFit.contain,
                opacity: 0.2,
              ),
            ),
          ),
          Column(
            children: [
              Container(
                color: Colors.amber,
                height: MediaQuery.of(context).padding.top,
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                color: Colors.amber,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Create Announcement',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: _showDeleteDialog,
                        ),
                        IconButton(
                          icon: const Icon(Icons.exit_to_app),
                          onPressed: () {
                            FirebaseAuth.instance.signOut();
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const AnnouncementWall(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextFormField(
                          controller: _titleController,
                          decoration: const InputDecoration(
                            labelText: 'Announcement Title',
                            border: OutlineInputBorder(),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a title';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _contentController,
                          decoration: const InputDecoration(
                            labelText: 'Announcement Content',
                            border: OutlineInputBorder(),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          maxLines: 5,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter content';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _imageUrlController,
                          decoration: const InputDecoration(
                            labelText: 'Google Drive Image Link (optional)',
                            border: OutlineInputBorder(),
                            hintText: 'Paste shareable link here',
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          validator: (value) {
                            if (value != null &&
                                value.isNotEmpty &&
                                !value.contains('drive.google.com')) {
                              return 'Please use a valid Google Drive link';
                            }
                            return null;
                          },
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Text(
                            'How to use imaging:\n1. Upload image to Google Drive\n2. Set share as → "Anyone with link"\n3. Paste link above',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ),
                        TextFormField(
                          controller: _linkController,
                          decoration: const InputDecoration(
                            labelText: 'External Link (optional)',
                            border: OutlineInputBorder(),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _authorController,
                          decoration: const InputDecoration(
                            labelText: 'Publisher Name',
                            border: OutlineInputBorder(),
                            hintText: 'Enter your name',
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter publisher name';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.amber,
                            ),
                            onPressed: _isLoading ? null : _publishAnnouncement,
                            child:
                                _isLoading
                                    ? const CircularProgressIndicator()
                                    : const Text(
                                      'Publish Announcement',
                                      style: TextStyle(color: Colors.black),
                                    ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
