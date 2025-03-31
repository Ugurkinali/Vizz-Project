class Announcement {
  final String id;
  final String title;
  final String content;
  final String? imageUrl;
  final String? link;
  final String author;
  final DateTime publishDate;

  Announcement({
    required this.id,
    required this.title,
    required this.content,
    this.imageUrl,
    this.link,
    required this.author,
    required this.publishDate,
  });

  factory Announcement.fromMap(Map<String, dynamic> map, String id) {
    return Announcement(
      id: id,
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      imageUrl: map['imageUrl'],
      link: map['link'],
      author: map['author'] ?? '',
      publishDate: map['publishDate']?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'content': content,
      'imageUrl': imageUrl,
      'link': link,
      'author': author,
      'publishDate': publishDate,
    };
  }
}
