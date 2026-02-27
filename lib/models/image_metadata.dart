import 'package:cloud_firestore/cloud_firestore.dart';

class ImageMetadata {
  final String id; 
  final String imageUrl;
  final Timestamp timestamp;
  final String description;

  ImageMetadata({
    required this.id,
    required this.imageUrl,
    required this.timestamp,
    this.description = '',
  });

  factory ImageMetadata.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return ImageMetadata(
      id: doc.id,
      imageUrl: data['imageUrl'] ?? '',
      timestamp: data['timestamp'] ?? Timestamp.now(),
      description: data['description'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'imageUrl': imageUrl,
      'timestamp': timestamp,
      'description': description,
    };
  }
}