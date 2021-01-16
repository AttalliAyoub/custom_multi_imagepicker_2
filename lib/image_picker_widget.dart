part of custom_multi_imagepicker_2;

class _MyImagePicker extends StatefulWidget {
  final int length, maxWidth, maxHeight;
  final bool useCroper, useComprasor;
  // final String sourcePath;
  final List<CropAspectRatioPreset> aspectRatioPresets;
  final CropAspectRatio aspectRatio;
  final CropStyle cropStyle;
  final ImageCompressFormat compressFormat;
  final int compressQuality;
  final AndroidUiSettings androidUiSettings;
  final IOSUiSettings iosUiSettings;
  final List<ImagePickerData> oldImages;

  _MyImagePicker({
    @required this.useCroper = false,
    @required this.useComprasor = false,
    this.length = 1,
    this.maxWidth,
    this.maxHeight,
    this.aspectRatio,
    this.oldImages = const [],
    this.aspectRatioPresets = const [
      CropAspectRatioPreset.original,
      CropAspectRatioPreset.square,
      CropAspectRatioPreset.ratio3x2,
      CropAspectRatioPreset.ratio4x3,
      CropAspectRatioPreset.ratio16x9
    ],
    this.cropStyle = CropStyle.rectangle,
    this.compressFormat = ImageCompressFormat.jpg,
    this.compressQuality = 90,
    this.androidUiSettings,
    this.iosUiSettings,
  })  : assert(maxWidth == null || maxWidth > 0),
        assert(maxHeight == null || maxHeight > 0),
        assert(compressQuality >= 0 && compressQuality <= 100);

  @override
  _MyImagePickerState createState() {
    return _MyImagePickerState();
  }
}

class _MyImagePickerState extends State<_MyImagePicker> {
  CameraController _controller;
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  Future<void> _initializeControllerFuture;
  Directory extDir;
  bool flash = false, /*hasFlash = false,*/ isTacking = false;
  num angle = 0.0;
  StreamSubscription<NativeDeviceOrientation> sub;
  ImagePickerData currentImage;
  Set<ImagePickerData> images = Set<ImagePickerData>.identity();

  @override
  void initState() {
    super.initState();
    setState(() {
      images.addAll(widget.oldImages);
    });
    Screen.keepOn(true);
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    SystemChrome.setEnabledSystemUIOverlays([]);
    _initCameras();
    sub = NativeDeviceOrientationCommunicator()
        .onOrientationChanged(useSensor: true)
        .listen(listenToOrontation);
  }

  void listenToOrontation(NativeDeviceOrientation data) {
    switch (data) {
      case NativeDeviceOrientation.landscapeLeft:
        angle = pi / 2;
        break;
      case NativeDeviceOrientation.landscapeRight:
        angle = -pi / 2;
        break;
      case NativeDeviceOrientation.portraitUp:
        angle = 0.0;
        break;
      case NativeDeviceOrientation.portraitDown:
        angle = pi;
        break;
      default:
        angle = 0;
        break;
    }
    setState(() {});
  }

  @override
  void dispose() {
    _controller?.dispose();
    sub?.cancel();
    super.dispose();
  }

  void _initCameras() async {
    _controller = CameraController(
        CustomMultiImagepicker2._cameras[0], ResolutionPreset.max,
        enableAudio: false);
    _initializeControllerFuture = _controller.initialize();
    await _initializeControllerFuture;
    // hasFlash = await _controller.hasFlash;
    // flash = _controller.flashMode != FlashMode.off;
    setState(() {});
    extDir = await getTemporaryDirectory();
    try {
      Directory(extDir.path + '/photos').deleteSync(recursive: true);
    } catch (err) {
      print(err);
    }
    extDir = await Directory(extDir.path + '/photos').create(recursive: true);
    setState(() {});
  }

  Widget _rotate({Widget child}) {
    return Transform.rotate(child: child, angle: angle);
  }

  Future<void> _dispose() {
    return Future.wait([
      Screen.keepOn(false),
      _controller.dispose(),
      SystemChrome.setPreferredOrientations(
          [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]),
      SystemChrome.setEnabledSystemUIOverlays(SystemUiOverlay.values),
    ]);
  }

