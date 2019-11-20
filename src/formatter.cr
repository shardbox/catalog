require "shardbox-core/catalog"
require "./tools"

module Catalog::Tools
  def self.command_format
    all_entries = {} of Repo::Ref => Catalog::Entry
    all_mirrors = Set(Repo::Ref).new

    catalog = Catalog.new(catalog_path)
    catalog.each_category do |category|
      Catalog::Tools.normalize_category(category)

      category.shards.each do |shard|
        all_entries[shard.repo_ref] ||= shard
        if duplicate_repo = Catalog.duplicate_mirror?(shard, all_mirrors, all_entries)
          Catalog::Tools.warn "duplicate mirror #{duplicate_repo}", category
        end
      end

      Catalog::Tools.write(catalog_path, category)
    end

    if Catalog::Tools::WARNINGS.empty?
      exit 0
    else
      exit 1
    end
  end
end
