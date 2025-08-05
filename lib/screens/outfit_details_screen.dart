import 'package:flutter/material.dart';
import '../models/recommendation_model.dart';

class OutfitDetailsScreen extends StatelessWidget {
  final OutfitRecommendation outfit;

  const OutfitDetailsScreen({Key? key, required this.outfit}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Outfit ${outfit.outfitNumber} Details'),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildOutfitHeader(),
              const SizedBox(height: 24),
              _buildComponentsSection(context),
              const SizedBox(height: 24),
              _buildStylingTips(),
              const SizedBox(height: 24),
              // _buildActionButtons(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOutfitHeader() {
    return Card(
      color: Colors.blue.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(Icons.checkroom, size: 48, color: Colors.blue),
            const SizedBox(height: 8),
            Text(
              'Outfit ${outfit.outfitNumber}',
              style: const TextStyle(
                fontSize: 24, 
                fontWeight: FontWeight.bold
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Personalized outfit based on your preferences',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComponentsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Outfit Components',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: outfit.components.length,
          separatorBuilder: (context, index) => const Divider(),
          itemBuilder: (context, index) {
            final entry = outfit.components.entries.elementAt(index);
            return _buildComponentItem(
              entry.key,
              entry.value,
              index,
            );
          },
        ),
      ],
    );
  }

  Widget _buildComponentItem(String type, String description, int index) {
    // Define icons for different component types
    IconData getIcon() {
      switch (type.toLowerCase()) {
        case 'topwear':
          return Icons.accessibility_new;
        case 'bottomwear':
          return Icons.account_box;
        case 'footwear':
          return Icons.approval;
        default:
          return Icons.category;
      }
    }

    // Format the component type for display
    final formattedType = '${type.substring(0, 1).toUpperCase()}${type.substring(1)}';
    
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.primaries[index % Colors.primaries.length].shade200,
        child: Icon(getIcon(), color: Colors.black87),
      ),
      title: Text(
        formattedType,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        description,
        style: const TextStyle(fontSize: 16),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 8),
    );
  }

  Widget _buildStylingTips() {
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.lightbulb, color: Colors.amber),
                SizedBox(width: 8),
                Text(
                  'Styling Tips',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              _getStylingTips(),
              style: const TextStyle(fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }

  String _getStylingTips() {
    // Generate styling tips based on outfit components
    final components = outfit.components;
    
    if (components.containsKey('topwear') && components.containsKey('bottomwear')) {
      final top = components['topwear']!;
      final bottom = components['bottomwear']!;
      
      // Check for color mentions
      final colors = [
        'black', 'white', 'blue', 'red', 'green', 'purple', 
        'yellow', 'orange', 'pink', 'brown', 'gray', 'grey'
      ];
      
      List<String> topColors = [];
      List<String> bottomColors = [];
      
      for (var color in colors) {
        if (top.toLowerCase().contains(color)) {
          topColors.add(color);
        }
        if (bottom.toLowerCase().contains(color)) {
          bottomColors.add(color);
        }
      }
      
      // Check for style mentions
      final styles = [
        'casual', 'formal', 'elegant', 'boho', 'vintage', 
        'preppy', 'grunge', 'athleisure'
      ];
      
      List<String> outfitStyles = [];
      
      for (var style in styles) {
        if (top.toLowerCase().contains(style) || bottom.toLowerCase().contains(style)) {
          outfitStyles.add(style);
        }
      }
      
      // Generate tips
      String tips = '';
      
      if (topColors.isNotEmpty && bottomColors.isNotEmpty) {
        tips += '• The ${topColors.first} of your top pairs well with the ${bottomColors.first} of your bottom piece.\n\n';
      }
      
      if (outfitStyles.isNotEmpty) {
        tips += '• This ${outfitStyles.first} style is perfect for both casual and semi-formal occasions.\n\n';
      }
      
      tips += '• Add minimal accessories to complete this look without overwhelming it.\n\n';
      tips += '• This outfit works well for day-to-evening transitions with the right accessories.';
      
      return tips;
    }
    
    return '• This outfit combines comfort and style for a balanced look.\n\n'
           '• Layer with a light jacket or cardigan for cooler temperatures.\n\n'
           '• Choose accessories that complement rather than compete with the outfit.\n\n'
           '• Consider simple jewelry to enhance the overall appearance.';
  }

  // Widget _buildActionButtons(BuildContext context) {
  //   return Row(
  //     mainAxisAlignment: MainAxisAlignment.spaceEvenly,
  //     children: [
  //       _buildActionButton(
  //         context,
  //         Icons.favorite_border,
  //         'Save',
  //         Colors.red.shade100,
  //         () => _showActionSnackBar(context, 'Outfit saved to favorites'),
  //       ),
  //       _buildActionButton(
  //         context,
  //         Icons.share,
  //         'Share',
  //         Colors.blue.shade100,
  //         () => _showActionSnackBar(context, 'Sharing options opened'),
  //       ),
  //       _buildActionButton(
  //         context,
  //         Icons.shopping_bag_outlined,
  //         'Shop',
  //         Colors.green.shade100,
  //         () => _showActionSnackBar(context, 'Shopping options opened'),
  //       ),
  //     ],
  //   );
  // }

  Widget _buildActionButton(
    BuildContext context,
    IconData icon,
    String label,
    Color color,
    VoidCallback onPressed,
  ) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.black87,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  void _showActionSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
