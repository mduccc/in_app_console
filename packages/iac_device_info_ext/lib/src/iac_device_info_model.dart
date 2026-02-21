class IacDeviceInfoModel {
  const IacDeviceInfoModel({
    required this.platform,
    required this.osVersion,
    required this.model,
    required this.manufacturer,
    required this.architecture,
    required this.totalRam,
    this.additionalInfo,
  });

  final String platform;
  final String osVersion;
  final String model;
  final String manufacturer;
  final String architecture;
  final String totalRam;
  final String? additionalInfo;

  String toFormattedString({
    required String screenResolution,
    required String pixelRatio,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('=== Device Information ===');
    buffer.writeln('Platform: $platform');
    buffer.writeln('OS Version: $osVersion');
    buffer.writeln('Model: $model');
    if (manufacturer.isNotEmpty) buffer.writeln('Manufacturer: $manufacturer');
    buffer.writeln('Architecture: $architecture');
    buffer.writeln('Total RAM: $totalRam');
    buffer.writeln('Screen Resolution: $screenResolution');
    buffer.writeln('Pixel Ratio: $pixelRatio');
    if (additionalInfo != null) buffer.writeln('Additional: $additionalInfo');
    return buffer.toString().trim();
  }
}
