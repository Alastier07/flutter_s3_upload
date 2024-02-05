import 'dart:io';
import 'dart:math';

import 'package:aws_s3_api/s3-2006-03-01.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  File? _file;
  bool _isUploading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              height: 200,
              width: 200,
              child: _file == null
                  ? const Icon(
                      Icons.broken_image_rounded,
                      size: 100,
                    )
                  : Image.file(
                      _file!,
                      fit: BoxFit.cover,
                    ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isUploading
                  ? null
                  : () async {
                      FilePickerResult? result =
                          await FilePicker.platform.pickFiles();

                      if (result != null) {
                        setState(() {
                          _file = File(result.files.single.path!);
                        });
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                fixedSize: const Size(140, 0),
              ),
              child: const Text('Choose File'),
            ),
            const SizedBox(height: 4),
            ElevatedButton(
              onPressed:
                  _isUploading ? null : () => setState(() => _file = null),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                fixedSize: const Size(140, 0),
              ),
              child: const Text('Clear File'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _file == null
                  ? null
                  : () async {
                      final uniqueFileName = generateRandomString(8);

                      setState(() => _isUploading = true);

                      await uploadFileToS3(
                        file: _file!,
                        bucketName: dotenv.get('S3_BUCKET_NAME'),
                        key: '${dotenv.get('S3_BUCKET_KEY')}/$uniqueFileName',
                        awsRegion: dotenv.get('AWS_REGION'),
                        credentials: AwsClientCredentials(
                          accessKey: dotenv.get('AWS_ACCESS_KEY'),
                          secretKey: dotenv.get('AWS_SECRET_KEY'),
                        ),
                      ).then(
                        (value) {
                          if (value == 1) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('File uploaded successfully!'),
                              ),
                            );

                            setState(() => _file = null);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'Something went wrong, please try again.'),
                              ),
                            );
                          }
                        },
                      );

                      setState(
                        () => _isUploading = false
                      );
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                fixedSize: const Size(140, 0),
              ),
              child: _isUploading
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(),
                    )
                  : const Text('Upload'),
            ),
          ],
        ),
      ),
    );
  }

  Future<int> uploadFileToS3({
    required File file,
    required String bucketName,
    required String key,
    required String awsRegion,
    required AwsClientCredentials credentials,
  }) async {
    try {
      final api = S3(
        region: awsRegion,
        credentials: credentials,
      );

      await api.putObject(
        bucket: bucketName,
        key: key,
        body: file.readAsBytesSync(),
      );

      api.close();

      print('File uploaded successfully!');

      return 1;
    } catch (e) {
      print('Error uploading _file: $e');

      return 2;
    }
  }

  String generateRandomString(int length) {
    const characters = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final random = Random();
    return String.fromCharCodes(
      Iterable.generate(
        length,
        (_) => characters.codeUnitAt(
          random.nextInt(characters.length),
        ),
      ),
    );
  }
}
