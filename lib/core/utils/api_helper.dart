import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../data/repositories/local/cache_repository.dart';
import '../../domain/entities/upload_file.dart';
import '../../domain/enums/response_type.dart';
import '../constants/app_constants.dart';
import 'logger.dart';

class ApiHelper {
  static Future<T> postMultipartRequest<T>(
      {required String endpoint,
      required Map<String, String> data,
      required List<UploadFile> files,
      ResponseType? responseType = ResponseType.json,
      String method = 'POST'
      
    }) async {
    try {
      final Uri uri = Uri.parse('$apiUrl/$endpoint');
      final String? token = await CacheRepository.instance.get('token');
      

      final request = http.MultipartRequest(method, uri);
      request.headers.addAll({
        'token': token ?? '',
      });

      request.fields.addAll(data);

      for (var file in files) {
        request.files.add(await http.MultipartFile.fromPath(file.name, file.path));
      }

      final response = await request.send();
      if (response.statusCode == 200) {
        switch (responseType) {
          case ResponseType.json:
            return jsonDecode(await response.stream.bytesToString());
          case ResponseType.text:
            return await response.stream.bytesToString() as T;
          default:
            return await response.stream.bytesToString() as T;
        }
      } else {
        throw parseError(await response.stream.bytesToString());
      }
    } catch (error) {
      throw error.toString();
    }
  }

  static Future<T> getData<T>(String endpoint, {ResponseType? responseType = ResponseType.json, String? url}) async {
    try {
      final Uri uri = Uri.parse(url ?? '$apiUrl/$endpoint');
      final String? token = await CacheRepository.instance.get('token');

      final response = await http.get(uri, headers: {
        'token': token ?? '',
        'Content-Type': 'application/json; charset=utf-8',
      });
      if (response.statusCode == 200) {
        switch (responseType) {
          case ResponseType.json:
            return jsonDecode(response.body) as T;
          case ResponseType.text:
            return response.body as T;
          default:
            return response.body as T;
        }
      } else {
        throw parseError(response.body);
      }
    } catch (error) {
      throw error.toString();
    }
  }

  static Future<T> postData<T>(String endpoint, Map data, {ResponseType? responseType = ResponseType.json}) async {
    try {
      final Uri uri = Uri.parse('$apiUrl/$endpoint');
      final String? token = await CacheRepository.instance.get('token');

      final response = await http.post(uri, headers: {
        'token': token ?? '',
        'Content-Type': 'application/json; charset=utf-8',
      }, body: jsonEncode(data));

      pinfo(response.statusCode);

      if (response.statusCode == 200 || response.statusCode == 201) {
        switch (responseType) {
          case ResponseType.json:
            return jsonDecode(response.body);
          case ResponseType.text:
            return response.body as T;
          default:
            return response.body as T;
        }
      } else {
        throw parseError(response.body);
      }
    } catch (error) {
      perror(error);
      throw error.toString();
    }
  }

  static Future<Object> putData(String endpoint, Map data, {ResponseType? responseType = ResponseType.json}) async {
    try {
      final Uri uri = Uri.parse('$apiUrl/$endpoint');
      final String? token = await CacheRepository.instance.get('token');

      final response = await http.put(uri, headers: {
        'token': token ?? '',
        'Content-Type': 'application/json; charset=utf-8',
      }, body: jsonEncode(data));

      if (response.statusCode == 200 || response.statusCode == 201) {
        switch (responseType) {
          case ResponseType.json:
            return jsonDecode(response.body);
          case ResponseType.text:
            return response.body;
          default:
            return response.body;
        }
      } else {
        throw parseError(response.body);
      }
    } catch (error) {
      throw error.toString();
    }
  }

  static Future<Object> patchData(String endpoint, Map data, {ResponseType? responseType = ResponseType.json}) async {
    try {
      final Uri uri = Uri.parse('$apiUrl/$endpoint');
      final String? token = await CacheRepository.instance.get('token');

      final response = await http.patch(uri, headers: {
        'token': token ?? '',
        'Content-Type': 'application/json; charset=utf-8',
      }, body: jsonEncode(data));

      if (response.statusCode == 200 || response.statusCode == 201) {
        switch (responseType) {
          case ResponseType.json:
            return jsonDecode(response.body);
          case ResponseType.text:
            return response.body;
          default:
            return response.body;
        }
      } else {
        throw parseError(response.body);
      }
    } catch (error) {
      throw error.toString();
    }
  }

  static Future<Object> deleteData(String endpoint, {ResponseType? responseType = ResponseType.json}) async {
    try {
      final Uri uri = Uri.parse('$apiUrl/$endpoint');
      final String? token = await CacheRepository.instance.get('token');

      final response = await http.delete(uri, headers: {
        'token': token ?? '',
        'Content-Type': 'application/json; charset=utf-8',
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        switch (responseType) {
          case ResponseType.json:
            return jsonDecode(response.body);
          case ResponseType.text:
            return response.body;
          default:
            return response.body;
        }
      } else {
        throw parseError(response.body);
      }
    } catch (error) {
      throw error.toString();
    }
  }

  static String parseError(String encoded) {
    final json = jsonDecode(encoded);
    return json['error'];
  }
}
