import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:exif/exif.dart' as exif;
import 'package:image/image.dart' as img;
import 'package:shimmer/shimmer.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A widget that provides virtual try-on functionality
class VirtualTryOn extends StatefulWidget {
  /// API Key for RapidAPI
  final String rapidApiKey;

  /// Optional custom styling for the widget
  final ThemeData? theme;

  /// Optional callback for when the try-on process completes successfully
  final Function(Uint8List)? onTryOnComplete;

  const VirtualTryOn({
    super.key,
    required this.rapidApiKey,
    this.theme,
    this.onTryOnComplete,
  });

  @override
  VirtualTryOnState createState() => VirtualTryOnState();
}

class VirtualTryOnState extends State<VirtualTryOn> {
  File? _clothingImage;
  File? _avatarImage;
  String _avatarSex = 'male';
  bool _isLoading = false;
  dynamic _apiResponse;
  final ImagePicker _picker = ImagePicker();
  bool _showGuidelines = false;

  @override
  void initState() {
    super.initState();
    _loadSavedClothingImage();
  }
  
  // Check for and load any saved clothing image
  Future<void> _loadSavedClothingImage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedImagePath = prefs.getString('clothing_image_path');
      
      if (savedImagePath != null) {
        final file = File(savedImagePath);
        if (await file.exists()) {
          setState(() {
            _clothingImage = file;
          });
          
          // Clear the path after loading to prevent reloading on next visit
          await prefs.remove('clothing_image_path');
          
          // Show a notification to the user
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Clothing image loaded from your selection'),
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      print('Error loading saved clothing image: $e');
    }
  }

