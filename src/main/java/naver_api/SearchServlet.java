package naver_api;

import com.google.gson.*;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;
import java.io.IOException;

@WebServlet("/search")
public class SearchServlet extends HttpServlet {

	private final String clientId = "QWLLbGX2Hs7LUXpiV4Pf";
	private final String clientSecret = "S0q2lOqSwB";

	@Override
	protected void doGet(HttpServletRequest request, HttpServletResponse response)
			throws ServletException, IOException {
		String keyword = request.getParameter("keyword");
		String pageStr = request.getParameter("page");
		int page = 1;
		if (pageStr != null) {
			try {
				page = Integer.parseInt(pageStr);
			} catch (Exception e) {
				page = 1;
			}
		}

		if (keyword == null || keyword.trim().isEmpty()) {
			request.setAttribute("error", "검색어를 입력해주세요.");
			request.getRequestDispatcher("index.jsp").forward(request, response);
			return;
		}

		// 검색 결과 JSON 가져오기
		String jsonResult = APISearchNews.searchBlog(keyword, clientId, clientSecret);
		JsonObject jsonObject = JsonParser.parseString(jsonResult).getAsJsonObject();
		JsonArray items = jsonObject.getAsJsonArray("items");

		// 최대 100건까지만
		JsonArray pagedItems = new JsonArray();
		int start = (page - 1) * 20;
		int end = Math.min(start + 20, items.size());
		for (int i = start; i < end && i < 100; i++) {
			pagedItems.add(items.get(i));
		}

		int totalPages = Math.min((int) Math.ceil(Math.min(items.size(), 100) / 20.0), 5);

		request.setAttribute("items", pagedItems);
		request.setAttribute("keyword", keyword);
		request.setAttribute("page", page);
		request.setAttribute("totalPages", totalPages);

		request.getRequestDispatcher("result.jsp").forward(request, response);
	}
}
