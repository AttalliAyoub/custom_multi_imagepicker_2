library custom_multi_imagepicker_2;

import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'dart:math';
import 'package:camera/camera.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:screen/screen.dart';
import 'package:shimmer/shimmer.dart';
import 'package:native_device_orientation/native_device_orientation.dart';
export 'package:image_cropper/src/options.dart'
    show
        CropAspectRatio,
        CropAspectRatioPreset,
        ImageCompressFormat,
        CropStyle,
        AndroidUiSettings,
        IOSUiSettings;

part 'image_picker_widget.dart';
part 'Image_picker_data.dart';
part 'themb_nile_configuration.dart';

enum _Handlerpermission { cam, storage, both }

class CustomMultiImagepicker2 {
  static const MethodChannel _channel =
      const MethodChannel('com.ayoub.custom_multi_imagepicker_2');

  static List<CameraDescription> _cameras = [];

  static Future<void> _initCams() async {
    try {
      if (_cameras == null || (_cameras?.isEmpty ?? true))
        _cameras = await availableCameras();
    } catch (err) {
      print(err);
    }
  }

  static Future<MapEntry<Permission, bool>> _permissionStatus(
      Permission permissionName) async {
    try {
      final status = await permissionName.status;
      // final status = await Permission.getSinglePermissionStatus(permissionName);
      if (status == PermissionStatus.granted)
        return MapEntry(permissionName, true);
      return MapEntry(permissionName, false);
    } catch (err) {
      print(err);
      return MapEntry(permissionName, false);
    }
  }

  static Future<Map<Permission, bool>> _requestPermission(
      Iterable<Permission> permissionNames) async {
    try {
      // final status = await permissionNames.fold(null, (a, b) {
      //   return a.request().then((value) => b.request());
      // });
      final status = Map<Permission, bool>();
      for (final permission in permissionNames) {
        status[permission] = await permission
            .request()
            .then((s) => s == PermissionStatus.granted);
      }
      return status;
      // // final status = await _permissionHandler
      // //     .requestPermissions(permissionNames?.toList() ?? []);
      // return status
      //     .map((k, v) => MapEntry(k, status[v] == PermissionStatus.granted));
    } catch (err) {
      print(err);
      return Map<Permission, bool>.identity();
    }
  }

  static Future<Map<Permission, bool>> per(
      {List<Permission> list, _Handlerpermission type}) async {
    assert(type == null && (list.isNotEmpty ?? false) ||
        type != null && (list?.isEmpty ?? true));
    // Permission.camera.
    List<Permission> _list = list ?? [];
    switch (type) {
      case _Handlerpermission.cam:
        _list = [Permission.camera];
        break;
      case _Handlerpermission.storage:
        _list = [Permission.storage];
        break;
      case _Handlerpermission.both:
        _list = [Permission.camera, Permission.storage];
        break;
      default:
        break;
    }
    if (_list?.isNotEmpty ?? false) {
      final List<Permission> statusList = [];

      for (var i in _list) {
        final e = await _permissionStatus(i);
        if (!(e?.value ?? true)) statusList.add(e.key);
      }
      print(statusList);
      if (statusList?.isNotEmpty ?? false) {
        final a = await _requestPermission(statusList);
        return a;
      }
    }
    return Map<Permission, bool>.identity();
  }

  static Future<ImagePickerData> cropOnly(
    ImagePickerData old, {
    int maxWidth,
    int maxHeight,
    CropAspectRatio aspectRatio,
    List<CropAspectRatioPreset> aspectRatioPresets = const [
      CropAspectRatioPreset.original,
      CropAspectRatioPreset.square,
      CropAspectRatioPreset.ratio3x2,
      CropAspectRatioPreset.ratio4x3,
      CropAspectRatioPreset.ratio16x9
    ],
    CropStyle cropStyle = CropStyle.rectangle,
    ImageCompressFormat compressFormat = ImageCompressFormat.jpg,
    int compressQuality = 90,
    AndroidUiSettings androidUiSettings,
    IOSUiSettings iosUiSettings,
  }) async {
    final file = await ImageCropper.cropImage(
      sourcePath: old.orginal.path ?? old.path,
      maxHeight: maxHeight,
      maxWidth: maxWidth,
      androidUiSettings: androidUiSettings,
      aspectRatio: aspectRatio,
      aspectRatioPresets: aspectRatioPresets,
      compressFormat: compressFormat,
      compressQuality: compressQuality,
      cropStyle: cropStyle,
      iosUiSettings: iosUiSettings,
    );
    if (file?.existsSync() ?? false) {
      old._crop(file);
    } else {
      final dirti = await getTemporaryDirectory();
      final fileName = basenameWithoutExtension(old.path);
      final targetdir = '${dirti.path}/$fileName${old.id}.jpg';
      final file2 = await FlutterImageCompress.compressAndGetFile(
          old.path, targetdir,
          format: CompressFormat.jpeg,
          quality: compressQuality,
          minHeight: maxHeight,
          minWidth: maxWidth);
      if (file2?.existsSync() ?? false) old._crop(file2);
    }
    return old;
  }

