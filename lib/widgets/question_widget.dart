import 'package:flutter/material.dart';
import '../models/question.dart';

class QuestionWidget extends StatefulWidget {
  final Question question;
  final Map<String, dynamic> currentAnswers;
  final Function(String, dynamic) onAnswerChanged;

  const QuestionWidget({
    Key? key,
    required this.question,
    required this.currentAnswers,
    required this.onAnswerChanged,
  }) : super(key: key);

  @override
  _QuestionWidgetState createState() => _QuestionWidgetState();
}

class _QuestionWidgetState extends State<QuestionWidget> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.question.question,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          if (widget.question.allowMultiple && widget.question.maxSelections != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Text(
                'Select up to ${widget.question.maxSelections} options',
                style: TextStyle(
                  color: Colors.grey[700],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          Expanded(
            child: widget.question.allowMultiple
                ? _buildMultipleChoiceOptions()
                : _buildSingleChoiceOptions(),
          ),
        ],
      ),
    );
  }

  Widget _buildSingleChoiceOptions() {
    return ListView.builder(
      itemCount: widget.question.options.length,
      itemBuilder: (context, index) {
        final option = widget.question.options[index];
        return RadioListTile<String>(
          title: Text(option),
          value: option,
          groupValue: widget.currentAnswers[widget.question.id],
          onChanged: (value) {
            widget.onAnswerChanged(widget.question.id, value);
          },
        );
      },
    );
  }

  Widget _buildMultipleChoiceOptions() {
    // Get current selected values or initialize empty list
    final List<String> selectedOptions = 
        (widget.currentAnswers[widget.question.id] as List<dynamic>?)?.cast<String>() ?? [];
    
    return ListView.builder(
      itemCount: widget.question.options.length,
      itemBuilder: (context, index) {
        final option = widget.question.options[index];
        final isSelected = selectedOptions.contains(option);
        
        return CheckboxListTile(
          title: Text(option),
          value: isSelected,
          onChanged: (bool? checked) {
            // Create a new list to avoid modifying the original
            List<String> updatedSelection = List<String>.from(selectedOptions);
            
            if (checked == true) {
              // Add the option if not already selected and within max selection limit
              if (!updatedSelection.contains(option)) {
                // Check if we've reached max selections
                if (widget.question.maxSelections != null && 
                    updatedSelection.length >= widget.question.maxSelections!) {
                  // Show snackbar to inform user of limit
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('You can only select up to ${widget.question.maxSelections} options'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                  return;
                }
                updatedSelection.add(option);
              }
            } else {
              // Remove the option
              updatedSelection.remove(option);
            }
            
            widget.onAnswerChanged(widget.question.id, updatedSelection);
          },
        );
      },
    );
  }
}
