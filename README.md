# AI ShortsMaker

주제를 입력하면 Gemini API로 유튜브 쇼츠/인스타그램 릴스용 30초 대본을 생성해주는 Rails 8 앱입니다.

## 요구 사항

* Ruby 3.3.12 (`.ruby-version` 참고)
* Rails 8.1
* SQLite3

## 초기 설정

```bash
bundle install
cp .env.example .env   # 아래 환경 변수 값 채우기
bin/rails db:prepare
```

## 환경 변수 (`.env`)

| 변수 | 필수 | 설명 |
| --- | --- | --- |
| `GEMINI_API_KEY` | 필수 | [Google AI Studio](https://aistudio.google.com/)에서 발급받은 Gemini API 키. 없으면 대본 생성이 동작하지 않습니다. |
| `COUPANG_PARTNERS_LINK` | 선택 | 쿠팡 파트너스 제휴 링크. 비워두면 결과 화면에서 해당 섹션이 표시되지 않습니다. |
| `BUY_ME_A_COFFEE_LINK` | 선택 | 후원 링크. 비워두면 결과 화면에서 해당 섹션이 표시되지 않습니다. |

## 개발 서버 실행

```bash
bin/dev
```

`Procfile.dev`가 Rails 서버와 Tailwind watcher를 함께 실행합니다. http://localhost:3000 에서 확인합니다.

## 테스트

```bash
bin/rails test
```

## 배포 (Kamal)

`config/deploy.yml`의 `servers.web`을 실제 서버 IP로 바꾸고, `.kamal/secrets`가 참조하는 `GEMINI_API_KEY`를 배포 환경(예: 로컬 `.env` 또는 CI 시크릿)에 설정한 뒤 배포합니다.

```bash
bin/kamal setup   # 최초 1회
bin/kamal deploy
```

## 알려진 제약

* Gemini 호출은 요청 처리 중 동기로 실행됩니다(응답이 느리면 최대 30초까지 대기).
* IP 기준으로 10분에 5회로 요청 빈도를 제한합니다(`ScriptsController::RATE_LIMIT_*`).
