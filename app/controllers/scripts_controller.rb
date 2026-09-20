class ScriptsController < ApplicationController
  require "net/http"
  require "uri"
  require "json"

  GEMINI_MODEL = "gemini-3.6-flash"
  MAX_TOPIC_LENGTH = 200
  RATE_LIMIT_MAX_REQUESTS = 5
  RATE_LIMIT_WINDOW = 10.minutes

  def index
  end

  def generate
    if rate_limited?
      @error = "요청이 너무 많습니다. 잠시 후 다시 시도해주세요."
      return render :index
    end

    topic = params[:topic].to_s.strip
    api_key = ENV["GEMINI_API_KEY"]

    if api_key.blank? || api_key == "dummy_key" || api_key == "your_gemini_api_key_here"
      @error = "Gemini API 키가 설정되지 않았습니다. .env 파일을 확인해주세요."
      return render :index
    end

    if topic.blank?
      @error = "주제를 입력해주세요."
      return render :index
    end

    if topic.length > MAX_TOPIC_LENGTH
      @error = "주제는 #{MAX_TOPIC_LENGTH}자 이내로 입력해주세요."
      return render :index
    end

    @script = request_script(topic, api_key)
    render :index
  end

  private

  def request_script(topic, api_key)
    uri = URI("https://generativelanguage.googleapis.com/v1beta/models/#{GEMINI_MODEL}:generateContent?key=#{api_key}")

    request = Net::HTTP::Post.new(uri)
    request["Content-Type"] = "application/json"
    request.body = { contents: [ { parts: [ { text: build_prompt(topic) } ] } ] }.to_json

    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true, open_timeout: 5, read_timeout: 30) do |http|
      http.request(request)
    end

    result = JSON.parse(response.body)

    unless response.is_a?(Net::HTTPSuccess)
      @error = "API 호출 실패: #{result.dig("error", "message") || response.message}"
      return nil
    end

    text = result.dig("candidates", 0, "content", "parts", 0, "text")
    @error = "AI 응답 형식을 파싱할 수 없습니다." if text.blank?
    text
  rescue Net::OpenTimeout, Net::ReadTimeout
    @error = "AI 서버 응답이 지연되고 있습니다. 잠시 후 다시 시도해주세요."
    nil
  rescue JSON::ParserError
    @error = "AI 응답을 처리할 수 없습니다. 잠시 후 다시 시도해주세요."
    nil
  rescue StandardError => e
    Rails.logger.error("[ScriptsController] Gemini request failed: #{e.class} #{e.message}")
    @error = "일시적인 오류가 발생했습니다. 잠시 후 다시 시도해주세요."
    nil
  end

  def build_prompt(topic)
    <<~PROMPT
      너는 유튜브 쇼츠 및 인스타그램 릴스를 위한 바이럴 대본 전문가야.
      다음 주제에 대해 [후킹] - [본문] - [콜투액션] 구조로 30초 내외의 대본을 작성해줘.
      말투는 친근한 반말(유튜브 스타일)로 해주고, 시각적 연출 지시문도 괄호로 짧게 포함해줘.
      주제: #{topic}
    PROMPT
  end

  def rate_limited?
    count = Rails.cache.read(rate_limit_key) || 0
    return true if count >= RATE_LIMIT_MAX_REQUESTS

    Rails.cache.write(rate_limit_key, count + 1, expires_in: RATE_LIMIT_WINDOW)
    false
  end

  def rate_limit_key
    "scripts_generate_rate_limit:#{request.remote_ip}"
  end
end
