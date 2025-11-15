import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// ============================================================================
// BEE HEALTH API CLASS - Gradio Client Implementation
// ============================================================================
class BeeHealthAPI {
  static const String baseUrl = 'https://saadiahemd292-bee-health-classifier.hf.space';
  
  /// Predict bee health from image using Gradio API
  static Future<Map<String, dynamic>> predict(File imageFile) async {
    try {
      // Step 1: Upload the image file
      final uploadResult = await _uploadFile(imageFile);
      if (!uploadResult['success']) {
        return uploadResult;
      }
      
      final fileUrl = uploadResult['file_url'];
      
      // Step 2: Call the prediction endpoint
      final response = await http.post(
        Uri.parse('$baseUrl/call/predict'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'data': [fileUrl],
        }),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final eventId = responseData['event_id'];
        
        // Step 3: Get the result using event_id
        final result = await _getResult(eventId);
        return result;
      } else {
        return {
          'success': false,
          'error': 'Prediction API Error: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Exception: $e',
      };
    }
  }

  /// Upload file to Gradio Space
  static Future<Map<String, dynamic>> _uploadFile(File imageFile) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/upload'),
      );
      
      request.files.add(
        await http.MultipartFile.fromPath(
          'files',
          imageFile.path,
        ),
      );

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final List<dynamic> uploadedFiles = json.decode(response.body);
        if (uploadedFiles.isNotEmpty) {
          return {
            'success': true,
            'file_url': uploadedFiles[0],
          };
        } else {
          return {
            'success': false,
            'error': 'No file uploaded',
          };
        }
      } else {
        return {
          'success': false,
          'error': 'Upload failed: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Upload exception: $e',
      };
    }
  }

  /// Get prediction result using event_id
  static Future<Map<String, dynamic>> _getResult(String eventId) async {
    try {
      // Poll for results (Gradio uses Server-Sent Events, but we'll use polling)
      for (int i = 0; i < 30; i++) {
        await Future.delayed(const Duration(milliseconds: 500));
        
        final response = await http.get(
          Uri.parse('$baseUrl/call/predict/$eventId'),
        );

        if (response.statusCode == 200) {
          // Parse the response - Gradio returns newline-delimited JSON
          final lines = response.body.split('\n');
          for (var line in lines.reversed) {
            if (line.trim().isEmpty) continue;
            
            try {
              final data = json.decode(line);
              if (data['msg'] == 'process_completed') {
                return _parsePredictionResult(data['output']['data']);
              }
            } catch (e) {
              continue;
            }
          }
        }
      }
      
      return {
        'success': false,
        'error': 'Timeout waiting for results',
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Result retrieval failed: $e',
      };
    }
  }

  /// Parse the prediction result from Gradio output
  static Map<String, dynamic> _parsePredictionResult(List<dynamic> outputData) {
    try {
      // Gradio typically returns results in different formats
      // The output format depends on your Gradio interface
      
      if (outputData.isEmpty) {
        return {
          'success': false,
          'error': 'No prediction data received',
        };
      }

      // Try to parse the result
      // Format 1: Direct dictionary with confidences
      if (outputData[0] is Map) {
        final predictions = outputData[0] as Map<String, dynamic>;
        Map<String, double> confidences = {};
        
        predictions.forEach((key, value) {
          if (value is num) {
            confidences[key] = value.toDouble();
          }
        });
        
        return {
          'success': true,
          'confidences': confidences,
          'raw_response': outputData,
        };
      }
      
      // Format 2: Label object with 'confidences' field
      if (outputData[0] is Map && outputData[0]['confidences'] != null) {
        final labelData = outputData[0] as Map<String, dynamic>;
        final confidencesList = labelData['confidences'] as List<dynamic>;
        
        Map<String, double> confidences = {};
        for (var item in confidencesList) {
          confidences[item['label']] = (item['confidence'] as num).toDouble();
        }
        
        return {
          'success': true,
          'confidences': confidences,
          'raw_response': outputData,
        };
      }

      return {
        'success': false,
        'error': 'Unknown result format',
        'raw_response': outputData,
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Failed to parse result: $e',
        'raw_response': outputData,
      };
    }
  }

  /// Get the top prediction class
  static String? getPredictionClass(Map<String, dynamic> result) {
    if (!result['success']) return null;
    final confidences = result['confidences'] as Map<String, dynamic>?;
    if (confidences == null || confidences.isEmpty) return null;
    
    return confidences.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }

  /// Get the confidence of the top prediction
  static double? getConfidence(Map<String, dynamic> result) {
    if (!result['success']) return null;
    final confidences = result['confidences'] as Map<String, dynamic>?;
    if (confidences == null || confidences.isEmpty) return null;
    
    return confidences.values.reduce((a, b) => a > b ? a : b);
  }

  /// Get all predictions sorted by confidence
  static List<Map<String, dynamic>> getAllPredictions(Map<String, dynamic> result) {
    if (!result['success']) return [];
    final confidences = result['confidences'] as Map<String, dynamic>?;
    if (confidences == null) return [];
    
    List<Map<String, dynamic>> predictions = [];
    confidences.forEach((className, confidence) {
      predictions.add({
        'class': className,
        'confidence': confidence,
        'percentage': (confidence * 100).toStringAsFixed(1),
      });
    });
    
    predictions.sort((a, b) => (b['confidence'] as double).compareTo(a['confidence'] as double));
    return predictions;
  }
}

// ============================================================================
// BEE HEALTH ANALYZER PAGE
// ============================================================================
class BeeHealthAnalyzerPage extends StatefulWidget {
  const BeeHealthAnalyzerPage({Key? key}) : super(key: key);

