import 'package:flutter/material.dart';
import '../models/question.dart';
import '../services/api_service.dart';
import '../widgets/question_widget.dart';
import 'results_screen.dart';

class QuestionnaireScreen extends StatefulWidget {
  const QuestionnaireScreen({Key? key}) : super(key: key);

  @override
  _QuestionnaireScreenState createState() => _QuestionnaireScreenState();
}

class _QuestionnaireScreenState extends State<QuestionnaireScreen> {
  final ApiService _apiService = ApiService();
  // final StorageService _storageService = StorageService();
  final Map<String, dynamic> _answers = {};
  List<Question> _questions = [];
  bool _isLoading = true;
  int _currentQuestionIndex = 0;
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    try {
      final questions = await _apiService.getQuestions();
      setState(() {
        _questions = questions;
        _isLoading = false;
        
        // Initialize answers map with empty values
        for (var question in questions) {
          if (question.allowMultiple) {
            _answers[question.id] = <String>[];
          } else {
            _answers[question.id] = null;
          }
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading questions: $e')),
      );
    }
  }

  void _handleAnswerChanged(String questionId, dynamic answer) {
    setState(() {
      _answers[questionId] = answer;
    });
  }

  bool _isCurrentQuestionAnswered() {
    if (_currentQuestionIndex >= _questions.length) return true;
    
    final question = _questions[_currentQuestionIndex];
    final answer = _answers[question.id];
    
    if (question.allowMultiple) {
      return answer != null && (answer as List).isNotEmpty;
    } else {
      return answer != null;
    }
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
      });
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _submitAnswers();
    }
  }

  void _previousQuestion() {
    if (_currentQuestionIndex > 0) {
      setState(() {
        _currentQuestionIndex--;
      });
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }  Future<void> _submitAnswers() async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      // Process answers to match the expected format
      Map<String, dynamic> formattedAnswers = _processAnswers();
      
      final response = await _apiService.submitPreferences(formattedAnswers);
      
      setState(() {
        _isLoading = false;
      });
      
      if (!mounted) return;
      
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ResultsScreen(responseData: response),
        ),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error submitting answers: $e')),
      );
    }
  }

  // Process answers into the format expected by the API
  Map<String, dynamic> _processAnswers() {
    // Start with the basic answers
    Map<String, dynamic> processed = Map.from(_answers);
    
    // Initialize item_specific_preferences if needed
    processed['item_specific_preferences'] = {};
    
    // Check if we have item types selected
    List<String>? itemTypes = processed['item_types'] as List<String>?;
    if (itemTypes != null && itemTypes.isNotEmpty) {
      // For each selected item type, add specific preferences
      for (String itemType in itemTypes) {
        String lowercaseItem = itemType.toLowerCase();
        processed['item_specific_preferences'][lowercaseItem] = {
          'colors': processed['favorite_colors'] ?? [],
          'materials': processed['preferred_materials'] ?? [],
        };
      }
    }
    
    return processed;
  }
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pushReplacementNamed('/');
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Fashion Preferences'),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.of(context).pushReplacementNamed('/');
            },
          ),
        ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _questions.isEmpty
              ? const Center(child: Text('No questions available'))
              : Column(
                  children: [
                    LinearProgressIndicator(
                      value: (_currentQuestionIndex + 1) / _questions.length,
                      backgroundColor: Colors.grey[200],
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        'Question ${_currentQuestionIndex + 1} of ${_questions.length}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Expanded(
                      child: PageView.builder(
                        controller: _pageController,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _questions.length,
                        onPageChanged: (index) {
                          setState(() {
                            _currentQuestionIndex = index;
                          });
                        },
                        itemBuilder: (context, index) {
                          return QuestionWidget(
                            question: _questions[index],
                            currentAnswers: _answers,
                            onAnswerChanged: _handleAnswerChanged,
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (_currentQuestionIndex > 0)
                            ElevatedButton(
                              onPressed: _previousQuestion,
                              child: const Text('Previous'),
                            )
                          else
                            const SizedBox(width: 80),
                          Text('${_currentQuestionIndex + 1}/${_questions.length}'),
                          ElevatedButton(
                            onPressed: _isCurrentQuestionAnswered()
                                ? _nextQuestion
                                : null,
                            child: Text(_currentQuestionIndex < _questions.length - 1
                                ? 'Next'
                                : 'Submit'),
                          ),
                        ],
                      ),
                    ),
                  ],                ),
      ),
    );
  }
}
