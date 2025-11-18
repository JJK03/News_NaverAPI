package naver_api;

import com.google.gson.*;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;
import java.io.IOException;
import java.util.logging.Logger;

@WebServlet("/search")
public class SearchServlet extends HttpServlet {

    private static final Logger LOG = Logger.getLogger(SearchServlet.class.getName());

    private final String clientId = "QWLLbGX2Hs7LUXpiV4Pf";
    private final String clientSecret = "S0q2lOqSwB";

    private static final int MAX_ITEMS = 100;
    private static final int PAGE_SIZE = 20;
    private static final int MAX_PAGES = 5;

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        String keyword = request.getParameter("keyword");
        int page = parsePageParam(request.getParameter("page"));

        if (keyword == null || keyword.trim().isEmpty()) {
            request.setAttribute("error", "검색어를 입력해주세요.");
            request.getRequestDispatcher("index.jsp").forward(request, response);
            return;
        }

        JsonArray items = null;
        try {
            String jsonResult = APISearchNews.searchBlog(keyword, clientId, clientSecret);
            if (jsonResult == null || jsonResult.trim().isEmpty()) {
                LOG.warning("APISearchNews returned empty result for keyword=" + keyword);
                request.setAttribute("error", "검색 결과를 가져오지 못했습니다.");
                request.getRequestDispatcher("index.jsp").forward(request, response);
                return;
            }

            JsonObject jsonObject = JsonParser.parseString(jsonResult).getAsJsonObject();
            JsonElement itemsEl = jsonObject.get("items");
            if (itemsEl != null && itemsEl.isJsonArray()) {
                items = itemsEl.getAsJsonArray();
            } else {
                items = new JsonArray();
            }

        } catch (JsonSyntaxException jse) {
            LOG.severe("JSON 파싱 오류: " + jse.getMessage());
            request.setAttribute("error", "검색 결과 파싱 중 오류가 발생했습니다.");
            request.getRequestDispatcher("index.jsp").forward(request, response);
            return;
        } catch (Exception e) {
            LOG.severe("검색 중 예외: " + e.getMessage());
            request.setAttribute("error", "검색 중 오류가 발생했습니다.");
            request.getRequestDispatcher("index.jsp").forward(request, response);
            return;
        }

        // 페이징 처리 한 페이지에 20개, 페이지 수는 5개, 총 100개
        JsonArray pagedItems = paginate(items, page, PAGE_SIZE, MAX_ITEMS);

        // 전체 저장용: 최대 100개
        JsonArray allItems = takeUpTo(items, MAX_ITEMS);
        String allItemsJson = allItems.toString();
        String allItemsJsonEncoded = NewsUtils.encodeJsonArray(allItems);

        int totalPages = Math.min((int) Math.ceil(Math.min(items.size(), MAX_ITEMS) / (double) PAGE_SIZE), MAX_PAGES);

        request.setAttribute("items", pagedItems);
        request.setAttribute("allItemsJson", allItemsJson);
        request.setAttribute("allItemsJsonEncoded", allItemsJsonEncoded);
        request.setAttribute("keyword", keyword);
        request.setAttribute("page", page);
        request.setAttribute("totalPages", totalPages);

        request.getRequestDispatcher("result.jsp").forward(request, response);
    }

    private int parsePageParam(String pageStr) {
        if (pageStr == null) return 1;
        try {
            int p = Integer.parseInt(pageStr);
            return Math.max(1, p);
        } catch (NumberFormatException e) {
            return 1;
        }
    }

    private JsonArray paginate(JsonArray items, int page, int pageSize, int maxItems) {
        JsonArray out = new JsonArray();
        if (items == null || items.size() == 0) return out;

        int start = (page - 1) * pageSize;
        int end = Math.min(start + pageSize, Math.min(items.size(), maxItems));

        for (int i = start; i < end; i++) {
            out.add(items.get(i));
        }
        return out;
    }

    private JsonArray takeUpTo(JsonArray items, int max) {
        JsonArray out = new JsonArray();
        if (items == null) return out;
        int limit = Math.min(items.size(), max);
        for (int i = 0; i < limit; i++) out.add(items.get(i));
        return out;
    }
}
