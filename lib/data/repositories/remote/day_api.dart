import 'dart:io';

import 'package:smart_vision_application/core/utils/api_helper.dart';
import 'package:smart_vision_application/data/repositories/local/helper.dart';
import 'package:smart_vision_application/domain/entities/upload_file.dart';
import 'package:smart_vision_application/domain/enums/day_type.dart';
import 'package:smart_vision_application/domain/enums/response_type.dart';

class DayApi {
  static Future<DayType> getDayType(File capture) async {
    final data = await ApiHelper.postMultipartRequest(
      endpoint: 'day-type',
      files: [
        UploadFile(name: Helper.getRandom(), path: capture.path)
      ], 
      data: {},
      responseType: ResponseType.text
    );
    return DayType.values.byName(data);
  }
}