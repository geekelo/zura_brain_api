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

      body = response.body
      body = JSON.parse(body) if body.is_a?(String)
      body = body.deep_stringify_keys if body.respond_to?(:deep_stringify_keys)
      data = body["data"] || {}

      raise Error, "Upload failed" unless response.success? && body["success"]

      {
        img_url: data["url"],
        del_url: data["delete_url"],
        date_time: Time.current.iso8601
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
