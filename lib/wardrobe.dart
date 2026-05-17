import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'app_theme.dart';
import 'category_manager.dart';
import 'homepage.dart';
import 'virtual_try_on.dart';

class _Question {
  final String id;
  final String label;
  final List<String> options;
  final bool multi;
  const _Question({
    required this.id,
    required this.label,
    required this.options,
    this.multi = false,
  });
}

const List<_Question> _kQuestions = [
  _Question(
    id: 'gender',
    label: "Who are we styling today?",
    options: ['Men', 'Women'],
  ),
  _Question(
    id: 'style',
    label: "Which style vibes feel like you?",
    options: ['Casual', 'Formal', 'Sporty', 'Streetwear', 'Traditional', 'Minimalist'],
    multi: true,
  ),
  _Question(
    id: 'colors',
    label: "Pick a few favorite colors",
    options: ['Black', 'White', 'Blue', 'Red', 'Green', 'Beige', 'Pink', 'Brown'],
    multi: true,
  ),
  _Question(
    id: 'items',
    label: "What do you want recommendations for?",
    options: ['Shirts', 'Pants', 'Dresses', 'Jackets', 'Shoes', 'Sportswear'],
    multi: true,
  ),
  _Question(
    id: 'occasion',
    label: "Where will you wear these?",
    options: ['Everyday', 'Work', 'Party', 'Sports', 'Traditional events'],
    multi: true,
  ),
  _Question(
    id: 'season',
    label: "Which season are we shopping for?",
    options: ['Summer', 'Winter', 'All-year'],
  ),
];

enum _Stage { intro, quiz, loading, results }

class WardrobePage extends StatefulWidget {
  @override
  _WardrobePageState createState() => _WardrobePageState();
}

class _WardrobePageState extends State<WardrobePage> {
  final Map<String, dynamic> _answers = {};
  final PageController _pageController = PageController();
  _Stage _stage = _Stage.intro;
  int _index = 0;
  String? _summary;
  List<CategoryItem> _recs = [];
  bool _bootstrapping = true;

  @override
  void initState() {
    super.initState();
    _resetAnswers();
    _loadPriorResults();
  }

  void _resetAnswers() {
    _answers.clear();
    for (final q in _kQuestions) {
      _answers[q.id] = q.multi ? <String>[] : null;
    }
  }

