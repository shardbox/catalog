require "http"
require "logger"
require "shardbox-core/db"
require "shardbox-core/ext/shards/resolvers/github"
require "shardbox-core/repo"
require "shardbox-core/repo/ref"
require "shardbox-core/catalog"

CLIENT = Shards::GithubResolver.graphql_client

total = ARGV[0]?.try(&.to_i) || 100

def query_repos(after)
  body = {
    variables: {first: 100, after: after},
    query:     <<-GRAPHQL
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
  }

  response = CLIENT.post "/graphql", body: body.to_json, headers: HTTP::Headers{"Authorization" => "bearer #{Shards::GithubResolver.api_token}"}

  abort "can't connect to GitHub API" unless response.status_code == 200

  json = JSON.parse(response.body)
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
  STDERR.puts "Querying GraphQL after:#{after}"
  data = query_repos(after)

  nodes = data["nodes"]
  STDERR.puts "#{nodes.size} responses"
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
        puts "- github: #{url}"
        puts "  description: #{node["description"]}"
        added << url
      end
    rescue exc
      p! node
      STDERR.puts exc
    end
  end
end

p! black_listed,
  no_shard_yml,
  in_catalog.size,
  added.size
