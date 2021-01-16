package com.ayoub.custom_multi_imagepicker_2

import androidx.annotation.NonNull
import android.app.Activity.RESULT_CANCELED
import android.app.Activity.RESULT_OK
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
// import io.flutter.plugin.common.PluginRegistry.Registrar
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import android.content.Intent
import android.graphics.Color
import com.esafirm.imagepicker.features.ImagePicker
import com.esafirm.imagepicker.model.Image
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.PluginRegistry.ActivityResultListener

/** CustomMultiImagepicker_2Plugin */
class CustomMultiImagepicker_2Plugin: FlutterPlugin, MethodCallHandler, ActivityAware, ActivityResultListener {
  private val IMAGEPICKER = "com.ayoub.custom_multi_imagepicker_2"
  private lateinit var channel : MethodChannel

  private var activityBinding: ActivityPluginBinding? = null
  private var imagePickerInstent : ImagePicker? = null
  private var imageresulte: Result? = null


  override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, IMAGEPICKER)
    channel.setMethodCallHandler(this)
  }

  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }

  override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {

    when (call.method) {
      "imagepicker" -> {
        imageresulte = result;
        var length: Int = 1
        length = call.argument<Int>("length")!!
        var toolbarFolderTitle: String = "Folder";
        toolbarFolderTitle = call.argument<String>("toolbarFolderTitle")!!;
        var toolbarImageTitle: String = "Folder";
        toolbarImageTitle = call.argument<String>("toolbarImageTitle")!!;
        var toolbarDoneButtonText: String = "Folder";
        toolbarDoneButtonText = call.argument<String>("toolbarDoneButtonText")!!;
        val oldImages: List<Map<String, Any>> = call.argument<List<Map<String, Any>>>("oldImages")!!;
        val exuteImages: List<Map<String, Any>> = call.argument<List<Map<String, Any>>>("exuteImages")!!;
        var camera: Boolean = false;
        camera = call.argument<Boolean>("camera")!!;
        var enableLog: Boolean = false;
        enableLog = call.argument<Boolean>("enableLog")!!;
        var folderMode: Boolean = true;
        folderMode = call.argument<Boolean>("folderMode")!!;
        imagePicker(
                length,
                toolbarFolderTitle,
                toolbarImageTitle,
                toolbarDoneButtonText,
                oldImages,
                exuteImages,
                camera,
                enableLog,
                folderMode)?.start();
      }
      else -> result.notImplemented()
    }
  }

  override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
    if (ImagePicker.shouldHandle(requestCode, resultCode, data)) {
      if (RESULT_CANCELED == resultCode || resultCode != RESULT_OK) {
        imageresulte?.success(mutableListOf<Map<String, Any>>())
        imageresulte = null
        return true
      }
      val images: List<Image>  = ImagePicker.getImages(data);
      val image: Image = ImagePicker.getFirstImageOrNull(data)
      if (images != null && images?.isNotEmpty()!!) {
        val array = mutableListOf<Map<String, Any>>()
        images.forEach { i -> array.add(mapOf("path" to i.path, "id" to i.id, "name" to i.name)) }
        imageresulte?.success(array)
      } else if (image != null) {
        imageresulte?.success(mutableListOf<Map<String, Any>>(mapOf("path" to image.path, "id" to image.id, "name" to image.name)))
      } else {
        imageresulte?.success(mutableListOf<Map<String, Any>>())
      }
      imageresulte = null
      return true;
    }
    return false
  }

  override fun onAttachedToActivity(binding: ActivityPluginBinding) {
    activityBinding = binding;
    imagePickerInstent = ImagePicker.create(binding.activity);
    binding.addActivityResultListener(this)
  }

  override fun onDetachedFromActivity() {
    activityBinding?.removeActivityResultListener(this);
    activityBinding = null
    imagePickerInstent = null
  }

  override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
    onAttachedToActivity(binding)
  }

  override fun onDetachedFromActivityForConfigChanges() {
    onDetachedFromActivity()
  }

  fun imagePicker(
          length: Int,
          toolbarFolderTitle: String = "Folder",
          toolbarImageTitle: String = "Tap to select",
          toolbarDoneButtonText: String = "DONE",
          oldImages: List<Map<String, Any>>?,
          exuteImages: List<Map<String, Any>>?,
          camera: Boolean = false,
          enableLog: Boolean = false,
          folderMode: Boolean = true
  ): ImagePicker? {
    val originImages = arrayListOf<Image>();
    val excludeImages = arrayListOf<Image>();
    originImages.addAll(oldImages?.map { a -> Image((a["id"] as Int).toLong(), a["name"] as String, a["path"] as String) }!!);
    excludeImages.addAll(exuteImages?.map { a -> Image((a["id"] as Int).toLong(), a["name"] as String, a["path"] as String)}!!);
    val iPI= imagePickerInstent
//            .returnMode(ReturnMode. ) // set whether pick and / or camera action should return immediate result or not.
            ?.folderMode(folderMode) // folder mode (false by default)
            ?.toolbarFolderTitle(toolbarFolderTitle) // folder selection title
            ?.toolbarImageTitle(toolbarImageTitle) // image selection title
            ?.toolbarArrowColor(Color.WHITE) // Toolbar 'up' arrow
            ?.toolbarDoneButtonText(toolbarDoneButtonText)
            ?.includeVideo(false) // Show video on image picker
            ?.includeAnimation(false)
            ?.onlyVideo(false)
            ?.limit(length) // max images can be selected (99 by default)
            ?.showCamera(camera) // show camera or not (true by default)
            ?.imageDirectory("Photos") // directory name for captured image  ("Camera" folder by default)
            ?.origin(originImages) // original selected images, used in multi mode
            ?.exclude(excludeImages) // exclude anything that in image.getPath()
//            ?.theme(R.style.CustomImagePickerTheme) // must inherit ef_BaseTheme. please refer to sample
            ?.enableLog(enableLog) // disabling log
    if (length > 1) return iPI?.multi();
    else return iPI?.single();
  }
}
