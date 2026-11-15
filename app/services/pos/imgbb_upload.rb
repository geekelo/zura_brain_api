require "faraday"
require "faraday/multipart"

module Pos
  class ImgbbUpload
    class Error < StandardError; end

    def self.call(file, name:)
      new(file, name).call
    end

    def initialize(file, name)
      @file = file
      @name = name
    end

    def call
      response = connection.post("/1/upload") do |req|
        req.params["key"] = ENV.fetch("IMGBB_API_KEY")
        req.body = {
          image: Faraday::Multipart::FilePart.new(
            @file.tempfile.path,
            @file.content_type.presence || "application/octet-stream",
            @file.original_filename
          ),
          name: @name
        }
      end

      raise Error, "Upload failed" unless response.success? && response.body["success"]

      {
        view_url: response.body.dig("data", "url"),
        delete_url: response.body.dig("data", "delete_url"),
        time: response.body.dig("data", "time")
      }
    end

    private

    def connection
      Faraday.new(url: "https://api.imgbb.com") do |f|
        f.request :multipart
        f.response :json
        f.adapter Faraday.default_adapter
      end
    end
  end
end
