part of '../core_http.dart';

extension _CoreHttpOperations on CoreHttp {
  _sendRequest(
    String url, {
    required HttpTypes type,
    required data,
    accessToken,
  }) async {
    Response? response;

    url = ApiUrlConstants.base + url;

    try {
      switch (type) {
        case HttpTypes.GET:
          response =
              await Client().get(Uri.parse(url), headers: <String, String>{
            HttpHeaders.authorizationHeader: accessToken,
          });
          break;
        case HttpTypes.POST:
          response = await Client().post(Uri.parse(url),
              headers: <String, String>{
                'Content-Type': 'application/json; charset=utf-8',
              },
              body: jsonEncode(data));
          break;
        default:
          response = null;
      }

      return response;
    } on SocketException {
      BaseHttp? baseHttp = _responseParser<BaseHttp, BaseHttp>(
          BaseHttp(), {"message": "No Internet connection"});
      throw FetchDataException(baseHttp);
    }
  }

  R? _returnResponse<R, T extends BaseModel>(Response response,
      {required T parseModel}) {
    final jsonDecoded = json.decode(utf8.decode(response.bodyBytes));

    if (response.statusCode == 200) {
      return _responseParser<R, T>(parseModel, jsonDecoded);
    } else {
      BaseHttp? baseHttp =
          _responseParser<BaseHttp, T>(BaseHttp(), jsonDecoded);

      switch (response.statusCode) {
        case 400:
          throw BadRequestException(baseHttp);
        case 401:
          throw InvalidInputException(baseHttp);
        case 403:
          throw UnauthorisedException(baseHttp);
        case 500:
          throw ServerException(baseHttp);
        default:
          throw FetchDataException(baseHttp);
      }
    }
  }

  R? _responseParser<R, T>(BaseModel model, dynamic data) {
    if (data is List) {
      return data.map((e) => model.fromJson(e)).toList().cast<T>() as R;
    } else if (data is Map) {
      return model.fromJson(data as Map<String, dynamic>) as R;
    }

    return data as R?;
  }
}