  Future<void> _loadPriorResults() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) setState(() => _bootstrapping = false);
      return;
    }
    try {
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final data = snap.data();
      final survey = data?['surveyData'] as Map<String, dynamic>?;
      final items = survey?['recommendationItems'] as List?;
      if (survey != null && items != null && items.isNotEmpty) {
        final recs = items
            .whereType<Map>()
            .map((m) => CategoryItem(
                  name: (m['name'] ?? '') as String,
                  gender: (m['gender'] ?? '') as String,
                  brand: (m['brand'] ?? '') as String,
                  imagePath: (m['imagePath'] ?? '') as String,
                ))
            .where((it) => it.imagePath.isNotEmpty)
            .toList();
        if (recs.isNotEmpty && mounted) {
          setState(() {
            _recs = recs;
            _summary = survey['summary'] as String?;
            _stage = _Stage.results;
            _bootstrapping = false;
          });
          return;
        }
      }
    } catch (e) {
      debugPrint('Loading prior quiz results failed: $e');
    }
    if (mounted) setState(() => _bootstrapping = false);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  bool get _currentAnswered {
    final q = _kQuestions[_index];
    final a = _answers[q.id];
    return q.multi ? (a as List).isNotEmpty : a != null;
  }

  void _toggle(String questionId, String option, bool multi) {
    setState(() {
      if (multi) {
        final list = List<String>.from(_answers[questionId] as List);
        list.contains(option) ? list.remove(option) : list.add(option);
        _answers[questionId] = list;
      } else {
        _answers[questionId] = option;
      }
    });
  }

  void _next() {
    if (_index < _kQuestions.length - 1) {
      setState(() => _index++);
      _pageController.nextPage(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
      );
    } else {
      _submit();
    }
  }

  void _prev() {
    if (_index > 0) {
      setState(() => _index--);
      _pageController.previousPage(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _submit() async {
    setState(() {
      _stage = _Stage.loading;
    });

    final recs = await _matchItems();
    final summary = await _fetchSummary();
    await _saveToFirestore(recs, summary);

    if (!mounted) return;
    setState(() {
      _recs = recs;
      _summary = summary;
      _stage = _Stage.results;
    });
  }

  Future<List<CategoryItem>> _matchItems() async {
    final mgr = CategoryManager();
    if (!mgr.isInitialized) {
      await mgr.initialize();
    }

    final gender = (_answers['gender'] as String?) ?? 'Men';
    final items = (_answers['items'] as List).cast<String>();

    final categories = items.isEmpty ? mgr.categoryNames : items;
    final pool = <CategoryItem>[];
    for (final c in categories) {
      pool.addAll(
        mgr.getItemsForCategory(c).where((it) => it.gender == gender),
      );
    }
    if (pool.isEmpty) {
      for (final c in mgr.categoryNames) {
        pool.addAll(
          mgr.getItemsForCategory(c).where((it) => it.gender == gender),
        );
      }
    }
    pool.shuffle(Random());
    return pool.take(8).toList();
  }

  Future<void> _saveToFirestore(List<CategoryItem> recs, String? summary) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final surveyData = <String, dynamic>{
      'timestamp': FieldValue.serverTimestamp(),
      'Gender': _answers['gender'] ?? 'Not specified',
      'Style': List<String>.from(_answers['style'] as List),
      'Color Palette': (_answers['colors'] as List).join(', '),
      'Clothing Type': List<String>.from(_answers['items'] as List),
      'Occasions': List<String>.from(_answers['occasion'] as List),
      'Season': _answers['season'] ?? '',
      'summary': summary,
      'recommendationUrls': recs.map((r) => r.imagePath).toList(),
      'recommendationItems': recs
          .map((r) => {
                'name': r.name,
                'brand': r.brand,
                'gender': r.gender,
                'imagePath': r.imagePath,
              })
          .toList(),
    };

    final doc = FirebaseFirestore.instance.collection('users').doc(user.uid);
    try {
      await doc.set({
        'surveyData': surveyData,
        'lastSurveyDate': FieldValue.serverTimestamp(),
        'email': user.email,
        'displayName': user.displayName,
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Firestore save failed: $e');
    }
  }

  Future<String?> _fetchSummary() async {
    final apiKey = dotenv.env['GOOGLE_AI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) return null;

    final prompt = '''
You are StyleBot. Write a short, friendly style summary (3-4 sentences, no markdown, no headers) for a user with these preferences:
- Gender: ${_answers['gender']}
- Styles: ${(_answers['style'] as List).join(', ')}
- Favorite colors: ${(_answers['colors'] as List).join(', ')}
- Wants recommendations for: ${(_answers['items'] as List).join(', ')}
- Occasions: ${(_answers['occasion'] as List).join(', ')}
- Season: ${_answers['season']}

Focus on actionable styling advice they can use today. Plain text only.
''';

    try {
      final resp = await http
          .post(
            Uri.parse(
              'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$apiKey',
            ),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'contents': [
                {
                  'parts': [
                    {'text': prompt}
                  ]
                }
              ]
            }),
          )
          .timeout(const Duration(seconds: 20));

      if (resp.statusCode != 200) {
        debugPrint('Gemini summary failed: ${resp.statusCode} ${resp.body}');
        return null;
      }
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      final candidates = data['candidates'] as List?;
      if (candidates == null || candidates.isEmpty) return null;
      final parts = candidates[0]['content']?['parts'] as List?;
      if (parts == null || parts.isEmpty) return null;
      return (parts[0]['text'] as String?)?.trim();
    } catch (e) {
      debugPrint('Gemini summary error: $e');
      return null;
    }
  }

  void _restart() {
    setState(() {
      _resetAnswers();
      _index = 0;
      _summary = null;
      _recs = [];
      _stage = _Stage.quiz;
    });
    _pageController.jumpToPage(0);
  }

  Future<void> _sendToTryOn(CategoryItem item) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selectedClothingPath', item.imagePath);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${item.name} sent to Try-On'),
        action: SnackBarAction(
          label: 'Open',
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => VirtualTryOn(
                rapidApiKey: dotenv.env['RAPIDAPI_KEY'] ?? '',
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_bootstrapping) {
      return const AppBackground(
        child: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }
    return AppBackground(
      child: SafeArea(
        child: switch (_stage) {
          _Stage.intro => _buildIntro(),
          _Stage.quiz => _buildQuiz(),
          _Stage.loading => _buildLoading(),
          _Stage.results => _buildResults(),
        },
      ),
    );
  }

  Widget _buildIntro() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Card(
          elevation: 6,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.checkroom, size: 72, color: AppTheme.primaryColor),
                const SizedBox(height: 16),
                Text('Style Quiz', style: AppTheme.headingStyle),
                const SizedBox(height: 8),
                const Text(
                  'Answer 6 quick questions and we\'ll build a personalized recommendation set from our brand catalog.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15, height: 1.4),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  style: AppTheme.elevatedButtonStyle(),
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Start Quiz'),
                  onPressed: () => setState(() => _stage = _Stage.quiz),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuiz() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Question ${_index + 1} of ${_kQuestions.length}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  TextButton(
                    onPressed: () => setState(() => _stage = _Stage.intro),
                    child: const Text('Cancel',
                        style: TextStyle(color: Colors.white70)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: (_index + 1) / _kQuestions.length,
                  minHeight: 6,
                  backgroundColor: Colors.white24,
                  valueColor: const AlwaysStoppedAnimation(Colors.white),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _kQuestions.length,
            onPageChanged: (i) => setState(() => _index = i),
            itemBuilder: (_, i) => _buildQuestionCard(_kQuestions[i]),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              if (_index > 0)
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white70),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: _prev,
                    child: const Text('Back'),
                  ),
                )
              else
                const Expanded(child: SizedBox()),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  style: AppTheme.elevatedButtonStyle(),
                  onPressed: _currentAnswered ? _next : null,
                  child: Text(_index < _kQuestions.length - 1 ? 'Next' : 'See My Style'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuestionCard(_Question q) {
    final selected = _answers[q.id];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(q.label, style: AppTheme.subheadingStyle),
              const SizedBox(height: 4),
              Text(
                q.multi ? 'Pick one or more' : 'Pick one',
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: q.options.map((opt) {
                      final isSelected = q.multi
                          ? (selected as List).contains(opt)
                          : selected == opt;
                      return ChoiceChip(
                        label: Text(opt),
                        selected: isSelected,
                        onSelected: (_) => _toggle(q.id, opt, q.multi),
                        selectedColor: AppTheme.primaryColor,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : Colors.black87,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: Colors.white),
          SizedBox(height: 16),
          Text(
            'Building your style profile…',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildResults() {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          iconTheme: const IconThemeData(color: Colors.white),
          title: const Text(
            'Your Style Profile',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              tooltip: 'Retake quiz',
              onPressed: _restart,
            ),
          ],
        ),
        if (_summary != null && _summary!.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Card(
                elevation: 3,
                shape:
                    RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.auto_awesome,
                              color: AppTheme.primaryColor),
                          const SizedBox(width: 8),
                          Text('StyleBot says',
                              style: AppTheme.subheadingStyle),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(_summary!,
                          style: const TextStyle(fontSize: 15, height: 1.4)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverToBoxAdapter(
            child: Row(
              children: [
                const Icon(Icons.shopping_bag_outlined,
                    color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  'Picked for you (${_recs.length})',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 12)),
        if (_recs.isEmpty)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Text(
                'No items matched your filters. Try retaking the quiz with broader choices.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70),
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.72,
              ),
              delegate: SliverChildBuilderDelegate(
                (_, i) => _buildRecCard(_recs[i]),
                childCount: _recs.length,
              ),
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }

  Widget _buildRecCard(CategoryItem item) {
    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Image.asset(
              item.imagePath,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: Colors.grey[200],
                child: const Icon(Icons.broken_image, color: Colors.grey),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  '${item.brand} • ${item.gender}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              icon: const Icon(Icons.checkroom, size: 18),
              label: const Text('Try On'),
              onPressed: () => _sendToTryOn(item),
            ),
          ),
        ],
      ),
    );
  }
}
