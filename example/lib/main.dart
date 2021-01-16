import 'package:flutter/material.dart';
import 'package:custom_multi_imagepicker_2/custom_multi_imagepicker_2.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Page(),
    );
  }
}

class Page extends StatefulWidget {
  Page({Key key}) : super(key: key);

  @override
  _PageState createState() => _PageState();
}

class _PageState extends State<Page> {
  List<ImagePickerData> images = List<ImagePickerData>.empty();
  pick(BuildContext context) async {
    final images = await CustomMultiImagepicker2.cameraOrGallery(context,
        length: 5, oldImages: this.images);
    setState(() {
      this.images = images ?? List<ImagePickerData>.empty();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Plugin example app'),
      ),
      body: Wrap(
        children: images.map(imageWidget).toList(),
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.photo),
        onPressed: () => pick(context),
      ),
    );
  }

  Widget imageWidget(ImagePickerData image) {
    final width = MediaQuery.of(context).size.width / 2 - 40;
    return Container(
      height: width,
      width: width,
      margin: EdgeInsets.all(20),
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: Theme.of(context).primaryColor,
          image: DecorationImage(
            image: FileImage(image.file),
            fit: BoxFit.cover,
          )),
    );
  }
}