  _swithcCam() async {
    await CustomMultiImagepicker2._initCams();
    final CameraDescription cameraDescription =
        (_controller.description == CustomMultiImagepicker2._cameras[0])
            ? (CustomMultiImagepicker2._cameras[1] ?? null)
            : CustomMultiImagepicker2._cameras[0];
    if (_controller != null) {
      await _controller.dispose();
    }
    _controller = CameraController(
      cameraDescription,
      ResolutionPreset.max,
      enableAudio: false,
    );
    _controller.addListener(() {
      if (mounted) setState(() {});
      if (_controller.value.hasError) {
        showSnackBar('Camera error ${_controller.value.errorDescription}');
      }
    });
    try {
      _initializeControllerFuture = _controller.initialize();
      await _initializeControllerFuture;
      // hasFlash = await _controller.hasFlash;
      // flash = _controller.flashMode != FlashMode.off;
      setState(() {
        flash = false;
      });
    } on CameraException catch (e) {
      showSnackBar(e.description);
    }
    if (mounted) {
      setState(() {});
    }
  }

  showSnackBar(String str) {
    _scaffoldKey.currentState.showSnackBar(SnackBar(
      content: Text(str),
      action: SnackBarAction(
        label: 'Dismiss',
        onPressed: () => _scaffoldKey.currentState.hideCurrentSnackBar(),
      ),
    ));
  }

  _flash() async {
    // final status = await _controller.hasFlash;
    // if (status)
    // _controller.setFlash(mode: !flash ? FlashMode.torch : FlashMode.off);
    _controller.setFlashMode(!flash ? FlashMode.torch : FlashMode.off);
    flash = !flash;
    setState(() {});
  }

