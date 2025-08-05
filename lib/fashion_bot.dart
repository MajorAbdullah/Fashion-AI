import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:thefashionai/app_theme.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() => runApp(FashionAssistantApp());

class FashionAssistantApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primaryColor: Colors.pinkAccent,
        colorScheme: ColorScheme.fromSwatch().copyWith(
          secondary: Colors.deepPurple,
        ),
      ),
      home: ChatScreen(),
    );
  }
}

class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final List<ChatMessage> _messages = [];
  final ApiService _apiService =
  ApiService(dotenv.env['GOOGLE_AI_API_KEY'] ?? '');
  bool _isLoading = false;
  late AnimationController _typingController;
  File? _selectedImage;

  final List<String> _premadePrompts = [
    "What's the latest summer fashion trend?",
    "How to style jeans for a night out?",
    "What colors match with my skin tone?",
    "Suggest office wear for hot weather",
    "How to accessorize a little black dress?",
    "What shoes go best with this outfit?",
  ];

  @override
  void initState() {
    super.initState();
    _typingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();
  }

  @override
  void dispose() {
    _typingController.dispose();
    super.dispose();
  }

  void _sendMessage() async {
    final text = _controller.text.trim();
    final imageFile = _selectedImage;

    if (text.isEmpty && imageFile == null) return;

    setState(() {
      _messages.add(ChatMessage(
        text: text.isNotEmpty ? text : 'Analyzing fashion image...',
        isUser: true,
        imageFile: imageFile,
      ));
      _isLoading = true;
      _selectedImage = null;
      _controller.clear();
    });

    try {
      final promptText = text.isNotEmpty ? text : 'Analyze this fashion image';
      final responseText = await _apiService.sendFashionQuery(
        promptText,
        imageFile: imageFile,
      );
      setState(() {
        _messages.add(ChatMessage(
          text: responseText,
          isUser: false,
          isFashionTip: true,
        ));
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    final ImageSource? source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.camera_alt),
              title: Text('Take Photo'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: Icon(Icons.photo_library),
              title: Text('Choose from Gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor,
        title: Text('Fashion Assistant 👗'),
        actions: [
          IconButton(
            icon: Icon(Icons.palette),
            onPressed: () => _controller.text =
            "Suggest color palette for my wardrobe according to the given image",
          )
        ],
      ),
      body: Column(
        children: [
          _buildPremadePrompts(),
          Expanded(
            child: ListView.builder(
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index < _messages.length) {
                  return _buildMessage(_messages[index]);
                } else {
                  return _buildTypingIndicator();
                }
              },
            ),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
      alignment: Alignment.centerLeft,
      child: Container(
        padding: EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: Colors.pink[50],
          borderRadius: BorderRadius.circular(15.0),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedDot(controller: _typingController, delay: 0),
            SizedBox(width: 4),
            AnimatedDot(controller: _typingController, delay: 200),
            SizedBox(width: 4),
            AnimatedDot(controller: _typingController, delay: 400),
          ],
        ),
      ),
    );
  }

  Widget _buildPremadePrompts() {
    return Container(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _premadePrompts.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.all(4.0),
            child: ChoiceChip(
              label: Text(_premadePrompts[index]),
              selected: false,
              onSelected: (_) => _controller.text = _premadePrompts[index],
              backgroundColor: Colors.pink[50],
              labelStyle: TextStyle(color: Colors.pink[800]),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInputArea() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          if (_selectedImage != null)
            Container(
              height: 100,
              child: Stack(
                children: [
                  Image.file(_selectedImage!,
                      width: 100, height: 100, fit: BoxFit.cover),
                  Positioned(
                    right: 0,
                    child: IconButton(
                      icon: Icon(Icons.close, color: Colors.red),
                      onPressed: () {
                        setState(() {
                          _selectedImage = null;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: InputDecoration(
                    hintText: 'Ask fashion advice...',
                    suffixIcon: IconButton(
                      icon: Icon(Icons.add_photo_alternate),
                      onPressed: _pickImage,
                    ),
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
              IconButton(
                icon: Icon(Icons.send, color: Colors.pink),
                onPressed: _sendMessage,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMessage(ChatMessage message) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        padding: EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: message.isUser
              ? Colors.pink[100]
              : (message.isFashionTip ? Colors.pink[50] : Colors.white),
          borderRadius: BorderRadius.circular(15.0),
          border: message.isFashionTip
              ? Border.all(color: Colors.pinkAccent)
              : null,
        ),
        constraints:
        BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (message.imageFile != null)
              Column(
                children: [
                  Image.file(
                    message.imageFile!,
                    width: 200,
                    height: 200,
                    fit: BoxFit.cover,
                  ),
                  SizedBox(height: 8),
                ],
              ),
            Linkify(
              onOpen: (link) async {
                final url = link.url;
                if (url.isNotEmpty) {
                  // Validate URL format
                  if (RegExp(r'^(http|https)://[^\s/$.?#].[^\s]*$')
                      .hasMatch(url)) {
                    if (await canLaunchUrl(Uri.parse(url))) {
                      await launchUrl(Uri.parse(url));
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Invalid URL: $url')),
                    );
                  }
                }
              },
              text: message.text,
              style: TextStyle(
                color: Colors.black87,
                fontWeight: message.isFashionTip
                    ? FontWeight.w500
                    : FontWeight.normal,
              ),
              linkStyle: TextStyle(
                color: Colors.blue[600],
                decoration: TextDecoration.underline,
              ),
            ),
            if (message.isFashionTip)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text('👗 Fashion BOT',
                    style: TextStyle(
                        color: Colors.pink[800],
                        fontSize: 12,
                        fontStyle: FontStyle.italic)),
              ),
          ],
        ),
      ),
    );
  }
}

class AnimatedDot extends StatelessWidget {
  final AnimationController controller;
  final int delay;

  const AnimatedDot({required this.controller, required this.delay});

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity:
      DelayTween(begin: 0.0, end: 1.0, delay: delay).animate(controller),
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: Colors.pinkAccent,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class DelayTween extends Tween<double> {
  DelayTween({double? begin, double? end, required this.delay})
      : super(begin: begin, end: end);

  final int delay;

  @override
  double lerp(double t) {
    t = (t - delay / 2000).clamp(0.0, 1.0);
    return super.lerp(t);
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final File? imageFile;
  final bool isFashionTip;

  ChatMessage({
    required this.text,
    required this.isUser,
    this.imageFile,
    this.isFashionTip = false,
  });
}

class ApiService {
  final String apiKey;

  ApiService(this.apiKey);

  Future<String> sendFashionQuery(String text, {File? imageFile}) async {
    const fashionContext = """
     You are a friendly personal fashion assistant named StyleBot. Your expertise includes:
    - Analyzing clothing items and outfits from images
    - Suggesting outfits based on occasions and personal style
    - Identifying skin undertones from photos
    - Providing color palette recommendations
    - Offering body type-specific fashion advice
    - Sustainable fashion suggestions
    - Seasonal fashion trends
    - Wardrobe organization tips
    - Natural, conversational tone
    - Simple language anyone can understand
    - Line breaks between main ideas
    - Occasional relevant emojis
    - Clear website links when suggesting products
    - No markdown or special formatting
    - Focus on actionable tips
    - Also you always have to reply in english language.

    When analyzing images:
    1. Start with positive feedback
    3. Mention color matches
    4. Offer styling alternatives
    5. Include relevant shopping links
    
    Always respond in a helpful, encouraging tone with markdown formatting. 
    Use fashion terminology appropriately and provide clear explanations.
    
    """;

    final prompt = imageFile != null
        ? "Fashion analysis for this look: $text. key suggestions in natural language, no special formatting, Analyze the user's image or answer their question. Emojis sparingly. If you're suggesting outfits outfits for some occasion also include link of websites where user can buy them. Focus on clear, natural formatting."
        : "$fashionContext\n User Question: $text";

    if (imageFile != null) {
      return _sendImageMessage(prompt, imageFile);
    } else {
      return _sendTextMessage(prompt);
    }
  }

  Future<String> _sendTextMessage(String text) async {
    final response = await http.post(
      Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-exp:generateContent?key=$apiKey'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "contents": [
          {
            "parts": [
              {"text": text}
            ]
          }
        ]
      }),
    );
    return _handleResponse(response);
  }

  Future<String> _sendImageMessage(String text, File imageFile) async {
    final imageBytes = await imageFile.readAsBytes();
    final base64Image = base64Encode(imageBytes);
    final mimeType = lookupMimeType(imageFile.path) ?? 'image/jpeg';

    final response = await http.post(
      Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-exp:generateContent?key=$apiKey'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "contents": [
          {
            "parts": [
              {"text": text},
              {
                "inline_data": {"data": base64Image, "mime_type": mimeType}
              }
            ]
          }
        ]
      }),
    );
    return _handleResponse(response);
  }

  String _handleResponse(http.Response response) {
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      String text = data['candidates'][0]['content']['parts'][0]['text'];
      return _cleanResponse(text);
    } else {
      throw Exception('API Error: ${response.body}');
    }
  }

  String _cleanResponse(String text) {
    return text
        .replaceAll('*', '')
        .replaceAll('##', '')
        .replaceAll('###', '')
        .replaceAll('- ', '')
        .replaceAll('```', '')
        .replaceAll('**', '');
  }
}