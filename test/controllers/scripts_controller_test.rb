require "test_helper"

class ScriptsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @original_cache = Rails.cache
    Rails.cache = ActiveSupport::Cache::MemoryStore.new

    @original_api_key = ENV["GEMINI_API_KEY"]
    ENV["GEMINI_API_KEY"] = "test_api_key"
  end

  teardown do
    Rails.cache = @original_cache
    ENV["GEMINI_API_KEY"] = @original_api_key
  end

  test "index renders the form" do
    get "/"
    assert_response :success
    assert_select "form"
  end

  test "blank topic shows an error" do
    post "/scripts/generate", params: { topic: "" }
    assert_response :success
    assert_select '[data-testid="error-message"]', text: "주제를 입력해주세요."
  end

  test "missing api key shows a setup error" do
    ENV["GEMINI_API_KEY"] = nil
    post "/scripts/generate", params: { topic: "고양이" }
    assert_response :success
    assert_select '[data-testid="error-message"]', /API 키가 설정되지 않았습니다/
  end

  test "topic longer than the limit is rejected" do
    post "/scripts/generate", params: { topic: "a" * (ScriptsController::MAX_TOPIC_LENGTH + 1) }
    assert_response :success
    assert_select '[data-testid="error-message"]', /이내로 입력해주세요/
  end

  test "successful response renders the generated script" do
    fake_response = Net::HTTPOK.new("1.1", "200", "OK")
    fake_response.define_singleton_method(:body) do
      { candidates: [ { content: { parts: [ { text: "생성된 대본" } ] } } ] }.to_json
    end

    Net::HTTP.stub(:start, fake_response) do
      post "/scripts/generate", params: { topic: "고양이" }
    end

    assert_response :success
    assert_select '[data-markdown-target="source"]', text: "생성된 대본"
  end

  test "a non-success API response shows an error" do
    fake_response = Net::HTTPBadRequest.new("1.1", "400", "Bad Request")
    fake_response.define_singleton_method(:body) do
      { error: { message: "잘못된 요청" } }.to_json
    end

    Net::HTTP.stub(:start, fake_response) do
      post "/scripts/generate", params: { topic: "고양이" }
    end

    assert_response :success
    assert_select '[data-testid="error-message"]', /API 호출 실패/
  end

  test "requests beyond the rate limit are rejected" do
    ScriptsController::RATE_LIMIT_MAX_REQUESTS.times do
      post "/scripts/generate", params: { topic: "" }
    end

    post "/scripts/generate", params: { topic: "고양이" }
    assert_response :success
    assert_select '[data-testid="error-message"]', /요청이 너무 많습니다/
  end
end