  Widget thumbnile(ImagePickerData i) {
    return Card(
      child: FutureBuilder(
        future: i.thubmbnile,
        builder: (BuildContext context, AsyncSnapshot<File> fileSna) {
          if ((fileSna?.data?.existsSync() ?? false))
            return _rotate(
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4.0),
                  border: currentImage == i
                      ? Border.all(
                          color: Theme.of(context).accentColor,
                          style: BorderStyle.solid,
                          width: 1)
                      : null,
                  image: DecorationImage(
                    image: FileImage(fileSna.data),
                    alignment: Alignment.center,
                    fit: BoxFit.cover,
                  ),
                ),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(4.0),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(4.0),
                    // onLongPress: () {
                    //   // showDialog(
                    //   //   context: context,
                    //   //   child: AlertDialog(
                    //   //     content: Card(
                    //   //         child: Image.file(i.file,
                    //   //             alignment: Alignment.center,
                    //   //             fit: BoxFit.cover)),
                    //   //     title: Text(i.name),
                    //   //     contentPadding: EdgeInsets.zero,
                    //   //   ),
                    //   // );
                    // },
                    onTap: () {
                      setState(() {
                        currentImage = i;
                      });
                    },
                    child: SizedBox(
                      width: 50,
                      height: 50,
                      child: Center(
                          child: currentImage == i
                              ? Icon(Icons.check_box,
                                  color: Theme.of(context).accentColor)
                              : Material(
                                  color: Colors.transparent,
                                )),
                    ),
                  ),
                ),
              ),
            );
          else
            return Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        try {
          await _dispose();
        } catch (err) {
          print(err);
        }
        return true;
      },
      child: Scaffold(
          key: _scaffoldKey,
          extendBody: true,
          body: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
            return Stack(
              alignment: Alignment.center,
              fit: StackFit.expand,
              overflow: Overflow.clip,
              children: <Widget>[
                FutureBuilder<void>(
                  future: _initializeControllerFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.done) {
                      final size = _controller.value.previewSize;
                      final height = max(size.width, size.height);
                      final width = min(size.width, size.height);
                      return Align(
                        alignment: Alignment.center,
                        child: Container(
                          width: constraints.maxWidth,
                          height: constraints.maxHeight,
                          child: FittedBox(
                            fit: BoxFit.cover,
                            child: SizedBox(
                              height: height,
                              width: width,
                              child: CameraPreview(_controller),
                            ),
                          ),
                        ),
                      );
                    } else {
                      return Center(
                          child: Shimmer.fromColors(
                        baseColor: Theme.of(context).scaffoldBackgroundColor,
                        highlightColor: Theme.of(context).accentColor,
                        child: Icon(Icons.camera_alt, size: 100),
                      ));
                    }
                  },
                ),

                Align(
                  alignment: Alignment.topLeft,
                  child: SafeArea(
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          IconButton(
                              color: Colors.white,
                              icon: _rotate(
                                child: Icon(
                                    flash ? Icons.flash_on : Icons.flash_off),
                              ),
                              onPressed: _flash),
                          if (currentImage != null)
                            IconButton(
                              color: Colors.white,
                              icon: _rotate(child: Icon(Icons.crop)),
                              onPressed: _crop,
                            ),
                          if (currentImage != null)
                            IconButton(
                              color: Colors.white,
                              icon: _rotate(child: Icon(Icons.delete)),
                              onPressed: _deleteFromList,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.topRight,
                  child: SafeArea(
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: IconButton(
                        color: Colors.white,
                        icon: Icon(Icons.cancel),
                        onPressed: () async {
                          await _dispose();
                          Navigator.of(context).pop();
                        },
                      ),
                    ),
                  ),
                ),
                Positioned(
                    left: 8,
                    bottom: 72,
                    child: SafeArea(
                      left: true,
                      right: true,
                      child: SizedBox(
                        height: constraints.maxHeight -
                            72 * 3 -
                            2 * MediaQuery.of(context).padding.top,
                        width: 58,
                        child: ListView(
                          padding: EdgeInsets.zero,
                          physics: const BouncingScrollPhysics(),
                          scrollDirection: Axis.vertical,
                          reverse: true,
                          children:
                              images.map(thumbnile).toList().reversed.toList(),
                        ),
                      ),
                    )),
                Align(
                  alignment: Alignment.bottomLeft,
                  child: SafeArea(
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: AnimatedOpacity(
                        duration: Duration(seconds: 1),
                        opacity: ((images?.length ?? 0) > 0) ? 1.0 : 0.0,
                        child: IconButton(
                          color: Colors.white,
                          icon: _rotate(child: Icon(Icons.check)),
                          onPressed: () => _end(context),
                        ),
                      ),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: SafeArea(
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: IconButton(
                        color: Colors.white,
                        icon: _rotate(child: Icon(Icons.camera)),
                        onPressed:
                            isTacking ? null : () => _captureImage(context),
                      ),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.bottomRight,
                  child: SafeArea(
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: IconButton(
                        color: Colors.white,
                        icon: _rotate(child: Icon(Icons.switch_camera)),
                        onPressed: _swithcCam,
                      ),
                    ),
                  ),
                ),
                // IconButton(
                //   color: Colors.white,
                //   icon: Icon(Icons.camera),
                //   onPressed: isTacking ? null : _captureImage,
                // ),
                // IconButton(
                //   color: Colors.white,
                //   icon: Icon(Icons.switch_camera),
                //   onPressed: _swithcCam,
                // ),
              ],
            );
          })),
    );
  }

  void _captureImage(BuildContext context) async {
    if (_controller?.value?.isInitialized ?? false) {
      // final String filePath = '${extDir.path}/${DateTime.now()}.jpeg';
      setState(() {
        isTacking = true;
      });
      final file = await _controller.takePicture();
      setState(() {
        isTacking = false;
      });
      final image = ImagePickerData(
        id: file.path.hashCode,
        name: basename(file.path),
        path: file.path,
        thembNileConfiguration:
            ThembNileConfiguration(minHeight: 50, minWidth: 50, quality: 80),
      );
      setState(() {
        images.add(image);
      });
      if (widget.length == images.length) _end(context);
    }
  }

  _deleteFromList() {
    setState(() {
      images.remove(currentImage);
      currentImage = null;
    });
  }

  _end(BuildContext context) async {
    final dirti = await getTemporaryDirectory();
    for (ImagePickerData i in images) {
      if (widget.oldImages.any((oi) => oi.id == i.id && oi.url != null)) {
        i.url = widget.oldImages
                .firstWhere((oi) => oi.id == i.id && oi.url != null,
                    orElse: () => null)
                ?.url ??
            '';
      }
      if (widget.useCroper) {
        if (widget.oldImages.any((oi) => oi.id == i.id && oi.icCropped))
          i._icCropped = true; //._crop(i.file);
        else {
          final file = await ImageCropper.cropImage(
            sourcePath: i.path,
            androidUiSettings: widget.androidUiSettings,
            aspectRatio: widget.aspectRatio,
            aspectRatioPresets: widget.aspectRatioPresets,
            compressFormat: widget.compressFormat,
            compressQuality: widget.compressQuality,
            cropStyle: widget.cropStyle,
            iosUiSettings: widget.iosUiSettings,
            maxHeight: widget.maxHeight,
            maxWidth: widget.maxWidth,
          );
          if (file?.existsSync() ?? false)
            i._crop(file);
          else {
            final fileName = basenameWithoutExtension(i.path);
            final targetdir = '${dirti.path}/$fileName${i.id}.jpg';
            final file2 = await FlutterImageCompress.compressAndGetFile(
                i.path, targetdir,
                format: CompressFormat.jpeg,
                quality: widget.compressQuality,
                minHeight: widget.maxHeight,
                minWidth: widget.maxWidth);
            if (file2?.existsSync() ?? false) i._crop(file2);
          }
        }
      } else if (widget.useComprasor) {
        // for (ImagePickerData i in listOfImages) {
        if (widget.oldImages.any((oi) => oi.id == i.id && oi.icCropped))
          i._icCropped = true; //._crop(i.file);
        else {
          final fileName = basenameWithoutExtension(i.path);
          final targetdir = '${dirti.path}/$fileName${i.id}.jpg';
          final file = await FlutterImageCompress.compressAndGetFile(
              i.path, targetdir,
              format: CompressFormat.jpeg,
              quality: widget.compressQuality,
              minHeight: widget.maxHeight,
              minWidth: widget.maxWidth);
          i._crop(file);
        }
      }
    }
    await _dispose();
    Navigator.of(context).pop(images.toList());
  }

  _end2(BuildContext context) async {
    if (widget.useCroper)
      for (var i in images) {
        if (!(i?.icCropped ?? true)) {
          final cropedFie = await ImageCropper.cropImage(
            sourcePath: i.path,
            androidUiSettings: widget.androidUiSettings,
            aspectRatio: widget.aspectRatio,
            aspectRatioPresets: widget.aspectRatioPresets,
            compressFormat: widget.compressFormat,
            compressQuality: widget.compressQuality,
            cropStyle: widget.cropStyle,
            iosUiSettings: widget.iosUiSettings,
            maxHeight: widget.maxHeight,
            maxWidth: widget.maxWidth,
          );
          if (cropedFie?.existsSync() ?? false) i._crop(cropedFie);
        }
      }
    else if (widget.useComprasor) {
      final dirti = await getTemporaryDirectory();
      for (ImagePickerData i in images) {
        // if (oldImages.any(
        //     (oi) => oi.id == i.id && oi.icCropped))
        //   i._crop(i.file);
        // else {
        final fileName = basenameWithoutExtension(i.path);
        final targetdir = '${dirti.path}/$fileName${i.id}.jpg';
        final file = await FlutterImageCompress.compressAndGetFile(
            i.path, targetdir,
            format: CompressFormat.jpeg,
            quality: widget.compressQuality,
            minHeight: widget.maxHeight,
            minWidth: widget.maxWidth);
        i._crop(file);
        // }
      }
    }
    await _dispose();
    Navigator.of(context).pop(images.toList());
  }

  void _crop() async {
    final cropedFie = await ImageCropper.cropImage(
      sourcePath: currentImage.path,
      androidUiSettings: widget.androidUiSettings,
      aspectRatio: widget.aspectRatio,
      aspectRatioPresets: widget.aspectRatioPresets,
      compressFormat: widget.compressFormat,
      compressQuality: widget.compressQuality,
      cropStyle: widget.cropStyle,
      iosUiSettings: widget.iosUiSettings,
      maxHeight: widget.maxHeight,
      maxWidth: widget.maxWidth,
    );
    if (cropedFie?.existsSync() ?? false) currentImage._crop(cropedFie);
  }
}
