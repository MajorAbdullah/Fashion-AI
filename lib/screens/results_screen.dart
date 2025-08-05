import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../models/recommendation_model.dart';
import 'outfit_details_screen.dart';
import 'choice_screen.dart';

class ResultsScreen extends StatefulWidget {
  final Map<String, dynamic> responseData;
  final bool fromSavedRecommendations;

  const ResultsScreen({
    Key? key, 
    required this.responseData, 
    this.fromSavedRecommendations = false,
  }) : super(key: key);

  @override
  _ResultsScreenState createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  final ApiService _apiService = ApiService();
  final StorageService _storageService = StorageService();
  List<OutfitRecommendation> _outfits = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    if (widget.fromSavedRecommendations) {
      _loadSavedRecommendations();
    } else {
      _loadRecommendations();
    }
  }
  Future<void> _loadSavedRecommendations() async {
    try {
      if (widget.responseData.containsKey('outfits')) {
        final outfitsJson = widget.responseData['outfits'];
        if (outfitsJson is List<OutfitRecommendation>) {
          setState(() {
            _outfits = outfitsJson;
            _isLoading = false;
          });
        } else {
          // Try to convert the JSON object to OutfitRecommendation objects
          final recommendations = OutfitRecommendation.fromJsonList(outfitsJson);
          setState(() {
            _outfits = recommendations;
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No recommendation data available')),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading saved recommendations: $e')),
      );
    }
  }

  Future<void> _loadRecommendations() async {
    try {
      final outfits = await _apiService.getRecommendations();
      
      // Save recommendations for future use
      await _storageService.saveRecommendations(outfits);
      
      setState(() {
        _outfits = outfits;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading recommendations: $e')),
      );
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Outfit Recommendations'),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const ChoiceScreen(),
              ),
            );
          },
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _outfits.isEmpty
              ? const Center(
                  child: Text('No outfit recommendations available'),
                )
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Based on your preferences, we recommend these outfits:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: ListView.builder(
                          itemCount: _outfits.length,
                          itemBuilder: (context, index) {
                            final outfit = _outfits[index];
                            return _buildOutfitCard(outfit);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildOutfitCard(OutfitRecommendation outfit) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OutfitDetailsScreen(outfit: outfit),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Outfit ${outfit.outfitNumber}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Icon(Icons.arrow_forward),
                ],
              ),
              const Divider(),
              ..._buildOutfitComponentsList(outfit.components),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildOutfitComponentsList(Map<String, String> components) {
    List<Widget> componentWidgets = [];

    // Define the order we want to display components
    final displayOrder = ['topwear', 'bottomwear', 'footwear'];
    
    for (final type in displayOrder) {
      if (components.containsKey(type)) {
        final value = components[type];
        componentWidgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 100,
                  child: Text(
                    '${type.substring(0, 1).toUpperCase()}${type.substring(1)}:',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  child: Text(
                    value!,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    }

    // Add other components not explicitly ordered
    components.forEach((type, value) {
      if (!displayOrder.contains(type)) {
        componentWidgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 100,
                  child: Text(
                    '${type.substring(0, 1).toUpperCase()}${type.substring(1)}:',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  child: Text(
                    value,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    });

    return componentWidgets;
  }
}
