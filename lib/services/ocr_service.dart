import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:logger/logger.dart';
import '../core/constants/app_constants.dart';

class OCRService {
  final TextRecognizer _textRecognizer = TextRecognizer();
  final Logger _logger = Logger();

  /// Extract text from an image using Google ML Kit
  Future<String> extractTextFromImage(File imageFile) async {
    try {
      final inputImage = InputImage.fromFile(imageFile);
      final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);
      
      final extractedText = recognizedText.text;
      _logger.i('OCR extracted ${extractedText.length} characters');
      
      return extractedText;
    } catch (e) {
      _logger.e('Error extracting text from image: $e');
      throw 'Failed to extract text from image';
    }
  }

  /// Parse prescription text and extract medication information
  Future<ParsedPrescription?> parsePrescriptionText(String text) async {
    try {
      _logger.i('Parsing prescription text: ${text.length} characters');
      
      if (text.trim().isEmpty) {
        return null;
      }

      final lines = text.split('\n').map((line) => line.trim()).where((line) => line.isNotEmpty).toList();
      
      String? medicationName;
      String? dosage;
      MedicationType? type;
      DosageFrequency? frequency;
      String? instructions;

      // Extract medication name (usually first significant line or after "Rx:")
      medicationName = _extractMedicationName(lines);
      
      // Extract dosage information
      dosage = _extractDosage(lines);
      
      // Extract medication type
      type = _extractMedicationType(text);
      
      // Extract frequency
      frequency = _extractFrequency(text);
      
      // Extract instructions
      instructions = _extractInstructions(lines);

      if (medicationName != null) {
        return ParsedPrescription(
          medicationName: medicationName,
          dosage: dosage ?? '',
          type: type ?? MedicationType.tablet,
          frequency: frequency ?? DosageFrequency.onceDaily,
          instructions: instructions,
        );
      }
      
      return null;
    } catch (e) {
      _logger.e('Error parsing prescription text: $e');
      return null;
    }
  }

  String? _extractMedicationName(List<String> lines) {
    // Common patterns for medication names
    for (String line in lines) {
      final lowerLine = line.toLowerCase();
      
      // Skip header information
      if (lowerLine.contains('doctor') || 
          lowerLine.contains('hospital') || 
          lowerLine.contains('clinic') ||
          lowerLine.contains('patient') ||
          lowerLine.contains('date') ||
          line.length < 3) {
        continue;
      }
      
      // Look for "Rx:" or prescription indicators
      if (lowerLine.contains('rx:') || lowerLine.contains('prescription:')) {
        final parts = line.split(':');
        if (parts.length > 1) {
          return parts[1].trim();
        }
      }
      
      // Look for medication-like words (usually contains letters and possibly numbers)
      if (RegExp(r'^[A-Za-z][A-Za-z0-9\s\-]{2,30}$').hasMatch(line)) {
        // Check if it's not a common non-medication word
        if (!_isCommonNonMedicationWord(line)) {
          return line.trim();
        }
      }
    }
    
    // If no clear medication found, return the first substantial line
    for (String line in lines) {
      if (line.length > 3 && RegExp(r'[A-Za-z]').hasMatch(line)) {
        return line.trim();
      }
    }
    
    return null;
  }

  String? _extractDosage(List<String> lines) {
    for (String line in lines) {
      final lowerLine = line.toLowerCase();
      
      // Look for dosage patterns
      final dosagePatterns = [
        RegExp(r'(\d+)\s*(mg|mcg|ml|g|units?)', caseSensitive: false),
        RegExp(r'(\d+\.?\d*)\s*(mg|mcg|ml|g|units?)', caseSensitive: false),
        RegExp(r'(\d+)/(\d+)\s*(mg|mcg|ml|g)', caseSensitive: false),
      ];
      
      for (final pattern in dosagePatterns) {
        final match = pattern.firstMatch(line);
        if (match != null) {
          return match.group(0);
        }
      }
    }
    
    return null;
  }

  MedicationType _extractMedicationType(String text) {
    final lowerText = text.toLowerCase();
    
    if (lowerText.contains('tablet') || lowerText.contains('tab')) {
      return MedicationType.tablet;
    } else if (lowerText.contains('capsule') || lowerText.contains('cap')) {
      return MedicationType.capsule;
    } else if (lowerText.contains('liquid') || lowerText.contains('syrup') || lowerText.contains('solution')) {
      return MedicationType.liquid;
    } else if (lowerText.contains('injection') || lowerText.contains('injectable')) {
      return MedicationType.injection;
    } else if (lowerText.contains('cream') || lowerText.contains('ointment') || lowerText.contains('gel')) {
      return MedicationType.cream;
    } else if (lowerText.contains('inhaler') || lowerText.contains('inhale')) {
      return MedicationType.inhaler;
    } else if (lowerText.contains('drops') || lowerText.contains('drop')) {
      return MedicationType.drops;
    } else if (lowerText.contains('patch')) {
      return MedicationType.patch;
    }
    
    return MedicationType.tablet; // Default
  }

  DosageFrequency _extractFrequency(String text) {
    final lowerText = text.toLowerCase();
    
    if (lowerText.contains('once daily') || 
        lowerText.contains('once a day') || 
        lowerText.contains('1x daily') ||
        lowerText.contains('od')) {
      return DosageFrequency.onceDaily;
    } else if (lowerText.contains('twice daily') || 
               lowerText.contains('twice a day') || 
               lowerText.contains('2x daily') ||
               lowerText.contains('bid') ||
               lowerText.contains('bd')) {
      return DosageFrequency.twiceDaily;
    } else if (lowerText.contains('three times daily') || 
               lowerText.contains('three times a day') || 
               lowerText.contains('3x daily') ||
               lowerText.contains('tid') ||
               lowerText.contains('tds')) {
      return DosageFrequency.threeTimesDaily;
    } else if (lowerText.contains('four times daily') || 
               lowerText.contains('four times a day') || 
               lowerText.contains('4x daily') ||
               lowerText.contains('qid') ||
               lowerText.contains('qds')) {
      return DosageFrequency.fourTimesDaily;
    } else if (lowerText.contains('every other day') || 
               lowerText.contains('alternate days') ||
               lowerText.contains('eod')) {
      return DosageFrequency.everyOtherDay;
    } else if (lowerText.contains('weekly') || 
               lowerText.contains('once a week') ||
               lowerText.contains('1x week')) {
      return DosageFrequency.weekly;
    } else if (lowerText.contains('as needed') || 
               lowerText.contains('prn') ||
               lowerText.contains('when required')) {
      return DosageFrequency.asNeeded;
    }
    
    return DosageFrequency.onceDaily; // Default
  }

  String? _extractInstructions(List<String> lines) {
    final instructionKeywords = [
      'take', 'apply', 'use', 'inject', 'inhale', 'instill',
      'before', 'after', 'with', 'without', 'food', 'meal',
      'morning', 'evening', 'bedtime', 'empty stomach'
    ];
    
    for (String line in lines) {
      final lowerLine = line.toLowerCase();
      
      // Check if line contains instruction keywords
      if (instructionKeywords.any((keyword) => lowerLine.contains(keyword))) {
        // Make sure it's not just a single word
        if (line.split(' ').length > 2) {
          return line.trim();
        }
      }
    }
    
    return null;
  }

  bool _isCommonNonMedicationWord(String word) {
    final nonMedicationWords = [
      'doctor', 'hospital', 'clinic', 'patient', 'prescription',
      'date', 'name', 'address', 'phone', 'age', 'weight',
      'diagnosis', 'signature', 'seal', 'stamp', 'registered'
    ];
    
    final lowerWord = word.toLowerCase();
    return nonMedicationWords.any((nonMed) => lowerWord.contains(nonMed));
  }

  void dispose() {
    _textRecognizer.close();
  }
}

/// Represents a parsed prescription from OCR text
class ParsedPrescription {
  final String medicationName;
  final String dosage;
  final MedicationType type;
  final DosageFrequency frequency;
  final String? instructions;

  const ParsedPrescription({
    required this.medicationName,
    required this.dosage,
    required this.type,
    required this.frequency,
    this.instructions,
  });

  @override
  String toString() {
    return 'ParsedPrescription(name: $medicationName, dosage: $dosage, type: ${type.displayName}, frequency: ${frequency.displayName})';
  }
}

