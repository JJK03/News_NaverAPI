# News_NaverAPI

## 조원
- 202245060 장진규 (조장)
- 202245051 김인성
- 202345063 조희준

## 설명
- NaverAPI Open Sauce 기반으로 작성되었으며,
- 사용자가 키워드를 입력하면 해당 키워드와 관련된 뉴스기사를 한 페이지당 20건씩, 총 5페이지로 100건을 나타냅니다.
- 검색 결과 저장버튼을 누르면 100건의 뉴스기사는 DB에 저장됩니다.

## DB구조
```sql
CREATE TABLE IF NOT EXISTS news_results (
    id INT AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    link VARCHAR(700) NOT NULL UNIQUE,
    press VARCHAR(100),
    pub_date DATETIME,
    saved_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```
- DB저장용 일련번호 id
- 기사 제목
- 기사 내용
- 기사 링크
- 언론사
- 기사 발행일
- DB에 저장된 시각