import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vizzapp/models/announcement.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'admin_login.dart';

class AnnouncementWall extends StatefulWidget {
  const AnnouncementWall({super.key});

  @override
  State<AnnouncementWall> createState() => _AnnouncementWallState();
}

class _AnnouncementWallState extends State<AnnouncementWall> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _launchUrl(String url) async {
    if (!url.startsWith('http')) url = 'https://$url';
    if (!await launchUrl(Uri.parse(url))) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: const AssetImage('assets/iec.png'),
                fit: BoxFit.contain,
                colorFilter: ColorFilter.mode(
                  Colors.white.withValues(alpha: 0.2),
                  BlendMode.dstATop,
                ),
              ),
            ),
          ),
          Column(
            children: [
              Container(
                color: Colors.amber,
                height: MediaQuery.of(context).padding.top,
              ),
              _buildHeader(),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream:
                      _firestore
                          .collection('announcements')
                          .orderBy('publishDate', descending: true)
                          .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final announcements =
                        snapshot.data!.docs.map((doc) {
                          return Announcement.fromMap(
                            doc.data() as Map<String, dynamic>,
                            doc.id,
                          );
                        }).toList();

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      itemCount: announcements.length,
                      itemBuilder: (context, index) {
                        return _buildAnnouncementCard(announcements[index]);
                      },
                    );
                  },
                ),
              ),
              _buildSocialButtons(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.amber,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Vızz',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              fontStyle: FontStyle.italic,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.admin_panel_settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AdminLoginPage()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAnnouncementCard(Announcement announcement) {
    return Card(
      color: Colors.white.withValues(alpha: 0.9),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              announcement.title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(announcement.content, style: const TextStyle(fontSize: 16)),
            if (announcement.imageUrl != null) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey[200],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    announcement.imageUrl!,
                    width: double.infinity,
                    height: 200,
                    fit: BoxFit.cover,
                    loadingBuilder: (
                      BuildContext context,
                      Widget child,
                      ImageChunkEvent? loadingProgress,
                    ) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          value:
                              loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                        ),
                      );
                    },
                    errorBuilder: (
                      BuildContext context,
                      Object exception,
                      StackTrace? stackTrace,
                    ) {
                      return Container(
                        color: Colors.grey[200],
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.broken_image,
                                size: 48,
                                color: Colors.grey,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Could not fetch image',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
            if (announcement.link != null) ...[
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () => _launchUrl(announcement.link!),
                child: Text(
                  announcement.link!,
                  style: TextStyle(
                    color: Colors.blue[600],
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  announcement.author,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                Text(
                  _formatDate(announcement.publishDate),
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildSocialButtons() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          const Text(
            'App created by Çankaya EMK',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildSocialButton('assets/instagram.png', () {
                _launchUrl('https://www.instagram.com/emk.cankaya/');
              }),
              _buildSocialButton('assets/linkedin.png', () {
                _launchUrl(
                  'https://www.linkedin.com/in/%C3%A7ankaya%C3%BCniversitesiend%C3%BCstrim%C3%BChendisligi/',
                );
              }),
              _buildSocialButton('assets/twitter.png', () {
                _launchUrl('https://x.com/EMKCANKAYA');
              }),
              _buildSocialButton('assets/whatsapp.png', () {
                _launchUrl('https://chat.whatsapp.com/EUAkBybCCZfIwnGaiuTlAA');
              }),
              _buildSocialButton('assets/youtube.png', () {
                _launchUrl('https://www.youtube.com/@EMKcankaya');
              }),
              _buildSocialButton('assets/iec.png', () {
                _launchUrl('https://ie.cankaya.edu.tr/iec_en.php');
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSocialButton(String assetPath, VoidCallback onPressed) {
    return GestureDetector(
      onTap: onPressed,
      child: Image.asset(assetPath, width: 32, height: 32),
    );
  }
}