  @override
  State<BeeHealthAnalyzerPage> createState() => _BeeHealthAnalyzerPageState();
}

class _BeeHealthAnalyzerPageState extends State<BeeHealthAnalyzerPage> {
  File? _selectedImage;
  bool _isAnalyzing = false;
  Map<String, dynamic>? _result;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
          _result = null;
        });
      }
    } catch (e) {
      _showError('Failed to pick image: $e');
    }
  }

  Future<void> _analyzeImage() async {
    if (_selectedImage == null) {
      _showError('Please select an image first');
      return;
    }

    setState(() {
      _isAnalyzing = true;
      _result = null;
    });

    try {
      final result = await BeeHealthAPI.predict(_selectedImage!);
      setState(() {
        _result = result;
        _isAnalyzing = false;
      });

      if (!result['success']) {
        _showError(result['error']);
      }
    } catch (e) {
      setState(() {
        _isAnalyzing = false;
      });
      _showError('Analysis failed: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _resetAnalysis() {
    setState(() {
      _selectedImage = null;
      _result = null;
      _isAnalyzing = false;
    });
  }

  Color _getHealthColor(String className) {
    final lowerClass = className.toLowerCase();
    if (lowerClass.contains('healthy') || lowerClass.contains('normal')) {
      return Colors.green;
    } else if (lowerClass.contains('hive') || lowerClass.contains('beetle')) {
      return Colors.orange;
    } else if (lowerClass.contains('varroa') || lowerClass.contains('mite')) {
      return Colors.red;
    } else {
      return Colors.blue;
    }
  }

  IconData _getHealthIcon(String className) {
    final lowerClass = className.toLowerCase();
    if (lowerClass.contains('healthy') || lowerClass.contains('normal')) {
      return Icons.check_circle;
    } else if (lowerClass.contains('hive') || lowerClass.contains('beetle')) {
      return Icons.warning_amber;
    } else if (lowerClass.contains('varroa') || lowerClass.contains('mite')) {
      return Icons.dangerous;
    } else {
      return Icons.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.bug_report, size: 28),
            SizedBox(width: 12),
            Text('Bee Health Classifier'),
          ],
        ),
        backgroundColor: Colors.amber.shade700,
        elevation: 0,
        actions: [
          if (_selectedImage != null)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _resetAnalysis,
              tooltip: 'Start Over',
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildImageSection(),
              const SizedBox(height: 20),
              if (_selectedImage != null) _buildActionButtons(),
              const SizedBox(height: 24),
              if (_isAnalyzing) _buildLoadingIndicator(),
              if (_result != null && _result!['success']) _buildResults(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: _selectedImage == null
            ? _buildImagePlaceholder()
            : _buildSelectedImage(),
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      height: 320,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.add_photo_alternate_outlined,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Select a bee image to analyze',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Upload an image to detect bee health conditions',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: () => _pickImage(ImageSource.camera),
                icon: const Icon(Icons.camera_alt),
                label: const Text('Camera'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: () => _pickImage(ImageSource.gallery),
                icon: const Icon(Icons.photo_library),
                label: const Text('Gallery'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedImage() {
    return Stack(
      children: [
        Image.file(
          _selectedImage!,
          height: 320,
          width: double.infinity,
          fit: BoxFit.cover,
        ),
        Positioned(
          top: 8,
          right: 8,
          child: Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            child: InkWell(
              onTap: _resetAnalysis,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.all(8),
                child: const Icon(Icons.close, size: 20),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _pickImage(ImageSource.gallery),
            icon: const Icon(Icons.photo_library),
            label: const Text('Change Image'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              side: BorderSide(color: Colors.amber.shade700, width: 2),
              foregroundColor: Colors.amber.shade700,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _isAnalyzing ? null : _analyzeImage,
            icon: _isAnalyzing 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.analytics),
            label: Text(_isAnalyzing ? 'Analyzing...' : 'Analyze'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber.shade700,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              disabledBackgroundColor: Colors.grey.shade300,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingIndicator() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.amber.shade700),
            strokeWidth: 3,
          ),
          const SizedBox(height: 20),
          Text(
            'Analyzing bee health...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'This may take a few seconds',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResults() {
    final predictions = BeeHealthAPI.getAllPredictions(_result!);
    if (predictions.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Text('No predictions available'),
      );
    }

    final topPrediction = predictions.first;
    final className = topPrediction['class'] as String;
    final confidence = topPrediction['confidence'] as double;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Icon(
                _getHealthIcon(className),
                size: 64,
                color: _getHealthColor(className),
              ),
              const SizedBox(height: 16),
              Text(
                className,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: _getHealthColor(className),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Confidence: ${(confidence * 100).toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
              LinearProgressIndicator(
                value: confidence,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(_getHealthColor(className)),
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        if (predictions.length > 1) _buildAllPredictions(predictions),
      ],
    );
  }

  Widget _buildAllPredictions(List<Map<String, dynamic>> predictions) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.analytics_outlined, color: Colors.grey.shade700),
              const SizedBox(width: 8),
              Text(
                'All Predictions',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...predictions.map((pred) {
            final className = pred['class'] as String;
            final confidence = pred['confidence'] as double;
            final percentage = pred['percentage'] as String;
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          className,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade800,
                          ),
                        ),
                      ),
                      Text(
                        '$percentage%',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: _getHealthColor(className),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  LinearProgressIndicator(
                    value: confidence,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _getHealthColor(className).withOpacity(0.7),
                    ),
                    minHeight: 6,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}

// ============================================================================
// MAIN FUNCTION
