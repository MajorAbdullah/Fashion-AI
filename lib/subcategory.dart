import 'package:flutter/material.dart';
import 'dart:io';

class SubcategoryPage extends StatelessWidget {
  final String title;
  final List<String> images;
  final String? brandFolder; // Optional parameter to specify a brand folder

  SubcategoryPage({
    required this.title, 
    required this.images,
    this.brandFolder,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: GridView.builder(
        padding: EdgeInsets.all(16.0),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, // Number of columns
          crossAxisSpacing: 10.0,
          mainAxisSpacing: 10.0,
          childAspectRatio: 0.75, // Adjust for better image display
        ),
        itemCount: images.length,
        itemBuilder: (context, index) {
          // Check if image exists in assets or file system
          Widget imageWidget;
          String imagePath = images[index];
          
          // For brand-specific images from the All Brands folder
          if (brandFolder != null) {
            imagePath = 'assets/All Brands/$brandFolder/$imagePath';
            
            try {
              imageWidget = Image.asset(
                imagePath,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[300],
                    child: Center(
                      child: Icon(Icons.broken_image, size: 40),
                    ),
                  );
                },
              );
            } catch (e) {
              imageWidget = Container(
                color: Colors.grey[300],
                child: Center(
                  child: Icon(Icons.broken_image, size: 40),
                ),
              );
            }
          } else {
            // For regular images
            try {
              imageWidget = Image.asset(
                imagePath,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[300],
                    child: Center(
                      child: Icon(Icons.broken_image, size: 40),
                    ),
                  );
                },
              );
            } catch (e) {
              imageWidget = Container(
                color: Colors.grey[300],
                child: Center(
                  child: Icon(Icons.broken_image, size: 40),
                ),
              );
            }
          }

          return Card(
            elevation: 5,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
                    child: imageWidget,
                  ),
                ),
                // You can add item name, price, etc. here
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    _formatImageName(images[index]),
                    style: TextStyle(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
  
  // Helper method to format image file names to display as item names
  String _formatImageName(String imagePath) {
    // Extract file name without extension
    String fileName = imagePath.split('/').last.split('.').first;
    
    // Remove any numbers or special formatting
    fileName = fileName.replaceAll(RegExp(r'^\d+\s*'), '');
    
    // Capitalize each word
    List<String> words = fileName.split(' ');
    words = words.map((word) {
      if (word.isNotEmpty) {
        return word[0].toUpperCase() + word.substring(1).toLowerCase();
      }
      return '';
    }).toList();
    
    return words.join(' ');
  }
}