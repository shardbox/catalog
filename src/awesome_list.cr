#! /usr/bin/env crystal
#
require "http/client"
require "file_utils"
require "shardbox-core/catalog"
require "./tools"

module Catalog::Tools
  def self.command_awesome_list(args)
    awesome_url = args.first? || "https://raw.githubusercontent.com/veelenga/awesome-crystal/master/README.md"

    FileUtils.mkdir_p(catalog_path)
    categories = {} of String => Catalog::Category
    catalog = Catalog.new(catalog_path)
    catalog.each_category do |category|
      categories[category.slug] = category
    end

    awesome_categories = fetch_awesomelist(awesome_url)
    awesome_categories.each do |awesome_cat|
      if category = categories[awesome_cat.slug]?
        new_shards = awesome_cat.shards.reject do |shard|
          category.shards.any? { |s| s.repo_ref == shard.repo_ref }
        end

        removed_shards = category.shards.reject do |shard|
          awesome_cat.shards.any? { |s| s.repo_ref == shard.repo_ref }
        end

        updated_shards = awesome_cat.shards.compact_map do |awesome_shard|
          catalog_shard = category.shards.find { |s| s.repo_ref == awesome_shard.repo_ref && s != awesome_shard }
          if catalog_shard
            {catalog_shard, awesome_shard}
          end
        end

        category.shards.concat(new_shards)

        removed_shards.each do |shard|
          shard.state = :archived
        end

        updated_shards.each do |catalog_shard, awesome_shard|
          category.shards.delete(catalog_shard)
          awesome_shard.mirrors.concat(catalog_shard.mirrors)
          category.shards << awesome_shard
        end
      else
        category = categories[awesome_cat.name] = awesome_cat
      end

      Catalog::Tools.normalize_category(category)

      Catalog::Tools.write(catalog_path, category)
    end
  end

  def self.fetch_awesomelist(awesome_url)
    catalog = [] of Catalog::Category

    HTTP::Client.get(awesome_url) do |response|
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
          name = line.byte_slice(3, line.bytesize - 3).strip
          current_category = Catalog::Category.new(name)
          current_category.slug = name.gsub(%r{[/ \\_]+}, '_') # FIXME: /
          catalog << current_category
        elsif current_category
          if match = line.match(/\A\s*\* \[(?<name>[^\]]+)\]\((?<url>[^)]+)\)( [–-] (?<description>.+))?\z/)
            url = URI.parse(match["url"])
            if url.path.ends_with?(".html")
              next
            end

            repo_ref = Repo::Ref.new(url) rescue next
            current_category.shards << Catalog::Entry.new(repo_ref, match["description"]?)
          elsif !line.strip.empty?
            print "// "
            puts line
          end
        end
      end
    end

    catalog
  end
end
