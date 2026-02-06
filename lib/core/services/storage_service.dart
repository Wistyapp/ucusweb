import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../constants/app_constants.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _imagePicker = ImagePicker();
  final Uuid _uuid = const Uuid();

  // Pick image from gallery
  Future<XFile?> pickImageFromGallery({
    int maxWidth = AppConstants.maxImageWidth,
    int maxHeight = AppConstants.maxImageHeight,
    int imageQuality = 80,
  }) async {
    try {
      final image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: maxWidth.toDouble(),
        maxHeight: maxHeight.toDouble(),
        imageQuality: imageQuality,
      );
      return image;
    } catch (e) {
      print('Error picking image from gallery: $e');
      return null;
    }
  }

  // Pick image from camera
  Future<XFile?> pickImageFromCamera({
    int maxWidth = AppConstants.maxImageWidth,
    int maxHeight = AppConstants.maxImageHeight,
    int imageQuality = 80,
  }) async {
    try {
      final image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: maxWidth.toDouble(),
        maxHeight: maxHeight.toDouble(),
        imageQuality: imageQuality,
      );
      return image;
    } catch (e) {
      print('Error picking image from camera: $e');
      return null;
    }
  }

  // Pick multiple images
  Future<List<XFile>> pickMultipleImages({
    int maxWidth = AppConstants.maxImageWidth,
    int maxHeight = AppConstants.maxImageHeight,
    int imageQuality = 80,
    int limit = AppConstants.maxImagesPerFacility,
  }) async {
    try {
      final images = await _imagePicker.pickMultiImage(
        maxWidth: maxWidth.toDouble(),
        maxHeight: maxHeight.toDouble(),
        imageQuality: imageQuality,
        limit: limit,
      );
      return images;
    } catch (e) {
      print('Error picking multiple images: $e');
      return [];
    }
  }

  // Upload file to Firebase Storage
  Future<UploadResult> uploadFile({
    required String filePath,
    required String storagePath,
    String? fileName,
  }) async {
    try {
      final file = File(filePath);
      final name = fileName ?? '${_uuid.v4()}_${DateTime.now().millisecondsSinceEpoch}';
      final extension = filePath.split('.').last;
      final fullPath = '$storagePath/$name.$extension';

      final ref = _storage.ref().child(fullPath);
      final uploadTask = ref.putFile(
        file,
        SettableMetadata(
          contentType: _getContentType(extension),
        ),
      );

      // Listen to upload progress
      uploadTask.snapshotEvents.listen((event) {
        final progress = event.bytesTransferred / event.totalBytes;
        print('Upload progress: ${(progress * 100).toStringAsFixed(0)}%');
      });

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      return UploadResult(
        success: true,
        url: downloadUrl,
        storagePath: fullPath,
        fileName: '$name.$extension',
      );
    } catch (e) {
      return UploadResult(
        success: false,
        error: 'Erreur lors du téléchargement: ${e.toString()}',
      );
    }
  }

  // Upload XFile (from image picker)
  Future<UploadResult> uploadXFile({
    required XFile file,
    required String storagePath,
    String? fileName,
  }) async {
    return uploadFile(
      filePath: file.path,
      storagePath: storagePath,
      fileName: fileName,
    );
  }

  // Upload multiple files
  Future<List<UploadResult>> uploadMultipleFiles({
    required List<XFile> files,
    required String storagePath,
  }) async {
    final results = <UploadResult>[];

    for (final file in files) {
      final result = await uploadXFile(
        file: file,
        storagePath: storagePath,
      );
      results.add(result);
    }

    return results;
  }

  // Upload profile image
  Future<UploadResult> uploadProfileImage({
    required XFile image,
    required String userId,
  }) async {
    return uploadXFile(
      file: image,
      storagePath: '${StoragePaths.coachProfiles}/$userId',
      fileName: 'profile',
    );
  }

  // Upload facility images
  Future<List<UploadResult>> uploadFacilityImages({
    required List<XFile> images,
    required String facilityId,
  }) async {
    return uploadMultipleFiles(
      files: images,
      storagePath: '${StoragePaths.facilityImages}/$facilityId',
    );
  }

  // Upload review photos
  Future<List<UploadResult>> uploadReviewPhotos({
    required List<XFile> photos,
    required String reviewId,
  }) async {
    return uploadMultipleFiles(
      files: photos,
      storagePath: '${StoragePaths.reviewPhotos}/$reviewId',
    );
  }

  // Upload message attachment
  Future<UploadResult> uploadMessageAttachment({
    required XFile file,
    required String conversationId,
  }) async {
    return uploadXFile(
      file: file,
      storagePath: '${StoragePaths.messageAttachments}/$conversationId',
    );
  }

  // Delete file from storage
  Future<bool> deleteFile(String storagePath) async {
    try {
      final ref = _storage.ref().child(storagePath);
      await ref.delete();
      return true;
    } catch (e) {
      print('Error deleting file: $e');
      return false;
    }
  }

  // Delete multiple files
  Future<void> deleteMultipleFiles(List<String> storagePaths) async {
    for (final path in storagePaths) {
      await deleteFile(path);
    }
  }

  // Get download URL for existing file
  Future<String?> getDownloadUrl(String storagePath) async {
    try {
      final ref = _storage.ref().child(storagePath);
      return await ref.getDownloadURL();
    } catch (e) {
      print('Error getting download URL: $e');
      return null;
    }
  }

  // Get content type from extension
  String _getContentType(String extension) {
    switch (extension.toLowerCase()) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'pdf':
        return 'application/pdf';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      default:
        return 'application/octet-stream';
    }
  }
}

class UploadResult {
  final bool success;
  final String? url;
  final String? storagePath;
  final String? fileName;
  final String? error;

  UploadResult({
    required this.success,
    this.url,
    this.storagePath,
    this.fileName,
    this.error,
  });
}