  static Future<List<ImagePickerData>> cameraOrGallery(
    BuildContext context, {
    bool useCropper = false,
    bool bottomSheetUI,
    bool useComprasor = false,
    int length = 1,
    int maxWidth,
    int maxHeight,
    String titleText,
    String messageText,
    String cancelText,
    String cameraText = 'Camera',
    String galleryText = 'Gallery',
    String toolbarFolderTitle = "Folder",
    String toolbarImageTitle = "Tap to select",
    String toolbarDoneButtonText = "DONE",
    bool usecameraInGallery = false,
    bool enableLogInGallery = false,
    bool folderModeGallery = true,
    List<ImagePickerData> oldImages = const <ImagePickerData>[],
    List<ImagePickerData> excloudImages = const <ImagePickerData>[],
    CropAspectRatio croperAspectRatio,
    List<CropAspectRatioPreset> croperAspectRatioPresets = const [
      CropAspectRatioPreset.original,
      CropAspectRatioPreset.square,
      CropAspectRatioPreset.ratio3x2,
      CropAspectRatioPreset.ratio4x3,
      CropAspectRatioPreset.ratio16x9
    ],
    CropStyle cropStyle = CropStyle.rectangle,
    ImageCompressFormat compressCroperFormat = ImageCompressFormat.jpg,
    int compressCroperQuality = 90,
    AndroidUiSettings androidCroperUiSettings,
    IOSUiSettings iosCroperUiSettings,
  }) async {
    assert(maxWidth == null || maxWidth > 0);
    assert(maxHeight == null || maxHeight > 0);
    assert(compressCroperQuality >= 0 && compressCroperQuality <= 100);
    assert(useCropper != null);

    await CustomMultiImagepicker2._initCams();

    void camera() async {
      await per(type: _Handlerpermission.cam);
      final imageFile = await Navigator.of(context)
          .push<List<ImagePickerData>>(MaterialPageRoute(
              builder: (context) => _MyImagePicker(
                    useCroper: useCropper,
                    useComprasor: useComprasor,
                    androidUiSettings: androidCroperUiSettings,
                    aspectRatio: croperAspectRatio,
                    aspectRatioPresets: croperAspectRatioPresets,
                    compressFormat: compressCroperFormat,
                    compressQuality: compressCroperQuality,
                    cropStyle: cropStyle,
                    iosUiSettings: iosCroperUiSettings,
                    length: length,
                    oldImages: oldImages,
                    maxHeight: maxHeight,
                    maxWidth: maxWidth,
                  )));
      Navigator.of(context).pop(imageFile);
    }

    void gallery() async {
      await per(
          type: usecameraInGallery
              ? _Handlerpermission.both
              : _Handlerpermission.storage);
      final List<dynamic> imgs = [];
      try {
        final resulte = await _channel.invokeListMethod('imagepicker', {
          'length': length,
          'toolbarFolderTitle': toolbarFolderTitle,
          'toolbarImageTitle': toolbarImageTitle,
          'toolbarDoneButtonText': toolbarDoneButtonText,
          'oldImages': oldImages.map((i) => i._orginal.map).toList(),
          'exuteImages': excloudImages.map((i) => i.orginal.map).toList(),
          'camera': usecameraInGallery,
          'enableLog': enableLogInGallery,
          'folderMode': folderModeGallery
        });
        if (resulte?.isNotEmpty ?? false) imgs.addAll(resulte);
        // _channel.invokeMethod('end');
      } catch (err) {
        // _channel.invokeMethod('end');
        print(err);
      }
      final listOfImages = imgs
              ?.map((i) => ImagePickerData.frmMap(Map<String, dynamic>.from(i)))
              ?.toList() ??
          [];
      final dirti = await getTemporaryDirectory();
      for (ImagePickerData i in listOfImages) {
        if (oldImages.any((oi) => oi.id == i.id && oi.url != null)) {
          i.url = oldImages
                  .firstWhere((oi) => oi.id == i.id && oi.url != null,
                      orElse: () => null)
                  ?.url ??
              '';
        }
        if (useCropper) {
          if (oldImages.any((oi) => oi.id == i.id && oi.icCropped))
            i._icCropped = true; // ._crop(i.file);
          else {
            final file = await ImageCropper.cropImage(
              sourcePath: i.path,
              androidUiSettings: androidCroperUiSettings,
              aspectRatio: croperAspectRatio,
              aspectRatioPresets: croperAspectRatioPresets,
              compressFormat: compressCroperFormat,
              compressQuality: compressCroperQuality,
              cropStyle: cropStyle,
              iosUiSettings: iosCroperUiSettings,
              maxHeight: maxHeight,
              maxWidth: maxWidth,
            );
            if (file?.existsSync() ?? false)
              i._crop(file);
            else {
              final fileName = basenameWithoutExtension(i.path);
              final targetdir = '${dirti.path}/$fileName${i.id}.jpg';
              final file2 = await FlutterImageCompress.compressAndGetFile(
                  i.path, targetdir,
                  format: CompressFormat.jpeg,
                  quality: compressCroperQuality,
                  minHeight: maxHeight,
                  minWidth: maxWidth);
              if (file2?.existsSync() ?? false) i._crop(file2);
            }
          }
        } else if (useComprasor) {
          // for (ImagePickerData i in listOfImages) {
          if (oldImages.any((oi) => oi.id == i.id && oi.icCropped))
            i._icCropped = true; //._crop(i.file);
          else {
            final fileName = basenameWithoutExtension(i.path);
            final targetdir = '${dirti.path}/$fileName${i.id}.jpg';
            final file = await FlutterImageCompress.compressAndGetFile(
                i.path, targetdir,
                format: CompressFormat.jpeg,
                quality: compressCroperQuality,
                minHeight: maxHeight,
                minWidth: maxWidth);
            i._crop(file);
          }
        }
      }
      Navigator.of(context).pop(listOfImages);
    }

    final builder = (context) {
      return ClipRRect(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        child: BottomSheet(
          elevation: 0,
          enableDrag: true,
          backgroundColor: Colors.black12,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
          builder: (BuildContext context) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text(
                      '   ${Upload From}',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      tooltip: 'Close',
                      icon: Icon(Icons.close),
                      onPressed: Navigator.of(context).pop,
                    ),
                  ],
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).dialogBackgroundColor,
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(25)),
                    boxShadow: [
                      BoxShadow(
                          offset: Offset(0, 0),
                          blurRadius: 20,
                          spreadRadius: -5,
                          color: Colors.black),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: <Widget>[
                      Expanded(
                        child: ButtonTheme(
                          buttonColor:
                              Theme.of(context).scaffoldBackgroundColor,
                          height: 70,
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.vertical(top: Radius.circular(25)),
                          ),
                          // minWidth: 70;
                          child: FlatButton.icon(
                            textColor: Theme.of(context).accentColor,
                            icon: Icon(Icons.camera_alt),
                            label: Text(cameraText??'Camera'),
                            onPressed: camera,
                          ),
                        ),
                      ),
                      Expanded(
                        child: ButtonTheme(
                          height: 70,
                          // minWidth: 70;
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.vertical(top: Radius.circular(25)),
                          ),
                          buttonColor:
                              Theme.of(context).scaffoldBackgroundColor,
                          child: FlatButton.icon(
                            textColor: Theme.of(context).accentColor,
                            icon: Icon(Icons.collections),
                            label: Text(galleryText??'Gallery'),
                            onPressed: gallery,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
          onClosing: () {
            print('hi therer');
          },
        ),
      );
    };

    List<ImagePickerData> resulte = [];

    if (bottomSheetUI == true ||
        Theme.of(context).platform == TargetPlatform.iOS) {
      resulte = await showCupertinoModalPopup<List<ImagePickerData>>(
          context: context,
          builder: (_context) {
            return CupertinoActionSheet(
              cancelButton: CupertinoActionSheetAction(
                child: Text(cancelText??'Cancel'),
                onPressed: Navigator.of(_context).pop,
              ),
              // Upload From
              message: Text(messageText??'how do you want to Upload the Image ?'),
              title: Text(titleText??'Upload From'),
              actions: <Widget>[
                CupertinoActionSheetAction(
                  isDefaultAction: true,
                  isDestructiveAction: true,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Icon(Icons.photo_camera,
                          color: Theme.of(_context).primaryColor),
                      SizedBox(width: 8.0),
                      Text(cameraText ?? 'Camera',
                          style: TextStyle(
                              color: Theme.of(_context).primaryColor)),
                    ],
                  ),
                  onPressed: camera,
                ),
                CupertinoActionSheetAction(
                  isDefaultAction: true,
                  isDestructiveAction: true,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Icon(Icons.collections,
                          color: Theme.of(_context).primaryColor),
                      SizedBox(width: 8.0),
                      Text(galleryText ?? 'Gallery',
                          style: TextStyle(
                              color: Theme.of(_context).primaryColor)),
                    ],
                  ),
                  onPressed: gallery,
                ),
              ],
            );
          });
    } else if (bottomSheetUI == false ||
        Theme.of(context).platform == TargetPlatform.android) {
      resulte = await showModalBottomSheet<List<ImagePickerData>>(
          context: context,
          isScrollControlled: false,
          elevation: 5,
          useRootNavigator: true,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
          builder: builder);
    }
    print(resulte);
    return resulte;
  }
}
