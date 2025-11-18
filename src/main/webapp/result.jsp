<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.text.SimpleDateFormat, java.util.Date, java.util.Locale, java.util.Calendar, java.net.URL, java.net.URLEncoder, com.google.gson.JsonArray, com.google.gson.JsonObject, com.google.gson.Gson" %>
<%@ page import="naver_api.NewsUtils" %>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8" />
    <title>뉴스 검색 결과</title>
    <style>
        html, body {
            height: 100%;
            margin: 0;
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background-color: #f7f9fc;
            display: flex;
            justify-content: center;
            align-items: flex-start;
        }

        .container {
            width: 90%;
            max-width: 1000px;
            margin-top: 10%;
            text-align: center;
        }

        h2 {
            color: #333;
        }

        /* 검색/저장 폼 영역 */
        .action-area {
            display: flex;
            justify-content: center;
            align-items: center;
            margin-bottom: 20px;
        }

        .search-form {
            display: flex;
            flex-grow: 1;
            max-width: 600px;
        }

        .search-form input[type=text] {
            padding: 12px 15px;
            width: 70%;
            font-size: 1em;
            border-radius: 8px;
            border: 1px solid #ccc;
            margin-right: 10px;
            box-sizing: border-box;
        }

        .search-form button,
        .save-form button {
            display: inline-block;
            width: 50%;
            max-width: 300px;
            padding: 15px 0;
            font-size: 1.2em;
            font-weight: bold;
            border: none;
            border-radius: 10px;
            background-color: #4CAF50;
            color: white;
            cursor: pointer;
            transition: background-color 0.3s, transform 0.2s;
        }

        .search-form button {
            width: 30%;
        }

        .search-form button:hover,
        .save-form button:hover {
            background-color: #45a049;
            transform: translateY(-2px);
        }
        
        table {
            border-collapse: collapse;
            width: 100%;
            box-shadow: 0 4px 12px rgba(0,0,0,0.1);
            background-color: #fff;
            margin-top: 20px;
            table-layout: fixed;
        }

        th, td {
            padding: 12px 15px;
            text-align: left;
            vertical-align: top;
            word-wrap: break-word;
        }

        th {
            background-color: #4CAF50;
            color: white;
        }

        tr:nth-child(even) {
            background-color: #f2f2f2;
        }

        tr:hover {
            background-color: #e6f7ff;
        }

        td.title { width: 30%; font-weight: bold; }
        td.press { width: 15%; color: #555; }
        td.pubDate { width: 15%; color: #777; }
        td.description { width: 30%; max-height: 3.6em; overflow: hidden; line-height: 1.2em; }
        td.link { width: 10%; }

        a.link-btn {
            display: inline-block;
            white-space: nowrap;
            padding: 6px 12px;
            border-radius: 5px;
            background-color: #007BFF;
            color: #fff;
            text-decoration: none;
            font-weight: bold;
            transition: background-color 0.3s, transform 0.2s;
        }

        a.link-btn:hover {
            background-color: #0056b3;
            transform: translateY(-2px);
        }

        /* 여러 페이지로 나누기 */
        .pagination {
            margin-top: 30px;
            margin-bottom: 50px; /* 화면 아래 여백 충분히 */
            text-align: center;
        }

        .pagination a {
            text-decoration: none;
            padding: 8px 12px;
            margin: 0 4px;
            background-color: #4CAF50;
            color: white;
            border-radius: 5px;
        }

        .pagination a.current {
            background-color: #007BFF;
        }

        @media (max-width: 800px) {
            td.description { max-width: 150px; }
            .action-area { flex-direction: column; }
            .search-form { width: 100%; max-width: none; margin-bottom: 15px; }
            .search-form input[type=text] { width: 65%; }
            .search-form button { width: 35%; }
            .save-form { width: 100%; }
        }
    </style>
</head>
<body>
<div class="container">

    <h2>뉴스 검색 결과</h2>

    <%
        // 화면에 보여줄 items (페이징된 것)
        JsonArray items = (JsonArray) request.getAttribute("items");

        // 전체 저장용 JSON (서블릿에서 인코딩된 값 우선 사용)
        String encodedAllItems = "";
        String allItemsJsonEncoded = (String) request.getAttribute("allItemsJsonEncoded");
        if (allItemsJsonEncoded != null && !allItemsJsonEncoded.isEmpty()) {
            encodedAllItems = allItemsJsonEncoded;
        } else {
            // 서블릿에서 raw allItemsJson을 줬을 수도 있으니 안전하게 처리
            Object allItemsObj = request.getAttribute("allItemsJson");
            if (allItemsObj != null) {
                try {
                    if (allItemsObj instanceof JsonArray) {
                        encodedAllItems = NewsUtils.encodeJsonArray((JsonArray) allItemsObj);
                    } else {
                        // 문자열로 넘어온 경우도 처리
                        String raw = allItemsObj.toString();
                        try {
                            JsonArray parsed = new Gson().fromJson(raw, JsonArray.class);
                            encodedAllItems = NewsUtils.encodeJsonArray(parsed);
                        } catch (Exception ex) {
                            // fallback: items 기반으로 인코딩
                            encodedAllItems = NewsUtils.encodeJsonArray(NewsUtils.takeUpTo(items, 100));
                        }
                    }
                } catch (Exception e) {
                    encodedAllItems = NewsUtils.encodeJsonArray(NewsUtils.takeUpTo(items, 100));
                }
            } else {
                // fallback: items에서 최대 100개 추출 후 인코딩
                encodedAllItems = NewsUtils.encodeJsonArray(NewsUtils.takeUpTo(items, 100));
            }
        }

        // 검색어 가져오기
        String keyword = (String) request.getAttribute("keyword");
        if (keyword == null) {
            keyword = "";
        }

        // 페이지 번호 가져오기
        Integer pageObj = (Integer) request.getAttribute("page");
        int currentPage = (pageObj != null) ? pageObj.intValue() : 1;
    %>

    <div class="action-area">
        <form action="search" method="get" class="search-form">
            <input type="text" name="keyword" value="<%= keyword %>" placeholder="검색어 입력" required />
            <button type="submit">검색</button>
        </form>

        <form action="save.jsp" method="post" class="save-form" style="margin-left: 10px;">
            <!-- 인코딩된 JSON만 전송 (절대 화면에 노출하지 않음) -->
            <input type="hidden" name="items_json" value="<%= encodedAllItems %>" />
            
            <!-- 검색어와 페이지 정보를 save.jsp로 전송 -->
            <input type="hidden" name="keyword" value="<%=keyword%>" />
            <input type="hidden" name="page" value="<%=currentPage%>" />
            
            <button type="submit" style="width: 150px;">검색 결과 저장</button>
        </form>
    </div>

    <table>
        <tr>
            <th>제목</th>
            <th>언론사</th>
            <th>발행일</th>
            <th>내용 일부</th>
            <th class="link">링크</th>
        </tr>
	<%
    if (items != null && items.size() > 0) {

        for (int i = 0; i < items.size(); i++) {
            JsonObject item = items.get(i).getAsJsonObject();

            String title = item.has("title") ? item.get("title").getAsString().replaceAll("<.*?>", "") : "";
            String description = item.has("description") ? item.get("description").getAsString().replaceAll("<.*?>", "") : "";
            String originallink = item.has("originallink") ? item.get("originallink").getAsString() : "";

            // NewsUtils.java로 보내기
            String press = NewsUtils.extractPress(originallink);
            String pubDateKR = item.has("pubDate") ? NewsUtils.formatPubDateWithWeek(item.get("pubDate").getAsString()) : "";

            String link = originallink;
            String shortDesc = description.length() > 60 ? description.substring(0, 60) + "..." : description;
	%>
	<tr>
	    <td class="title"><%= title %></td>
	    <td class="press"><%= press %></td>
	    <td class="pubDate"><%= pubDateKR %></td>
	    <td class="description"><%= shortDesc %></td>
	    <td class="link"><a href="<%= link %>" target="_blank" class="link-btn">바로가기</a></td>
	</tr>
	<%
	    }
    } else {
	%>
        <tr>
            <td colspan="5" style="text-align: center; padding: 20px;">검색 결과가 없거나 오류가 발생했습니다.</td>
        </tr>
	<%
    }
	%>

    </table>

    <div class="pagination">
    <%
        Integer totalPagesObj = (Integer) request.getAttribute("totalPages");
        
        int pageNumber = currentPage; // 위에 정의된 currentPage 사용
        int totalPages = (totalPagesObj != null) ? totalPagesObj.intValue() : 1;
       
        if (totalPages > 1) {
            for(int p=1; p<=totalPages; p++) {
                if(p == pageNumber) {
    %>
            <a href="search?keyword=<%=keyword%>&page=<%=p%>" class="current"><%=p%></a>
    <%
                } else {
    %>
            <a href="search?keyword=<%=keyword%>&page=<%=p%>"><%=p%></a>
    <%
                }
            }
        }
    %>
    </div>
    
    <!-- 저장 성공/실패 메시지 표시  -->
    <%
        String saveMessage = (String) session.getAttribute("saveMessage");
        if (saveMessage != null) {
            session.removeAttribute("saveMessage"); 
    %>
    <script>
        alert('<%= saveMessage.replace("'", "\\'") %>');
    </script>
    <%
        }
    %>

</div>
</body>
</html>