  void _showImageSourceDialog(bool isClothing) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Select Image Source',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildImageSourceOption(
                    icon: Icons.camera_alt,
                    label: 'Camera',
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage(isClothing, ImageSource.camera);
                    },
                  ),
                  _buildImageSourceOption(
                    icon: Icons.photo_library,
                    label: 'Gallery',
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage(isClothing, ImageSource.gallery);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageSourceOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 30, color: Theme.of(context).primaryColor),
            const SizedBox(height: 8),
            Text(label),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(bool isClothing, ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 85,
      );
      if (image == null) return;

      final File processedImage = await _processImage(File(image.path));
      setState(() {
        if (isClothing) {
          _clothingImage = processedImage;
        } else {
          _avatarImage = processedImage;
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick image: $e')),
      );
    }
  }

  Future<File> _processImage(File image) async {
    try {
      final bytes = await image.readAsBytes();
      await exif.readExifFromBytes(bytes); // Read EXIF data (triggers auto-correction)

      final compressed = await FlutterImageCompress.compressWithFile(
        image.absolute.path,
        format: CompressFormat.jpeg,
        autoCorrectionAngle: true,
        minHeight: 512,
        minWidth: 512,
        quality: 90,
      );

      if (compressed == null) {
        throw Exception('Failed to compress image');
      }

      return File(image.path)..writeAsBytesSync(compressed);
    } catch (e) {
      // If compression fails, return original image
      debugPrint('Image processing error: $e');
      return image;
    }
  }

  Future<void> _submitTryOn() async {
    if (_clothingImage == null || _avatarImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select both images'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Validate image sizes
    try {
      final clothingSize = await _clothingImage!.length();
      final avatarSize = await _avatarImage!.length();
      if (clothingSize > 5 * 1024 * 1024 || avatarSize > 5 * 1024 * 1024) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Max file size is 5MB'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      // Validate image format
      final clothingBytes = await _clothingImage!.readAsBytes();
      final avatarBytes = await _avatarImage!.readAsBytes();
      final clothingImage = img.decodeImage(clothingBytes);
      final avatarImage = img.decodeImage(avatarBytes);
      if (clothingImage == null || avatarImage == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid image format'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      setState(() {
        _isLoading = true;
        _apiResponse = null;
      });

      final url = Uri.parse('https://try-on-diffusion.p.rapidapi.com/try-on-file');

      final request = http.MultipartRequest('POST', url)
        ..fields['avatar_sex'] = _avatarSex.toLowerCase()
        ..files.add(http.MultipartFile(
          'clothing_image',
          _clothingImage!.readAsBytes().asStream(),
          _clothingImage!.lengthSync(),
          filename: 'clothing.jpg',
          contentType: MediaType('image', 'jpeg'),
        ))
        ..files.add(http.MultipartFile(
          'avatar_image',
          _avatarImage!.readAsBytes().asStream(),
          _avatarImage!.lengthSync(),
          filename: 'avatar.jpg',
          contentType: MediaType('image', 'jpeg'),
        ))
        ..headers.addAll({
          'x-rapidapi-host': 'try-on-diffusion.p.rapidapi.com',
          'x-rapidapi-key': widget.rapidApiKey,
        });

      final response = await request.send();
      final responseBody = await response.stream.toBytes();

      setState(() {
        _isLoading = false;
        _apiResponse = {
          'status': response.statusCode,
          'headers': response.headers,
          'body': responseBody,
        };
      });

      if (response.statusCode == 200 &&
          response.headers['content-type']?.contains('image') == true &&
          widget.onTryOnComplete != null) {
        widget.onTryOnComplete!(responseBody);
      }

      if (response.statusCode != 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('API Error: ${response.statusCode}'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Widget _buildImagePreview(File? image, bool isClothing) {
    final String label = isClothing ? 'Clothing Image' : 'Avatar Image';

    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 12.0),
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => _showImageSourceDialog(isClothing),
            child: Container(
              width: 140,
              height: 140,
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.grey.shade300,
                  width: 1,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(7),
                child: image != null
                    ? Image.file(image, fit: BoxFit.cover)
                    : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_a_photo_outlined,
                      size: 36,
                      color: Colors.grey.shade500,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Select image',
                      style: TextStyle(
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildImageGuidelines() {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Image Guidelines',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                    fontSize: 16,
                  ),
                ),
                IconButton(
                  icon: Icon(
                    _showGuidelines ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: Theme.of(context).primaryColor,
                  ),
                  onPressed: () {
                    setState(() {
                      _showGuidelines = !_showGuidelines;
                    });
                  },
                ),
              ],
            ),
            if (_showGuidelines) ...[
              const Divider(),
              const Text(
                'For Avatar Image:',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 4),
              _buildGuidelinePoint(
                  '• Face should be clearly visible and forward-facing'),
              _buildGuidelinePoint(
                  '• Full body shot with natural pose (standing straight)'),
              _buildGuidelinePoint(
                  '• Well-lit environment with neutral background'),
              _buildGuidelinePoint(
                  '• Avoid loose or bulky clothing that hides body shape'),
              _buildGuidelinePoint(
                  '• Avoid accessories that cover face (sunglasses, hats)'),

              const SizedBox(height: 8),
              const Text(
                'For Clothing Image:',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 4),
              _buildGuidelinePoint(
                  '• Clear, front view of clothing item on plain background'),
              _buildGuidelinePoint(
                  '• Well-lit with accurate color representation'),
              _buildGuidelinePoint(
                  '• Preferably without a model wearing it'),
              _buildGuidelinePoint(
                  '• Full item should be visible (not cropped)'),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildGuidelinePoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(text, style: const TextStyle(fontSize: 13)),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Create a ScrollController to control the scrolling
    final ScrollController scrollController = ScrollController();

    return Scrollbar(
      controller: scrollController,
      thickness: 6.0,
      radius: const Radius.circular(10.0),
      thumbVisibility: true,
      child: SingleChildScrollView(
        controller: scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Column(
                children: [
                  Text(
                    'Virtual Try-On',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Upload images to see how clothing looks on you',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            _buildImageGuidelines(),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildImagePreview(_clothingImage, true)),
                const SizedBox(width: 16),
                Expanded(child: _buildImagePreview(_avatarImage, false)),
              ],
            ),
            const SizedBox(height: 20),
            Card(
              elevation: 1,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: [
                    Text(
                      'Avatar Gender',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildGenderOption('male'),
                        const SizedBox(width: 20),
                        _buildGenderOption('female'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitTryOn,
                child: _isLoading
                    ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                    : const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.style_outlined, color: Colors.white),
                    SizedBox(width: 8),
                    Text('Try it On'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            if (_apiResponse != null)
              Card(
                elevation: 1,
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'Result',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (_apiResponse!['headers']['content-type']?.contains('image') == true)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.memory(
                            _apiResponse!['body'],
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return const Center(
                                child: Text("Failed to load image result"),
                              );
                            },
                          ),
                        )
                      else
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            _apiResponse != null && _apiResponse!['body'] != null
                                ? String.fromCharCodes(_apiResponse!['body'])
                                : "No response data",
                            textAlign: TextAlign.center,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildGenderOption(String gender) {
    final bool isSelected = _avatarSex == gender;
    final String displayText = gender.substring(0, 1).toUpperCase() + gender.substring(1);
    final IconData genderIcon = gender == 'male' ? Icons.male : Icons.female;

    return InkWell(
      onTap: () => setState(() => _avatarSex = gender),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).primaryColor : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              genderIcon,
              color: isSelected ? Colors.white : Colors.grey.shade600,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              displayText,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey.shade700,
                fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}