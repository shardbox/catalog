#! /usr/bin/env crystal
require "shardbox-core/catalog"
require "shardbox-core/db"

catalog_path = "catalog"

ShardsDB.transaction do |db|
  categories = db.all_categories
  categories.each do |category|
    puts "Exporting #{category.slug}"

    catalog_category = Catalog::Category.new(category.name, category.description)

    shards = db.shards_in_category(category.id)
    shards.each do |item|
      shard = item[:shard]
      repo = item[:repo]
      entry = Catalog::Entry.new(repo.ref, shard.description)

      repos = db.find_mirror_repos(shard.id)
      repos.each do |repo|
        case repo.role
        when "mirror"
          entry.mirror << repo.ref
        when "legacy"
          entry.legacy << repo.ref
        end
      end

      catalog_category.shards << entry
    end

    catalog_category.shards.sort! { |a, b| a.repo_ref.name.compare(b.repo_ref.name, case_insensitive: true) }

    path = File.join(catalog_path, "#{category.slug}.yml")
    File.open(path, "w") do |file|
      catalog_category.to_yaml(file)
    end
  end
end
