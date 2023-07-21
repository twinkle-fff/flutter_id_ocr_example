import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:ocr/util/camera.dart';

List<CameraDescription> cameras = [];

class CameraPage extends StatefulWidget {
  const CameraPage({Key? key}) : super(key: key);

  @override
  State<CameraPage> createState() => _CameraState();
}

class _CameraState extends State<CameraPage> {
  late CameraController _controller;
  final TextRecognizer _textRecognizer =
  TextRecognizer(script: TextRecognitionScript.japanese);
  bool isReady = false;
  bool skipScanning = false;
  bool isScanned = false;
  RecognizedText? _recognizedText;
  String result = "";

  @override
  void initState() {
    super.initState();
    _setup();
  }

  @override
  void dispose() {
    _controller.dispose();
    _textRecognizer.close();
    super.dispose();
  }

  _processImage(CameraImage availableImage) async {
    if (!mounted || skipScanning) return;
    setState(() {
      skipScanning = true;
    });

    final inputImage = convert(
      camera: cameras[0],
      cameraImage: availableImage,
    );

    _recognizedText = await _textRecognizer.processImage(inputImage);
    if (!mounted) return;
    setState(() {
      skipScanning = false;
    });
    if (_recognizedText != null && _recognizedText!.text.isNotEmpty) {


      // Todo: 再帰処理
      bool isFinish = false;
      // print(_recognizedText?.text ?? "");

      final t = _recognizedText?.text ?? "";
      List<String> ts = t.split("\n");
      ts.forEach((element) {
        print(element);
        if(element.contains("平成") || element.contains("昭和")) {
          print("done");
          if (element.contains("年") && element.contains("月") &&
              element.contains("日")/* && element.contains("生")*/) {
            _controller.stopImageStream();
            result = element;
            setState(() {
              isScanned = true;

            });
            isFinish = true;
          }
        }
      });
      print("re");
      if(isFinish){return;}
      // _controller.stopImageStream();
      await _controller.stopImageStream();
      _controller.startImageStream(_processImage);


      // _controller.stopImageStream();
      // setState(() {
      //   isScanned = true;
      // });
    }
  }

  Future<void> _setup() async {
    cameras = await availableCameras();
    _controller = CameraController(cameras[0], ResolutionPreset.max);
    await _controller.initialize().catchError((Object e) {
      if (e is CameraException) {
        switch (e.code) {
          case 'CameraAccessDenied':
            print('User denied camera access.');
            break;
          default:
            print('Handle other errors.');
            break;
        }
      }
    });
    if (!mounted) {
      return;
    }
    setState(() {
      isReady = true;
    });
    await _controller.startImageStream(_processImage);
  //  再読み込み


  }

  @override
  Widget build(BuildContext context) {
    final isLoading = !isReady || !_controller.value.isInitialized;
    return Scaffold(
      appBar: AppBar(
        title: const Text('テキスト読み取り画面'),
      ),
      body: Column(
          children: isLoading
              ? [const Center(child: CircularProgressIndicator())]
              : [
            Padding(
                padding: const EdgeInsets.all(20),
                child: AspectRatio(
                  aspectRatio: 12 / 9,
                  child: Stack(
                    children: [
                      ClipRect(
                        child: Transform.scale(
                          scale: _controller.value.aspectRatio * 12 / 9,
                          child: Center(
                            child: CameraPreview(_controller),
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
            isScanned
                ? ElevatedButton(
              child: const Text('再度読み取る'),
              onPressed: () {
                setState(() {
                  isScanned = false;
                  _recognizedText = null;
                });
                _controller.startImageStream(_processImage);
              },
            )
                : const Text('読み込み中'),
            Expanded(
              flex: 1,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Text(
                    // _recognizedText != null ? _recognizedText!.text : ''
                    result),
              ),
            )
          ]),
    );
  }
}