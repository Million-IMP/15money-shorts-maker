class ScriptsController < ApplicationController
  require 'net/http'
  require 'uri'
  require 'json'

  def index
  end

  def generate
    topic = params[:topic]
    api_key = ENV['GEMINI_API_KEY']

    if api_key.blank? || api_key == 'dummy_key' || api_key == 'your_gemini_api_key_here'
      @error = "Gemini API 키가 설정되지 않았습니다. .env 파일을 확인해주세요."
      render :index
      return
    end

    if topic.blank?
      @error = "주제를 입력해주세요."
      render :index
      return
    end

    prompt = <<~PROMPT
      너는 유튜브 쇼츠 및 인스타그램 릴스를 위한 바이럴 대본 전문가야.
      다음 주제에 대해 [후킹] - [본문] - [콜투액션] 구조로 30초 내외의 대본을 작성해줘.
      말투는 친근한 반말(유튜브 스타일)로 해주고, 시각적 연출 지시문도 괄호로 짧게 포함해줘.
      주제: #{topic}
    PROMPT

    uri = URI("https://generativelanguage.googleapis.com/v1beta/models/gemini-3.6-flash:generateContent?key=#{api_key}")

    request = Net::HTTP::Post.new(uri)
    request['Content-Type'] = 'application/json'
    
    body = {
      contents: [{ parts: [{ text: prompt }] }]
    }
    request.body = body.to_json

    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
      http.request(request)
    end

    result = JSON.parse(response.body)

    if response.is_a?(Net::HTTPSuccess)
      begin
        @script = result["candidates"].first["content"]["parts"].first["text"]
      rescue
        @error = "AI 응답 형식을 파싱할 수 없습니다."
      end
    else
      @error = "API 호출 실패: #{result.dig('error', 'message') || response.message}"
    end

    render :index
  end
end
