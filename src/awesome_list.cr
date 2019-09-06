#! /usr/bin/env crystal
#
require "http/client"
require "file_utils"
require "shardbox-core/catalog"
require "shardbox-core/db"

AWESOME_URL = ARGV.first? || "https://raw.githubusercontent.com/veelenga/awesome-crystal/master/README.md"

catalog = [] of Catalog::Category

HTTP::Client.get(AWESOME_URL) do |response|
  if response.status_code != 200
    abort "Status code: #{response.status_code}"
  end

  current_category = nil
  lino = 0
  response.body_io.each_line do |line|
    lino += 1
    if line.starts_with?("# ") && line != "# Awesome Crystal"
      break
    elsif line.starts_with?("## ")
      current_category = Catalog::Category.new(line.byte_slice(3, line.bytesize - 3).strip)
      catalog << current_category
    elsif current_category
      if match = line.match(/\A\s*\* \[(?<name>.+)\]\((?<url>.+)\) [–-] (?<description>.+)\z/)

        url = URI.parse(match["url"])
        if url.path.ends_with?(".html")
          next
        end

        repo_ref = Repo::Ref.new(url) rescue next
        current_category.shards << Catalog::Entry.new(repo_ref, match["description"])
      elsif !line.strip.empty?
        print "// "
        puts line
      end
    end
  end
end

FileUtils.mkdir_p("catalog")

catalog.each do |category|
  filename = File.join("catalog", category.name.gsub(%r{[/ \\]+}, '_'))
  File.open("#{filename}.yml", "w") do |file|
    category.to_yaml(file)
  end
end
