module Catalog::Tools
  WARNINGS = Hash(String, Array(String)).new { |hash, k| hash[k] = [] of String }

  def self.normalize_category(category)
    shards = category.shards
    if category.slug == "Uncategorized" && !shards.empty?
      warn "Category 'Uncategorized' must not contain any entries.", category.slug
    end

    shards.sort! { |a, b| a.repo_ref.name.compare(b.repo_ref.name, case_insensitive: true) }

    shards.map! do |shard|
      if description = shard.description
        shard.description = description.strip.rchop('.').rchop('!')
      end

      shard
    end

    shards.dup.each_cons(2, reuse: true) do |cons|
      a, b = cons
      if a.repo_ref == b.repo_ref
        # Try to remove duplicate entries automatically
        if a.mirrors == b.mirrors
          if a.description == b.description || a.description.nil?
            shards.delete(a)
            next
          elsif b.description.nil?
            shards.delete(b)
            next
          end
        end

        warn "Duplicate entry for #{cons[0].repo_ref.url}.", category.slug
      end
    end
  end

  def self.warn(message, category_slug : String)
    list = WARNINGS[category_slug]

    if list.empty?
      puts "In #{category_slug}:"
    end

    list << message

    print "  "
    puts message
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
