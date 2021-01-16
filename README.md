<!--
  Title: Flutter Windows Vautl
  Description: flutter Windows to store read/write data into credential manager, with encryption.
  Author: Attalli Ayoub @AttalliAyoub <attalliayoub50@gmail.com>
  -->
# custom_multi_imagepicker_2

flutter multi image picker with cropper and compressor
<meta name='keywords' content='flutter, android, ktolin, multi image picker, image, compressor, cropper'>

used in this plugin
    packages:
        - flutter_image_compress
        - image_cropper
        - permission_handler
        - shimmer
        - native_device_orientation
        - flutter_cache_manager
    libraries:
        // android native library
        - https://github.com/esafirm/android-image-picker


## Getting Started
simple example
```dart
import 'package:custom_multi_imagepicker/custom_multi_imagepicker.dart';

// simage image getting
    final images = await CustomMultiImagepicker2.cameraOrGallery(context, length: 5);
    print(images.first.path);
```
with all the options

```dart
    final images = await CustomMultiImagepicker2.cameraOrGallery(
      context,
      length: 5,
      oldImages: this.images,
      androidCroperUiSettings: AndroidUiSettings(),
      bottomSheetUI: true,
      compressCroperFormat: ImageCompressFormat.jpg,
      compressCroperQuality: 90,
      cropStyle: CropStyle.circle,
      croperAspectRatio: CropAspectRatio(ratioX: 1, ratioY: 1),
      croperAspectRatioPresets: [
        CropAspectRatioPreset.original,
        CropAspectRatioPreset.ratio16x9,
        CropAspectRatioPreset.square,
      ],
      enableLogInGallery: true,
      iosCroperUiSettings: IOSUiSettings(),
      excloudImages: [],
      folderModeGallery: true,
      maxHeight: 900,
      maxWidth: 900,
      toolbarDoneButtonText: '',
      toolbarFolderTitle: '',
      toolbarImageTitle: '',
      usecameraInGallery: false,
      useComprasor: true,
      useCropper: true,
    );
    print(images);
```

### support the author
<a href="https://www.buymeacoffee.com/attalliayoub" target="_blank"><img src="https://cdn.buymeacoffee.com/buttons/v2/default-yellow.png" alt="Buy Me A Coffee" style="height: 30px !important;width: 108.5px !important;" ></a>