#!/usr/bin/env ruby
# frozen_string_literal: true

require "json"
require "open-uri"
require "openssl"

def workgroup_ietf
  result = []
  URI.open("https://tools.ietf.org/wg/") do |f|
    f.each_line do |l|
      l.scan(%r{<td width="50%" style='padding: 0 1ex'>([^<]+)</td>}) do |w|
        result << w[0].gsub(/\s+$/, "").gsub(/ Working Group$/, "")
      end
    end
  end
  result
end

def workgroup_irtf
  result = []
  URI.open("https://irtf.org/groups", ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE) do |f| # rubocop:disable Layout/LineLength
    f.each_line do |l|
      l.scan(%r{<a title="([^"]+) Research Group"[^>]+>([^<]+)<}) do |w|
        result << w[0].gsub(/\s+$/, "")
        result << w[1].gsub(/\s+$/, "") # abbrev
      end
    end
  end
  result
end

print [workgroup_ietf, workgroup_irtf].flatten.to_json
