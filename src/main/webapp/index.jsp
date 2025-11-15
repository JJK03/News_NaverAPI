<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<html>
<head>
    <title>뉴스 검색</title>
    <style>
        html, body {
            height: 100%;
            margin: 0;
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background-color: #f7f9fc;
            display: flex;
            justify-content: center;
            align-items: flex-start; /* 위쪽으로 정렬 */
        }

        .container {
            background-color: #fff;
            padding: 40px 60px;
            border-radius: 15px;
            box-shadow: 0 8px 16px rgba(0,0,0,0.15);
            text-align: center;
            width: 500px;
            max-width: 90%;
            margin-top: 15%; /* 화면 위에서 1/4 정도 위치 */
        }

        h2 {
            margin-bottom: 30px;
            color: #333;
        }

        input[type=text] {
            padding: 15px 20px;
            width: 80%;
            font-size: 1.2em;
            border-radius: 10px;
            border: 1px solid #ccc;
            margin-bottom: 20px;
            box-sizing: border-box;
        }

        button {
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

        button:hover {
            background-color: #45a049;
            transform: translateY(-2px);
        }

        @media (max-width: 600px) {
            input[type=text] { width: 100%; }
            .container { padding: 30px 20px; }
        }
    </style>
</head>
<body>
<div class="container">
    <h2>네이버 블로그 뉴스 검색</h2>
    <form action="search" method="get">
        <input type="text" name="keyword" placeholder="검색어를 입력하세요" required /><br>
        <button type="submit">검색</button>
    </form>
</div>
</body>
</html>
