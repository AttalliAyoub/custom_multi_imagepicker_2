part of custom_multi_imagepicker_2;

final _cache = DefaultCacheManager();

class _ImagePickerData {
  final int id;
  final String name;
  final String path;

  const _ImagePickerData.constCON({
    @required this.id,
    @required this.path,
    @required this.name,
  });

  _ImagePickerData({
    @required this.id,
    @required this.path,
    @required this.name,
  }) : assert(path?.isNotEmpty ?? false);

  Map<String, dynamic> get map => {
        if (path?.isNotEmpty ?? false) 'path': path,
        if (!(id?.isNaN ?? true)) 'id': id,
        if (name?.isNotEmpty ?? false) 'name': name
      };

  File get file => File(path);

  @override
  bool operator ==(dynamic other) {
    if (other is ImagePickerData) {
      return other.id == id &&
          (other.path == path || other?.orginal?.path == path);
    }
    return false;
  }

  @override
  int get hashCode {
    return id;
  }
}

class ImagePickerData extends _ImagePickerData {
  _ImagePickerData _orginal;
  final ThembNileConfiguration thembNileConfiguration;
  @override
  String path;
  String url;
  bool _icCropped = false;
  bool _isUrlCropped = false;
  bool get icCropped => _icCropped;
  bool get isUrlCropped => _isUrlCropped;

  static Future<ImagePickerData> fromURL(String url) async {
    File file = await _cache.getSingleFile(url);
    return ImagePickerData(
      id: file.path.hashCode,
      url: url,
      name: basenameWithoutExtension(file.path),
      path: file.path,
    );
  }

  ImagePickerData({
    int id,
    this.path,
    this.url,
    String name,
    this.thembNileConfiguration = const ThembNileConfiguration(),
  })  : _orginal = _ImagePickerData.constCON(id: id, name: name, path: path),
        super(id: id, name: name, path: path) {
    if (url?.isNotEmpty ?? false) _icCropped = true;
    _createThubmbnile();
  }

  ImagePickerData.frmMap(Map<String, dynamic> map,
      {this.thembNileConfiguration = const ThembNileConfiguration()})
      : this.path = map['path'],
        this.url = map['url'],
        _orginal = _ImagePickerData.constCON(
            id: map['id'], name: map['name'], path: map['path']),
        super(path: map['path'], id: map['id'], name: map['name']) {
    if (url?.isNotEmpty ?? false) _icCropped = true;
    _createThubmbnile();
  }

  void _crop(File file) {
    assert((file?.existsSync() ?? false) && (file?.path?.isNotEmpty ?? false));
    path = file.path;
    if (url?.isNotEmpty ?? false) _isUrlCropped = true;
    _icCropped = true;
  }

  _ImagePickerData get orginal => _orginal;

  final Completer<File> _thubmbnileCompleter = Completer<File>();

  Future<File> get thubmbnile => _thubmbnileCompleter.future;

  void _createThubmbnile() async {
    final dirti = await getTemporaryDirectory();
    final fileName = basenameWithoutExtension(path);
    final targetdir = '${dirti.path}/$fileName$id.jpg';
    final resulte = await FlutterImageCompress.compressAndGetFile(
        file.path, targetdir,
        format: CompressFormat.jpeg,
        quality: thembNileConfiguration.quality,
        minHeight: thembNileConfiguration.minHeight,
        minWidth: thembNileConfiguration.minWidth);
    _thubmbnileCompleter.complete(resulte);
  }
}
