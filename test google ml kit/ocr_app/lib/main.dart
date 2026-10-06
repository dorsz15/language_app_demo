import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

void main() => runApp(const OcrApp());

class OcrApp extends StatelessWidget {
  const OcrApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Simple OCR',
      theme: ThemeData(colorSchemeSeed: Colors.teal, useMaterial3: true),
      home: const OcrPage(),
    );
  }
}

class OcrPage extends StatefulWidget {
  const OcrPage({super.key});

  @override
  State<OcrPage> createState() => _OcrPageState();
}

class _OcrPageState extends State<OcrPage> {
  final ImagePicker _picker = ImagePicker();
  // Latin script covers English, Polish, German, Spanish, French, etc.
  final TextRecognizer _recognizer =
      TextRecognizer(script: TextRecognitionScript.latin);

  File? _image;
  String _text = '';
  bool _busy = false;

  @override
  void dispose() {
    _recognizer.close();
    super.dispose();
  }

  Future<void> _capture(ImageSource source) async {
    try {
      final XFile? picked =
          await _picker.pickImage(source: source, imageQuality: 90);
      if (picked == null) return;

      setState(() {
        _image = File(picked.path);
        _text = '';
        _busy = true;
      });

      final input = InputImage.fromFilePath(picked.path);
      final RecognizedText result = await _recognizer.processImage(input);

      setState(() {
        _text = result.text.isEmpty ? '(no text found)' : result.text;
        _busy = false;
      });
    } catch (e) {
      setState(() {
        _text = 'Error: $e';
        _busy = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Simple OCR')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _busy ? null : () => _capture(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Take photo'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed:
                        _busy ? null : () => _capture(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Gallery'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_image != null)
              SizedBox(
                height: 200,
                child: Image.file(_image!, fit: BoxFit.contain),
              ),
            const SizedBox(height: 16),
            if (_busy) const LinearProgressIndicator(),
            Expanded(
              child: SingleChildScrollView(
                child: SelectableText(
                  _text.isEmpty && !_busy
                      ? 'Take a photo to extract text.'
                      : _text,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
            if (_text.isNotEmpty && !_busy)
              TextButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: _text));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Copied to clipboard')),
                  );
                },
                icon: const Icon(Icons.copy),
                label: const Text('Copy text'),
              ),
          ],
        ),
      ),
    );
  }
}
