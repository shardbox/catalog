#! /usr/bin/env crystal

require "http"
require "log"
require "shardbox-core/db"
require "shardbox-core/repo"
require "shardbox-core/repo/ref"
require "shardbox-core/catalog"
require "shardbox-core/fetchers/github_api"

CLIENT = Shardbox::GitHubAPI.new

total = ARGV[0]?.try(&.to_i) || 100

def query_repos(after)
  response = CLIENT.query <<-GRAPHQL, {first: 100, after: after}
    query CrystalShards($first: Int!, $after: String) {
      search(query: "language:Crystal", first: $first, after: $after, type: REPOSITORY) {
        nodes {
          ... on Repository {
            nameWithOwner
            description
            ref(qualifiedName: "master") {
              name
              target {
                ... on Commit {
                  tree {
                    entries {
                      name
                    }
                  }
                }
              }
            }
          }
        }
        pageInfo {
          endCursor
        }
      }
    }
    GRAPHQL

  json = JSON.parse(response)
  data = json["data"]?
  unless data
    p json
    abort "Invalid response"
  end

  data["search"]
end

black_listed = [] of String
no_shard_yml = [] of String
in_catalog = [] of String
added = [] of String

blacklist = File.open("BLACKLIST") do |file|
  Array(Catalog::Entry).from_yaml(file)
end

after = nil
while total > 0
  data = query_repos(after)

  nodes = data["nodes"]
  after = data["pageInfo"]["endCursor"]
  total -= nodes.size

  ShardsDB.transaction do |db|
    nodes.as_a.each do |node|
      url = node["nameWithOwner"].as_s

      ref = node["ref"]?
      next unless ref
      entries = ref.dig("target", "tree", "entries").as_a
      has_shard_yml = entries.any? do |entry|
        entry["name"] == "shard.yml"
      end
      unless has_shard_yml
        no_shard_yml << url
        next
      end

      is_blacklisted = blacklist.any? do |entry|
        entry.repo_ref == Repo::Ref.new("github", url)
      end
      if is_blacklisted
        black_listed << url
        next
      end

      if db.get_repo_id?("github", url)
        in_catalog << url
      else
        puts "github:#{url}"
        added << url
      end
    rescue exc
      STDERR.puts exc
    end
  end
end

p! black_listed,
  no_shard_yml,
  in_catalog.size,
  added.size
