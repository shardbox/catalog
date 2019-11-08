#! /usr/bin/env crystal
require "shardbox-core/catalog"

catalog_path = "catalog"

Catalog.each_category(catalog_path) do |yaml_category, category_slug|
  shards = yaml_category.shards
  if category_slug == "Uncategorized"
    if !shards.empty?
      warn "Category 'Uncategorized' must not contain any entries.", category_slug
    end
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

      warn "Duplicate entry for #{cons[0].repo_ref.url}.", category_slug
    end
  end

  path = File.join(catalog_path, "#{category_slug}.yml")
  File.open(path, "w") do |file|
    yaml_category.to_yaml(file)
  end
end

WARNINGS = Hash(String, Array(String)).new { |hash, k| hash[k] = [] of String }

def warn(message, category_slug)
  list = WARNINGS[category_slug]

  if list.empty?
    puts "In #{category_slug}:"
  end

  list << message

  print "  "
  puts message
end

if WARNINGS.empty?
  exit 0
else
  exit 1
end
