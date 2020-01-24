module Catalog::Tools
  def self.normalize_category(category)
    warnings = [] of String

    shards = category.shards
    if category.slug == "Uncategorized" && !shards.empty?
      warnings << "Category 'Uncategorized' must not contain any entries."
    end

    shards.sort! { |a, b| a.repo_ref.name.compare(b.repo_ref.name, case_insensitive: true) }

    shards.map! do |shard|
      if description = shard.description
        shard.description = description.strip.rchop('.').rchop('!')
      end

      shard
    end

    shards.dup.each_cons_pair do |a, b|
      if a.repo_ref == b.repo_ref
        # Try to remove duplicate entries automatically
        if a.mirrors == b.mirrors
          if a.description == b.description || a.description.nil?
            if a_index = shards.index(a)
              shards.delete_at(a_index)
            end
          elsif b.description.nil?
            if b_index = shards.index(b)
              shards.delete_at(b_index)
            end
          end
        end

        warnings << "Duplicate entry for #{a.repo_ref}."
      end
    end

    warnings
  end

  @@last_slug : String? = nil

  def self.warn(message, category_slug : String)
    if @@last_slug != category_slug
      STDERR.puts "#{category_slug}.yml:"
      @@last_slug = category_slug
    end

    STDERR.print "  "
    STDERR.puts message
  end

  def self.write(catalog_path, category)
    path = File.join(catalog_path, "#{category.slug}.yml")
    File.open(path, "w") do |file|
      category.to_yaml(file)
    end
  end

  def self.catalog_path
    "./catalog"
  end
end
