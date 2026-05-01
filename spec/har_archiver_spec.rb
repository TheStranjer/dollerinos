require_relative "../spec/spec_helper"
require_relative "../lib/har_archiver"
require "json"
require "time"
require "net/http"

describe Trading::HarArchiver do
  let(:archiver) { described_class.new }

  describe "#archive" do
    let(:request_data) do
      {
        method: "POST",
        url: "https://api.x.ai/v1/responses",
        headers: [
          { name: "Content-Type", value: "application/json" },
          { name: "Authorization", value: "Bearer test_key" }
        ],
        body: '{"test": "data"}'
      }
    end

    let(:response_data) do
      {
        code: 200,
        message: "OK",
        headers: [
          { name: "content-type", value: "application/json" }
        ],
        content_type: "application/json",
        body: '{"result": "success"}'
      }
    end

    let(:start_time) { Time.now }
    let(:end_time) { start_time + 0.5 }

    before do
      # Clean up any existing HAR files
      Dir.glob("/home/neetzsche/Code/dollerinos/output/*.har").each { |f| File.delete(f) }
    end

    it "creates a HAR file in the output directory" do
      filepath = archiver.archive(request_data, response_data, start_time, end_time)
      expect(File.exist?(filepath)).to be true
      expect(filepath).to include("output/grok_")
      expect(filepath).to end_with(".har")
    end

    it "generates timestamp-based filenames" do
      filepath1 = archiver.archive(request_data, response_data, start_time, end_time)
      sleep 0.01
      filepath2 = archiver.archive(request_data, response_data, start_time, end_time)
      expect(filepath1).not_to eq(filepath2)
    end

    it "creates valid HAR JSON structure" do
      filepath = archiver.archive(request_data, response_data, start_time, end_time)
      content = File.read(filepath)
      har_data = JSON.parse(content)

      expect(har_data).to have_key("log")
      expect(har_data["log"]).to have_key("version")
      expect(har_data["log"]).to have_key("creator")
      expect(har_data["log"]).to have_key("entries")
    end

    it "includes request details in HAR" do
      filepath = archiver.archive(request_data, response_data, start_time, end_time)
      har_data = JSON.parse(File.read(filepath))
      entry = har_data["log"]["entries"][0]

      expect(entry["request"]["method"]).to eq("POST")
      expect(entry["request"]["url"]).to eq("https://api.x.ai/v1/responses")
      expect(entry["request"]["headers"]).to be_an(Array)
      expect(entry["request"]["postData"]["text"]).to eq('{"test": "data"}')
    end

    it "includes response details in HAR" do
      filepath = archiver.archive(request_data, response_data, start_time, end_time)
      har_data = JSON.parse(File.read(filepath))
      entry = har_data["log"]["entries"][0]

      expect(entry["response"]["status"]).to eq(200)
      expect(entry["response"]["statusText"]).to eq("OK")
      expect(entry["response"]["content"]["text"]).to eq('{"result": "success"}')
    end

    it "includes timing information" do
      filepath = archiver.archive(request_data, response_data, start_time, end_time)
      har_data = JSON.parse(File.read(filepath))
      entry = har_data["log"]["entries"][0]

      expect(entry["timings"]).to have_key("wait")
      expect(entry["time"]).to match(/\d+ms/)
    end
  end

  describe ".archive" do
    it "is a convenience class method" do
      request_data = {
        method: "POST",
        url: "https://api.x.ai/v1/responses",
        headers: [],
        body: "{}"
      }
      response_data = {
        code: 200,
        message: "OK",
        headers: [],
        content_type: "application/json",
        body: '{"result": "ok"}'
      }
      start_time = Time.now
      end_time = Time.now

      filepath = Trading::HarArchiver.archive(request_data, response_data, start_time, end_time)
      expect(File.exist?(filepath)).to be true

      File.delete(filepath)
    end
  end
end
