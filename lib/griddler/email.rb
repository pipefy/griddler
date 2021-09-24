require 'htmlentities'

module Griddler
  class Email
    include ActionView::Helpers::SanitizeHelper
    attr_reader :to, :from, :cc, :bcc, :subject, :raw_body, :raw_text, :raw_html, :headers, :raw_headers, :attachments, :content_ids

    def initialize(params)
      @params = params

      @to = recipients(:to)
      @from = extract_address(params[:from])
      @subject = extract_subject

      @raw_text = params[:text]
      @raw_html = params[:html]
      @raw_body = @raw_text.presence || @raw_html

      @headers = extract_headers
      @content_ids = params['content-ids']
      @cc = recipients(:cc)
      @bcc = recipients(:bcc)

      @raw_headers = params[:headers]

      @attachments = params[:attachments]
    end

    private

    attr_reader :params

    def config
      @config ||= Griddler.configuration
    end

    def recipients(type)
      params[type].to_a.map { |recipient| extract_address(recipient) }
    end

    def extract_address(address)
      EmailParser.parse_address(clean_invalid_utf8_bytes(address))
    end

    def extract_subject
      clean_invalid_utf8_bytes(params[:subject])
    end

    def extract_headers
      if params[:headers].is_a?(Hash)
        deep_clean_invalid_utf8_bytes(params[:headers])
      else
        EmailParser.extract_headers(clean_invalid_utf8_bytes(params[:headers]))
      end
    end

    def extract_cc_from_headers(headers)
      EmailParser.extract_cc(headers)
    end

    def deep_clean_invalid_utf8_bytes(object)
      case object
      when Hash
        object.inject({}) do |clean_hash, (key, dirty_value)|
          clean_hash[key] = deep_clean_invalid_utf8_bytes(dirty_value)
          clean_hash
        end
      when Array
        object.map { |element| deep_clean_invalid_utf8_bytes(element) }
      when String
        clean_invalid_utf8_bytes(object)
      else
        object
      end
    end

    def clean_invalid_utf8_bytes(text)
      if text && !text.valid_encoding?
        text.force_encoding('ISO-8859-1').encode!('UTF-8')
      else
        text
      end
    end
  end
end
