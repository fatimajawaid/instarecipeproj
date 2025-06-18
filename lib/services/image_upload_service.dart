import 'dart:io';
import 'dart:typed_data';
import 'dart:async';
import 'dart:convert';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

class ImageUploadService {
  static final FirebaseStorage _storage = FirebaseStorage.instance;
  static final ImagePicker _picker = ImagePicker();

  // Pick image from gallery or camera
  static Future<XFile?> pickImage({
    required ImageSource source,
    required BuildContext context,
  }) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 75,
        maxWidth: 1024,
        maxHeight: 1024,
      );

      return pickedFile;
    } catch (e) {
      debugPrint('Error picking image: $e');
      return null;
    }
  }

  // Upload image to Firebase Storage
  static Future<String?> uploadImage({
    required XFile imageFile,
    required String recipeName,
  }) async {
    try {
      // TEMPORARY WORKAROUND: Convert image to base64 data URL for testing
      if (kIsWeb) {
        debugPrint('TEMPORARY: Converting image to base64 data URL for web testing');
        
        // Read image bytes
        final Uint8List bytes = await imageFile.readAsBytes();
        debugPrint('Image size: ${bytes.length} bytes');
        
        // Convert to base64
        final String base64String = base64Encode(bytes);
        
        // Create data URL (this allows the image to be displayed without external hosting)
        final String dataUrl = 'data:image/jpeg;base64,$base64String';
        
        // Simulate upload time
        await Future.delayed(Duration(seconds: 1));
        
        debugPrint('Generated base64 data URL (${base64String.length} characters)');
        return dataUrl;
      }
      
      // Original Firebase upload code (for when Firebase is properly configured)
      // Create a unique filename
      final String fileName = 'recipes/${DateTime.now().millisecondsSinceEpoch}_${recipeName.toLowerCase().replaceAll(' ', '_')}.jpg';
      
      debugPrint('Starting upload to Firebase Storage: $fileName');
      
      // Upload to Firebase Storage
      final Reference ref = _storage.ref().child(fileName);
      
      late UploadTask uploadTask;
      
      if (kIsWeb) {
        // For web, use bytes
        final Uint8List bytes = await imageFile.readAsBytes();
        debugPrint('Image size: ${bytes.length} bytes');
        uploadTask = ref.putData(bytes);
      } else {
        // For mobile, use file
        final File file = File(imageFile.path);
        uploadTask = ref.putFile(file);
      }
      
      // Add timeout to prevent infinite waiting
      final TaskSnapshot snapshot = await uploadTask.timeout(
        Duration(seconds: 30),
        onTimeout: () {
          debugPrint('Upload timeout - cancelling task');
          uploadTask.cancel();
          throw TimeoutException('Upload timeout after 30 seconds');
        },
      );
      
      final String downloadUrl = await snapshot.ref.getDownloadURL();
      debugPrint('Upload successful: $downloadUrl');
      
      return downloadUrl;
    } catch (e) {
      debugPrint('Error uploading image: $e');
      
      // TEMPORARY FALLBACK: Try to convert to base64 if Firebase fails
      if (kIsWeb) {
        try {
          debugPrint('TEMPORARY: Falling back to base64 conversion');
          final Uint8List bytes = await imageFile.readAsBytes();
          final String base64String = base64Encode(bytes);
          final String dataUrl = 'data:image/jpeg;base64,$base64String';
          return dataUrl;
        } catch (e2) {
          debugPrint('Failed to convert to base64: $e2');
          return 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=400&h=400&fit=crop';
        }
      }
      
      return null;
    }
  }

  // Delete image from Firebase Storage
  static Future<bool> deleteImage(String imageUrl) async {
    try {
      final Reference ref = _storage.refFromURL(imageUrl);
      await ref.delete();
      return true;
    } catch (e) {
      debugPrint('Error deleting image: $e');
      return false;
    }
  }

  // Show image source selection dialog
  static void showImageSourceDialog({
    required BuildContext context,
    required Function(XFile?) onImageSelected,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFFfbf9f9),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFF8d6658),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              
              Text(
                'Select Image Source',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF191210),
                ),
              ),
              const SizedBox(height: 20),
              
              // Camera option
              ListTile(
                leading: const Icon(
                  Icons.camera_alt,
                  color: Color(0xFFef6a42),
                  size: 28,
                ),
                title: const Text(
                  'Camera',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF191210),
                  ),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  final XFile? image = await pickImage(
                    source: ImageSource.camera,
                    context: context,
                  );
                  onImageSelected(image);
                },
              ),
              
              // Gallery option
              ListTile(
                leading: const Icon(
                  Icons.photo_library,
                  color: Color(0xFFef6a42),
                  size: 28,
                ),
                title: const Text(
                  'Gallery',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF191210),
                  ),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  final XFile? image = await pickImage(
                    source: ImageSource.gallery,
                    context: context,
                  );
                  onImageSelected(image);
                },
              ),
              
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
} 