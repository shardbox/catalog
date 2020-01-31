require "shardbox-core/catalog"
require "./tools"

module Catalog::Tools
  def self.command_format
    has_warnings = false
    duplication = Catalog::Duplication.new

    catalog = Catalog.new(catalog_path)
    catalog.each_category do |category|
      warnings = Catalog::Tools.normalize_category(category)

      category.shards.each do |shard|
        if error = duplication.register(category.slug, shard)
          warnings << error.message
        end
      end

      Catalog::Tools.write(catalog_path, category)

      warnings.each do |warning|
        Catalog::Tools.warn warning, category.slug
      end
      has_warnings ||= warnings.any?
    end

    !has_warnings
  end
end
