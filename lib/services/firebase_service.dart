import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import '../models/image_metadata.dart';

class FirebaseService {
  final firebase_storage.FirebaseStorage _storage = firebase_storage.FirebaseStorage.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImagePicker _picker = ImagePicker();

  Future<XFile?> pickImage(ImageSource source) async {
    try {
      return await _picker.pickImage(source: source);
    } catch (e) {
      print('Error picking image: $e');
      return null;
    }
  }

  Future<String?> uploadImage(File imageFile, String fileName) async {
    try {
      firebase_storage.Reference ref = _storage.ref().child('uploads/$fileName');
      firebase_storage.UploadTask uploadTask = ref.putFile(imageFile);
      firebase_storage.TaskSnapshot snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  Future<void> saveImageMetadata(ImageMetadata metadata) async {
    try {
      await _firestore.collection('images').add(metadata.toJson());
    } catch (e) {
      print('Error saving metadata: $e');
      throw Exception('Failed to save metadata');
    }
  }

  Stream<List<ImageMetadata>> getImageMetadataStream() {
    return _firestore.collection('images').orderBy('timestamp', descending: true).snapshots().map((snapshot) {
      try {
        return snapshot.docs.map((doc) => ImageMetadata.fromFirestore(doc)).toList();
      } catch (e) {
        print('Error fetching metadata stream: $e');
        return [];
      }
    });
  }

  Future<void> deleteImage(String imageId, String imageUrl) async {
    try {
      await _firestore.collection('images').doc(imageId).delete();
      firebase_storage.Reference photoRef = _storage.refFromURL(imageUrl);
      await photoRef.delete();
    } catch (e) {
      print('Error deleting image: $e');
      throw Exception('Failed to delete image');
    }
  }

  Future<void> updateImageMetadata(String imageId, String newDescription) async {
    try {
      await _firestore.collection('images').doc(imageId).update({
        'description': newDescription,
      });
    } catch (e) {
      print('Error updating metadata: $e');
      throw Exception('Failed to update metadata');
    }
  }
}