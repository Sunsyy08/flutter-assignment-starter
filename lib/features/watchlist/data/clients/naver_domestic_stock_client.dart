// ignore_for_file: unused_element, unused_field

import 'dart:convert';

import 'package:dio/dio.dart';

import '../dtos/naver_stock_dtos.dart';

abstract interface class NaverStockDataClient {
  Future<List<NaverAutocompleteItemDto>> searchStocks(String query);

  Future<Map<String, NaverRealtimeQuoteDto>> fetchRealtimeQuotes(
      Iterable<String> symbols,
      );

  Future<NaverChartMetadataDto> fetchChartMetadata(String symbol);

  Future<NaverDailyHistoryPageDto> fetchDailyHistoryPage({
    required String symbol,
    required int page,
  });
}

class NaverDomesticStockClient implements NaverStockDataClient {
  const NaverDomesticStockClient(this._dio);

  final Dio _dio;

  static const Map<String, String> _defaultHeaders = {
    'accept': 'application/json, text/plain, */*',
    'referer': 'https://m.stock.naver.com/',
    'accept-language': 'ko-KR,ko;q=0.9,en-US;q=0.8,en;q=0.7',
    'user-agent':
    'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) '
        'AppleWebKit/537.36 (KHTML, like Gecko) '
        'Chrome/123.0.0.0 Safari/537.36',
  };

  static Map<String, dynamic> _decodeJsonObjectBody(
      Object? data,
      String contextLabel,
      ) {
    if (data == null) {
      throw FormatException('$contextLabel response body is empty');
    }

    if (data is Map<String, dynamic>) {
      return data;
    }

    if (data is String) {
      final decoded = jsonDecode(data);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      throw FormatException('$contextLabel response is not a JSON object');
    }

    if (data is List<int>) {
      final decoded = jsonDecode(utf8.decode(data));
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      throw FormatException('$contextLabel response is not a JSON object');
    }

    if (data is Map) {
      return data.map((key, value) => MapEntry(key.toString(), value));
    }

    throw FormatException('$contextLabel response body has unsupported shape');
  }

  static Map<String, dynamic> _asStringKeyedMap(
      Object? value,
      String contextLabel,
      ) {
    if (value is Map<String, dynamic>) {
      return value;
    }

    if (value is Map) {
      return value.map((key, value) => MapEntry(key.toString(), value));
    }

    throw FormatException('$contextLabel is not a JSON object');
  }

