import 'dart:io';

import 'package:aws_s3_api/s3-2006-03-01.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  File? file;

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
              child: file == null
                  ? const Icon(
                      Icons.broken_image_rounded,
                      size: 100,
                    )
                  : Image.file(
                      file!,
                      fit: BoxFit.cover,
                    ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                FilePickerResult? result =
                    await FilePicker.platform.pickFiles();

                if (result != null) {
                  setState(() {
                    file = File(result.files.single.path!);
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
              onPressed: () => setState(() => file = null),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                fixedSize: const Size(140, 0),
              ),
              child: const Text('Clear File'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: file == null
                  ? null
                  : () => uploadFileToS3(
                        file: file!,
                        bucketName: '',
                        key: '',
                        s3Region: '',
                        credentials: AwsClientCredentials(
                          accessKey: '',
                          secretKey: '',
                        ),
                      ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                fixedSize: const Size(140, 0),
              ),
              child: const Text('Upload'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> uploadFileToS3({
    required File file,
    required String bucketName,
    required String key,
    required String s3Region,
    required AwsClientCredentials credentials,
  }) async {
    try {
      final api = S3(
        region: s3Region,
        credentials: credentials,
      );

      await api.putObject(
        bucket: bucketName,
        key: key,
        body: file.readAsBytesSync(),
      );

      api.close();

      print('File uploaded successfully!');
    } catch (e) {
      print('Error uploading file: $e');
    }
  }
}
