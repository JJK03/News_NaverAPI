<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.sql.*, com.google.gson.*, java.util.Date, java.text.SimpleDateFormat, java.util.Locale, java.net.URL, java.net.URLDecoder" %>
<%
    request.setCharacterEncoding("UTF-8");

    String originalKeyword = request.getParameter("keyword");
    String originalPage = request.getParameter("page");
    String encodedKeyword = originalKeyword;
    if (originalKeyword != null) {
        try {
            encodedKeyword = java.net.URLEncoder.encode(originalKeyword, "UTF-8");
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    final String DB_URL = "jdbc:mysql://localhost:3306/news_db";
    final String DB_USER = "root";
    final String DB_PASSWORD = "Wkdwlsrb1!";
    final String TABLE_NAME = "news_results";

    String itemsJsonEncoded = request.getParameter("items_json");

    if (itemsJsonEncoded == null || itemsJsonEncoded.trim().isEmpty()) {
        session.setAttribute("saveMessage", "저장할 검색 결과가 없습니다. (items_json 파라미터 누락)");
        response.sendRedirect("search?keyword=" + encodedKeyword + "&page=" + originalPage);
        return;
    }

    String itemsJson = null;
    try {
        // 디코드
        itemsJson = URLDecoder.decode(itemsJsonEncoded, "UTF-8");
    } catch (Exception e) {
        // 디코드 실패시 원본 사용
        itemsJson = itemsJsonEncoded;
    }

    if (itemsJson == null || itemsJson.trim().isEmpty() || "[]".equals(itemsJson.trim())) {
        session.setAttribute("saveMessage", "저장할 검색 결과가 없습니다. (items_json 비어있음)");
        response.sendRedirect("search?keyword=" + encodedKeyword + "&page=" + originalPage);
        return;
    }

    JsonArray items;
    try {
        items = JsonParser.parseString(itemsJson).getAsJsonArray();
    } catch (JsonParseException e) {
        session.setAttribute("saveMessage", "데이터 파싱 오류: 유효하지 않은 JSON 형식입니다. 에러: " + e.getMessage());
        e.printStackTrace();
        response.sendRedirect("search?keyword=" + encodedKeyword + "&page=" + originalPage);
        return;
    }

    Connection conn = null;
    PreparedStatement pstmt = null;
    Statement stmt = null;
    int successCount = 0;

    try {
        Class.forName("com.mysql.cj.jdbc.Driver");
        conn = DriverManager.getConnection(DB_URL, DB_USER, DB_PASSWORD); // 위에 적혀있음

        String createTableSQL = "CREATE TABLE IF NOT EXISTS " + TABLE_NAME + " ("
                + "id INT AUTO_INCREMENT PRIMARY KEY, "
                + "title VARCHAR(255) NOT NULL, "
                + "description TEXT, "
                + "link VARCHAR(2000) NOT NULL UNIQUE, "
                + "press VARCHAR(100), "
                + "pub_date DATETIME, "
                + "saved_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP"
                + ")";
        stmt = conn.createStatement();
        stmt.executeUpdate(createTableSQL);

        String sql = "INSERT INTO " + TABLE_NAME + " (title, description, link, press, pub_date) "
                + "VALUES (?, ?, ?, ?, ?) ON DUPLICATE KEY UPDATE title=VALUES(title), description=VALUES(description)";
        pstmt = conn.prepareStatement(sql);

        SimpleDateFormat inputFormat = new SimpleDateFormat("EEE, dd MMM yyyy HH:mm:ss Z", Locale.ENGLISH);

        /* 
          배치 처리
          DB에 여러 개의 INSERT문을 한꺼번에 모아서 처리하는 것
          addBatch()로 SQL문을 모아두고
          executeBatch()로 모아둔 SQL문을 한꺼번에 실행한 후
          clearBatch()로 배치를 초기화한다
        */
        final int BATCH_SIZE = 50;
        int batchCount = 0;

        for (int i = 0; i < items.size(); i++) {
            JsonObject item = items.get(i).getAsJsonObject();

            // HTML 태그 제거
            String title = item.has("title") ? item.get("title").getAsString().replaceAll("<.*?>", "") : "";
            String description = item.has("description") ? item.get("description").getAsString().replaceAll("<.*?>", "") : "";
            String originallink = item.has("originallink") ? item.get("originallink").getAsString() : "";
            String pubDate = item.has("pubDate") ? item.get("pubDate").getAsString() : null;

            // 언론사 추출 로직
            String press = "알 수 없음";
            try {
                if (originallink != null && !originallink.isEmpty()) {
                    URL url = new URL(originallink);
                    String host = url.getHost().toLowerCase();
                    if (host.startsWith("www.")) host = host.substring(4);
                    press = host.replaceAll("\\.[a-z]{2,3}(?:\\.[a-z]{2})?$", "");
                    int lastDotIndex = press.lastIndexOf('.');
                    if (lastDotIndex != -1) {
                        press = press.substring(lastDotIndex + 1);
                    }
                    if (press.isEmpty()) press = "알수 없음";
                }
            } catch (Exception e) {
                press = "알수 없음";
            }

            // 날짜 형식 변환 (java.sql.Timestamp로 안전하게 처리)
            java.sql.Timestamp pubTimestamp = null;
            if (pubDate != null && !pubDate.isEmpty()) {
                try {
                    Date parsed = inputFormat.parse(pubDate);
                    pubTimestamp = new java.sql.Timestamp(parsed.getTime());
                } catch (Exception e) {
                    pubTimestamp = null;
                }
            }

            pstmt.setString(1, title);
            pstmt.setString(2, description);
            pstmt.setString(3, originallink);
            pstmt.setString(4, press);
            if (pubTimestamp != null) {
                pstmt.setTimestamp(5, pubTimestamp);
            } else {
                pstmt.setNull(5, Types.TIMESTAMP);
            }

            pstmt.addBatch();
            batchCount++;

            // 배치 사이즈마다 실행
            if (batchCount % BATCH_SIZE == 0) {
                int[] results = pstmt.executeBatch();
                for (int res : results) {
                    if (res > 0 || res == Statement.SUCCESS_NO_INFO) successCount++;
                }
                pstmt.clearBatch();
            }
        }

        // 남은 배치 실행
        int[] remaining = pstmt.executeBatch();
        for (int res : remaining) {
            if (res > 0 || res == Statement.SUCCESS_NO_INFO) successCount++;
        }

        session.setAttribute("saveMessage", successCount + "개의 뉴스가 데이터베이스에 저장되었습니다.");

    } catch (SQLException e) {
        session.setAttribute("saveMessage", "DB 저장 오류 : " + e.getMessage());
        e.printStackTrace();
    } catch (ClassNotFoundException e) {
        session.setAttribute("saveMessage", "DB 드라이버 오류 - JDBC 드라이버 파일을 확인하세요.");
        e.printStackTrace();
    } finally {
        if (pstmt != null) try { pstmt.close(); } catch (SQLException e) {}
        if (stmt != null) try { stmt.close(); } catch (SQLException e) {}
        if (conn != null) try { conn.close(); } catch (SQLException e) {}
    }

    response.sendRedirect("search?keyword=" + encodedKeyword + "&page=" + originalPage);
%>
