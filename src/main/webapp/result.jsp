<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.text.SimpleDateFormat, java.util.Date, java.util.Locale, java.net.URL, com.google.gson.JsonArray, com.google.gson.JsonObject" %>

<html>
<head>
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

        /* 검색창 */
        .search-form input[type=text] {
            padding: 12px 15px;
            width: 60%;
            max-width: 400px;
            font-size: 1em;
            border-radius: 8px;
            border: 1px solid #ccc;
            margin-right: 10px;
            box-sizing: border-box;
        }

        .search-form button {
            display: inline-block;
            padding: 10px 20px;
            border-radius: 8px;
            background-color: #4CAF50;
            color: white;
            font-weight: bold;
            border: none;
            cursor: pointer;
            transition: background-color 0.3s, transform 0.2s;
        }

        .search-form button:hover {
            background-color: #45a049;
            transform: translateY(-2px);
        }

        /* 테이블 */
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

        td.title { width: 35%; font-weight: bold; }
        td.press { width: 20%; color: #555; }
        td.pubDate { width: 15%; color: #777; }
        td.description { width: 30%; max-height: 3.6em; overflow: hidden; line-height: 1.2em; }

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

        /* 페이지네이션 */
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

        @media (max-width: 600px) {
            td.description { max-width: 150px; }
            .search-form input[type=text] { width: 100%; margin-bottom: 10px; }
            .search-form button { width: 100%; }
        }
    </style>
</head>
<body>
<div class="container">

    <h2>뉴스 검색 결과</h2>

    <!-- 검색창 -->
    <form action="search" method="get" class="search-form">
        <input type="text" name="keyword" value="<%= request.getAttribute("keyword") %>" placeholder="검색어 입력" required />
        <button type="submit">검색</button>
    </form>

    <!-- 결과 테이블 -->
    <table>
        <tr>
            <th>제목</th>
            <th>언론사</th>
            <th>발행일</th>
            <th>내용 일부</th>
            <th>링크</th>
        </tr>
	<%
    // 요일 한글화 배열
    String[] weekdaysKR = {"일", "월", "화", "수", "목", "금", "토"};

    // 입력/출력 포맷
    SimpleDateFormat inputFormat = new SimpleDateFormat("EEE, dd MMM yyyy HH:mm:ss Z", Locale.ENGLISH);
    SimpleDateFormat dateFormat = new SimpleDateFormat("yyyy-MM-dd HH:mm", Locale.KOREAN);

    JsonArray items = (JsonArray) request.getAttribute("items");
    for (int i = 0; i < items.size(); i++) {
        JsonObject item = items.get(i).getAsJsonObject();
        
        String title = item.get("title").getAsString().replaceAll("<.*?>", "");
        String description = item.get("description").getAsString().replaceAll("<.*?>", "");

        // 언론사
        String originallink = item.get("originallink").getAsString();
        String press = "알 수 없음";
        try {
            URL url = new URL(originallink);
            String host = url.getHost();
            if(host.startsWith("www.")) host = host.substring(4);
            press = host;
        } catch(Exception e) {}

        // 발행일 한글화
        String pubDate = item.get("pubDate").getAsString();
        String pubDateKR = "";
        try {
            Date date = inputFormat.parse(pubDate);
            String weekday = weekdaysKR[date.getDay()]; // 요일 한글
            pubDateKR = dateFormat.format(date) + " (" + weekday + ")";
        } catch(Exception e) {
            pubDateKR = pubDate;
        }

        String link = originallink; 
        String shortDesc = description.length() > 60 ? description.substring(0, 60) + "..." : description;
	%>
	<tr>
	    <td class="title"><%= title %></td>
	    <td class="press"><%= press %></td>
	    <td class="pubDate"><%= pubDateKR %></td>
	    <td class="description"><%= shortDesc %></td>
	    <td><a href="<%= link %>" target="_blank" class="link-btn">바로가기</a></td>
	</tr>
	<%
	    }
	%>

    </table>

    <!-- 페이지네이션 -->
    <div class="pagination">
    <%
        int pageNumber = (Integer) request.getAttribute("page");
        int totalPages = (Integer) request.getAttribute("totalPages");
        String keyword = (String) request.getAttribute("keyword");

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
    %>
    </div>

</div>
</body>
</html>