  @override
  Future<List<NaverAutocompleteItemDto>> searchStocks(String query) async {
    // TODO(assignment): Implement the Naver autocomplete request.
    //
    // 네이버 자동완성 API 호출
    // ResponseType.plain: 응답이 String으로 올 수 있어서 plain으로 받음
    // items 배열에서 각 항목을 NaverAutocompleteItemDto.fromJson으로 변환
    final response = await _dio.get<Object>(
      'https://ac.stock.naver.com/ac',
      queryParameters: {
        'q': query,
        'target': 'stock,ipo,index,marketindicator',
      },
      options: Options(
        headers: _defaultHeaders,
        responseType: ResponseType.plain,
      ),
    );

    final body = _decodeJsonObjectBody(response.data, 'searchStocks');
    final items = body['items'] as List;
    return items
        .map((e) => NaverAutocompleteItemDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<Map<String, NaverRealtimeQuoteDto>> fetchRealtimeQuotes(
      Iterable<String> symbols,
      ) async {
    // TODO(assignment): Implement the Naver realtime quote request.
    //
    // 중복 심볼 제거 후 빈 경우 빈 map 반환
    // SERVICE_ITEM:005930,000660 형태로 query 파라미터 구성
    // result -> areas -> datas 경로로 데이터 추출
    final unique = symbols.toSet().toList();
    if (unique.isEmpty) return {};

    final query = 'SERVICE_ITEM:${unique.join(',')}';

    final response = await _dio.get<Object>(
      'https://polling.finance.naver.com/api/realtime',
      queryParameters: {'query': query},
      options: Options(
        headers: _defaultHeaders,
        responseType: ResponseType.plain,
      ),
    );

    final body = _decodeJsonObjectBody(response.data, 'fetchRealtimeQuotes');
    final result = _asStringKeyedMap(body['result'], 'result');
    final areas = result['areas'] as List;

    final map = <String, NaverRealtimeQuoteDto>{};
    for (final area in areas) {
      final datas = (area as Map)['datas'] as List;
      for (final data in datas) {
        final dto = NaverRealtimeQuoteDto.fromJson(
          data as Map<String, dynamic>,
        );
        // 6자리 국내 심볼 기준으로 map에 저장
        map[dto.symbol] = dto;
      }
    }
    return map;
  }

  @override
  Future<NaverChartMetadataDto> fetchChartMetadata(String symbol) async {
    // TODO(assignment): Implement the chart metadata request.
    //
    // 종목 메타데이터 API 호출 (종목명, 거래소명 등)
    final response = await _dio.get<Object>(
      'https://stock.naver.com/api/securityFe/api/fchart/domestic/stock/$symbol',
      options: Options(
        headers: _defaultHeaders,
        responseType: ResponseType.plain,
      ),
    );

    final body = _decodeJsonObjectBody(response.data, 'fetchChartMetadata');
    return NaverChartMetadataDto.fromJson(body);
  }

  @override
  Future<NaverDailyHistoryPageDto> fetchDailyHistoryPage({
    required String symbol,
    required int page,
  }) async {
    // TODO(assignment): Implement parsing for the legacy daily history page.
    //
    // 네이버 일별 시세는 JSON이 아니라 HTML로 반환됨
    // ResponseType.bytes + latin1 디코딩으로 한글 깨짐 방지
    // HTML 테이블에서 날짜/종가/시가/고가/저가/거래량 파싱
    // 테이블 숫자 순서: 종가, 전일비, 시가, 고가, 저가, 거래량
    if (page < 1) throw ArgumentError('page must be >= 1');

    final response = await _dio.get<Object>(
      'https://finance.naver.com/item/sise_day.naver',
      queryParameters: {'code': symbol, 'page': page},
      options: Options(
        headers: {
          ..._defaultHeaders,
          'accept': 'text/html',
        },
        responseType: ResponseType.bytes,
      ),
    );

    // latin1로 디코딩해야 한글이 깨지지 않음
    final html = latin1.decode(response.data as List<int>);

    // 날짜 행 파싱: td에서 날짜 패턴 추출
    final rowRegex = RegExp(
      r'<tr[^>]*>\s*<td[^>]*>\s*<span[^>]*>(\d{4}\.\d{2}\.\d{2})</span>.*?'
      r'<td[^>]*><span[^>]*>([\d,]+)</span>.*?'  // 종가
      r'<td[^>]*>.*?</td>.*?'                     // 전일비 (스킵)
      r'<td[^>]*><span[^>]*>([\d,]+)</span>.*?'  // 시가
      r'<td[^>]*><span[^>]*>([\d,]+)</span>.*?'  // 고가
      r'<td[^>]*><span[^>]*>([\d,]+)</span>.*?'  // 저가
      r'<td[^>]*><span[^>]*>([\d,]+)</span>',    // 거래량
      dotAll: true,
    );

    final priceInfos = <NaverHistoricalPriceDto>[];
    for (final match in rowRegex.allMatches(html)) {
      // 날짜 형식 변환: 2026.03.27 → 20260327
      final dateStr = match.group(1)!.replaceAll('.', '');
      priceInfos.add(
        NaverHistoricalPriceDto.fromJson({
          'localDate': dateStr,
          'closePrice': _parseDouble(match.group(2)!),
          'openPrice': _parseDouble(match.group(3)!),
          'highPrice': _parseDouble(match.group(4)!),
          'lowPrice': _parseDouble(match.group(5)!),
          'accumulatedTradingVolume': _parseInt(match.group(6)!),
        }),
      );
    }

    // lastPage 추출: 페이지네이션 영역에서 마지막 페이지 번호 파싱
    final lastPageRegex = RegExp(r'pgRR[^>]*page=(\d+)');
    final lastPageMatch = lastPageRegex.firstMatch(html);
    final lastPage = lastPageMatch != null
        ? int.parse(lastPageMatch.group(1)!)
        : page;

    return NaverDailyHistoryPageDto(
      symbol: symbol,
      page: page,
      lastPage: lastPage,
      priceInfos: priceInfos,
    );
  }
}

double _parseDouble(String value) {
  return double.parse(value.replaceAll(',', ''));
}

int _parseInt(String value) {
  return int.parse(value.replaceAll(',', ''));
}

Map<String, String> naverDesktopLikeHeaders() =>
    Map<String, String>.unmodifiable(NaverDomesticStockClient._defaultHeaders);