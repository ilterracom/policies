#!/usr/bin/env ruby
# Validate public page metadata using only the Ruby standard library.
require "yaml"
require "uri"

ROOT = File.expand_path("..", __dir__)
PAGES = Dir.glob(File.join(ROOT, "**", "*.md")).reject do |path|
  relative = path.delete_prefix(ROOT + "/")
  relative == "README.md" || relative.split("/").any? { |part| part.start_with?("_", ".") }
end

def metadata(path)
  content = File.read(path, encoding: "UTF-8")
  match = content.match(/\A---\s*\n(.*?)\n---\s*\n/m)
  raise "missing YAML front matter" unless match
  YAML.safe_load(match[1], aliases: false) || {}
end

errors = []
products = {}
permalinks = {}
pages = []

begin
  config = YAML.safe_load(File.read(File.join(ROOT, "_config.yml"), encoding: "UTF-8"), aliases: false) || {}
  site_url = URI.parse(config["url"].to_s)
  errors << "_config.yml: url must be an HTTPS domain" unless site_url.is_a?(URI::HTTPS) && site_url.host
  errors << "_config.yml: baseurl must be empty for the custom domain" unless config["baseurl"] == ""
  errors << "_config.yml: repository_url must point to the public repository" unless config["repository_url"] == "https://github.com/ilterracom/policies"
  cname_path = File.join(ROOT, "CNAME")
  if File.exist?(cname_path) && File.read(cname_path, encoding: "UTF-8").strip != site_url.host
    errors << "CNAME: domain does not match _config.yml url"
  end
rescue StandardError => e
  errors << "_config.yml: #{e.message}"
end

PAGES.each do |path|
  relative = path.delete_prefix(ROOT + "/")
  begin
    errors << "#{relative}: public content must be in English" if File.read(path, encoding: "UTF-8").match?(/[А-Яа-яЁё]/)
    data = metadata(path)
    pages << [relative, data]
    url = data["permalink"]
    valid_url = url.is_a?(String) && (url.match?(%r{\A/(?:[a-z0-9.-]+/)*\z}) || url == "/404.html")
    if !valid_url
      errors << "#{relative}: invalid permalink"
    elsif permalinks.key?(url)
      errors << "#{relative}: permalink #{url} already belongs to #{permalinks[url]}"
    else
      permalinks[url] = relative
    end

    next unless data["layout"] == "product"
    id = data["product_id"]
    errors << "#{relative}: product_id must be a lowercase slug" unless id.to_s.match?(/\A[a-z0-9]+(?:-[a-z0-9]+)*\z/)
    errors << "#{relative}: replace the template product name" if data["title"] == "Product name"
    errors << "#{relative}: missing product title" if data["title"].to_s.empty?
    errors << "#{relative}: permalink must be /#{id}/" if url != "/#{id}/"
    errors << "#{relative}: duplicate product_id #{id}" if products.key?(id)
    errors << "#{relative}: order must be an integer" unless data["order"].is_a?(Integer)
    if data["icon"]
      icon = data["icon"].to_s
      expected = %r{\A/assets/products/#{Regexp.escape(id.to_s)}/icon\.(?:jpg|png|webp|svg)\z}
      errors << "#{relative}: icon must be /assets/products/#{id}/icon.jpg, .png, .webp or .svg" unless icon.match?(expected)
      errors << "#{relative}: icon file does not exist" unless File.file?(File.join(ROOT, icon.delete_prefix("/")))
    end
    products[id] = relative unless id.to_s.empty?

    next unless data["external_documents"]
    unless data["external_documents"].is_a?(Array)
      errors << "#{relative}: external_documents must be a list"
      next
    end
    data["external_documents"].each_with_index do |external, index|
      unless external.is_a?(Hash) && !external["title"].to_s.empty?
        errors << "#{relative}: external document #{index + 1} needs a title"
        next
      end
      begin
        link = URI.parse(external["url"].to_s)
        raise URI::InvalidURIError unless link.is_a?(URI::HTTPS) && link.host
      rescue URI::InvalidURIError
        errors << "#{relative}: external document #{index + 1} needs an HTTPS URL"
      end
    end
  rescue StandardError => e
    errors << "#{relative}: #{e.message}"
  end
end

pages.each do |relative, data|
  next unless data["layout"] == "document"
  id = data["product"]
  errors << "#{relative}: no product page for product=#{id.inspect}" unless id == "company" || products.key?(id)
  errors << "#{relative}: permalink must start with /#{id}/" unless data["permalink"].to_s.start_with?("/#{id}/")
  errors << "#{relative}: missing title" if data["title"].to_s.empty?
  %w[version effective_date updated_date source_snapshot archived].each do |field|
    errors << "#{relative}: #{field} is no longer used; the release branch records document history" if data.key?(field)
  end
  if data.key?("source_url")
    begin
      link = URI.parse(data["source_url"].to_s)
      errors << "#{relative}: source_url must point to ilterra.com over HTTPS" unless link.is_a?(URI::HTTPS) && link.host == "ilterra.com"
    rescue URI::InvalidURIError
      errors << "#{relative}: invalid source_url"
    end
  end
  errors << "#{relative}: order must be an integer" unless data["order"].is_a?(Integer)
  body = File.read(File.join(ROOT, relative), encoding: "UTF-8")
  errors << "#{relative}: template text remains in the document" if body.include?("<!-- TEMPLATE:")
  placeholders = %w[LEGAL\ ENTITY\ NAME REGISTERED\ ADDRESS BILLING\ EMAIL SUPPORT\ EMAIL GOVERNING\ LAW\ JURISDICTION COURTS\ JURISDICTION CURRENCY\ AND\ AMOUNT]
  errors << "#{relative}: unresolved legal placeholder" if placeholders.any? { |field| body.include?("[#{field}]") }
end

if errors.empty?
  puts "Content check passed: #{pages.count} pages, #{products.count} products."
else
  warn errors.join("\n")
  exit 1
end
