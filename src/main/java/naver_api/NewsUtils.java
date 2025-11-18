package naver_api;

import com.google.gson.Gson;
import com.google.gson.JsonArray;
import com.google.gson.JsonElement;
import com.google.gson.JsonParser;

import java.net.URL;
import java.net.URLEncoder;
import java.net.URLDecoder;
import java.nio.charset.StandardCharsets;
import java.time.ZonedDateTime;
import java.time.format.DateTimeFormatter;
import java.time.format.DateTimeParseException;
import java.util.Locale;

public final class NewsUtils {

    private static final Gson GSON = new Gson();

    // Input pattern example: "Tue, 18 Nov 2025 20:10:00 +0900"
    private static final DateTimeFormatter INPUT_FORMAT =
            DateTimeFormatter.ofPattern("EEE, dd MMM yyyy HH:mm:ss Z", Locale.ENGLISH);

    // Output example: "2025-11-18 20:10 (화)"
    private static final DateTimeFormatter OUTPUT_FORMAT =
            DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm", Locale.KOREAN);

    // 요일(일~토)
    private static final String[] WEEK_KR = {"일","월","화","수","목","금","토"};

    // JsonArray를 UTF-8로 URL-인코딩한 문자열 반환 (HTML hidden input에 안전하게 넣기 위해)
    public static String encodeJsonArray(JsonArray arr) {
        if (arr == null) return "";
        String raw = GSON.toJson(arr);
        try {
            return URLEncoder.encode(raw, StandardCharsets.UTF_8.toString());
        } catch (Exception e) {
            // 원본 문자열 반환 (인코딩 실패)
            return raw;
        }
    }

    // 인코딩된 JSON 문자열을 디코드하여 JsonArray로 반환
    public static JsonArray decodeJsonArray(String encoded) {
        if (encoded == null || encoded.trim().isEmpty()) return new JsonArray();
        String decoded;
        try {
            decoded = URLDecoder.decode(encoded, StandardCharsets.UTF_8.toString());
        } catch (Exception e) {
            decoded = encoded; // 이미 디코드되어 왔거나 디코드 실패 시 원본 사용
        }
        JsonElement el;
        try {
            el = JsonParser.parseString(decoded);
        } catch (Exception ex) {
            return new JsonArray();
        }
        if (el.isJsonArray()) return el.getAsJsonArray();
        return new JsonArray();
    }

    /*
      원본링크에서 언론사/도메인 이름을 안전하게 추출
      ex) "https://news.example.co.kr/..." -> "example"
      실패하면 "알 수 없음" 반환
    */
    public static String extractPress(String originallink) {
        if (originallink == null || originallink.isEmpty()) return "알 수 없음";
        try {
            URL url = new URL(originallink);
            String host = url.getHost().toLowerCase();
            if (host.startsWith("www.")) host = host.substring(4);

            // .co.kr, .com, .net 같은 TLD 패턴 제거
            String press = host.replaceAll("\\.(co\\.)?([a-z]{2,3})(?:\\.[a-z]{2})?$", "");
            // 만약 서브도메인(abc.news.example) 등으로 남아 있으면 마지막 토큰 사용
            int lastDot = press.lastIndexOf('.');
            if (lastDot != -1) press = press.substring(lastDot + 1);

            if (press == null || press.trim().isEmpty()) return "알 수 없음";
            return press;
        } catch (Exception e) {
            return "알 수 없음";
        }
    }

    /*
      pubDate 문자열을 "yyyy-MM-dd HH:mm (요일)" 포맷으로 반환
      파싱 실패 시 원본 문자열 반환
    */
    public static String formatPubDateWithWeek(String pubDate) {
        if (pubDate == null || pubDate.isEmpty()) return "";
        try {
            ZonedDateTime zdt = ZonedDateTime.parse(pubDate, INPUT_FORMAT);
            int dowIndex = zdt.getDayOfWeek().getValue() % 7; // MON(1)->index1, SUN(7)->index0
            String weekday = WEEK_KR[dowIndex];
            return OUTPUT_FORMAT.format(zdt) + " (" + weekday + ")";
        } catch (DateTimeParseException e) {
            // 포맷이 예상과 다르면 원본 반환
            return pubDate;
        } catch (Exception e) {
            return pubDate;
        }
    }

    /*
      pubDate 문자열을 java.sql.Timestamp로 변환 (DB insert용)
      실패시 null 반환
    */
    public static java.sql.Timestamp parsePubDateToTimestamp(String pubDate) {
        if (pubDate == null || pubDate.isEmpty()) return null;
        try {
            ZonedDateTime zdt = ZonedDateTime.parse(pubDate, INPUT_FORMAT);
            java.time.Instant instant = zdt.toInstant();
            return java.sql.Timestamp.from(instant);
        } catch (Exception e) {
            return null;
        }
    }

    /*
      JsonArray에서 최대 maxCnt개를 골라 새 JsonArray 반환
    */
    public static JsonArray takeUpTo(JsonArray items, int maxCnt) {
        JsonArray out = new JsonArray();
        if (items == null) return out;
        int limit = Math.min(items.size(), maxCnt);
        for (int i = 0; i < limit; i++) out.add(items.get(i));
        return out;
    }
}