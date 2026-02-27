import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../services/firebase_service.dart';
import '../models/image_metadata.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ImagesScreen extends StatefulWidget {
  const ImagesScreen({super.key});

  @override
  State<ImagesScreen> createState() => ImagesScreenState();
}

class ImagesScreenState extends State<ImagesScreen> {
  final FirebaseService firebaseService = FirebaseService();
  File? selectedImage;
  bool isUploading = false;
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController editDescriptionController = TextEditingController();

  Future<void> pickAndUploadImage(ImageSource source) async {
    final XFile? pickedFile = await firebaseService.pickImage(source);
    if (pickedFile != null) {
      setState(() {
        selectedImage = File(pickedFile.path);
      });
      if (mounted) showUploadDialog();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image selection cancelled.')),
        );
      }
    }
  }

  Future<void> showUploadDialog() async {
    descriptionController.clear();
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Upload Image'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                selectedImage != null
                    ? Image.file(selectedImage!, height: 150, fit: BoxFit.cover)
                    : const Text('No image selected.'),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Optional: Image Description',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                setState(() {
                  selectedImage = null;
                });
                Navigator.of(dialogContext).pop();
              },
            ),
            ElevatedButton(
              onPressed: selectedImage == null || isUploading
                  ? null
                  : () {
                      Navigator.of(dialogContext).pop();
                      uploadImageWithMetadata();
                    },
              child: isUploading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Upload'),
            ),
          ],
        );
      },
    );
  }

  Future<void> uploadImageWithMetadata() async {
    if (selectedImage == null) return;
    setState(() {
      isUploading = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Uploading image...')),
    );

    try {
      final String fileName = 'img_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final String? imageUrl = await firebaseService.uploadImage(selectedImage!, fileName);

      if (imageUrl != null) {
        final ImageMetadata metadata = ImageMetadata(
          id: '', // Firestore generates this
          imageUrl: imageUrl,
          timestamp: Timestamp.now(),
          description: descriptionController.text.trim(),
        );
        await firebaseService.saveImageMetadata(metadata);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Image uploaded successfully!'), backgroundColor: Colors.green),
          );
        }
      } else {
        throw Exception('Failed to get image URL.');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: ${e.toString().replaceFirst("Exception: ", "")}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        isUploading = false;
        selectedImage = null;
        descriptionController.clear();
      });
    }
  }

  void showImageOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext bc) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Pick from Gallery'),
                onTap: () {
                  Navigator.of(context).pop();
                  pickAndUploadImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Take a Picture'),
                onTap: () {
                  Navigator.of(context).pop();
                  pickAndUploadImage(ImageSource.camera);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> deleteImage(ImageMetadata imageMeta) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Image?'),
          content: const Text('Are you sure you want to delete this image and its metadata? This action cannot be undone.'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      setState(() => isUploading = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Deleting image...')),
      );
      try {
        await firebaseService.deleteImage(imageMeta.id, imageMeta.imageUrl);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Image deleted successfully!'), backgroundColor: Colors.green),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Deletion failed: ${e.toString().replaceFirst("Exception: ", "")}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        setState(() => isUploading = false);
      }
    }
  }

  Future<void> showEditMetadataDialog(ImageMetadata imageMeta) async {
    editDescriptionController.text = imageMeta.description;
    final newDescription = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit Description'),
          content: TextField(
            controller: editDescriptionController,
            decoration: const InputDecoration(labelText: 'Image Description'),
            maxLines: 2,
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(editDescriptionController.text.trim());
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (newDescription != null && newDescription != imageMeta.description) {
      setState(() => isUploading = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Updating metadata...')),
      );
      try {
        await firebaseService.updateImageMetadata(imageMeta.id, newDescription);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Metadata updated successfully!'), backgroundColor: Colors.green),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Update failed: ${e.toString().replaceFirst("Exception: ", "")}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        setState(() => isUploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Uploaded Images'),
      ),
      body: StreamBuilder<List<ImageMetadata>>(
        stream: firebaseService.getImageMetadataStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.image_not_supported_outlined, size: 60, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No images uploaded yet.', style: TextStyle(fontSize: 18)),
                  SizedBox(height: 8),
                  Text('Tap the button to upload an image.', style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }
          final images = snapshot.data!;
          return GridView.builder(
            padding: const EdgeInsets.all(8.0),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 8.0,
              mainAxisSpacing: 8.0,
              childAspectRatio: 0.8,
            ),
            itemCount: images.length,
            itemBuilder: (context, index) {
              final imageMeta = images[index];
              return Card(
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: Image.network(
                        imageMeta.imageUrl,
                        fit: BoxFit.cover,
                        loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) => const Center(
                          child: Icon(Icons.broken_image, size: 40, color: Colors.grey),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            imageMeta.description.isNotEmpty ? imageMeta.description : 'No description',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat('MMM d, yyyy a').format(imageMeta.timestamp.toDate()),
                            style: TextStyle(fontSize: 10, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    ButtonBar(
                      alignment: MainAxisAlignment.spaceEvenly,
                      buttonPadding: EdgeInsets.zero,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, size: 20, color: Colors.blue),
                          onPressed: isUploading ? null : () => showEditMetadataDialog(imageMeta),
                          tooltip: 'Edit Description',
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, size: 20, color: Colors.redAccent),
                          onPressed: isUploading ? null : () => deleteImage(imageMeta),
                          tooltip: 'Delete Image',
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: isUploading ? null : () => showImageOptions(context),
        label: isUploading ? const Text('Processing...') : const Text('Add Image'),
        icon: isUploading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : const Icon(Icons.add_a_photo),
        tooltip: 'Upload new image',
      ),
    );
  }
}