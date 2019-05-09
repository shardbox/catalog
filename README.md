This is the shard catalog for https://shardbox.org

This repository contains a list of categories and the shards in each category.
For shardbox it provides both a taxonomy and a way to recognize new shards.
The shardbox database is regularly synced with the definitions of this catalog.

# Contributing

Pull requests against this repo are welcome.

You can use this to announce new shards to shardbox.org.

# Format

The catalog is contained in `./catalog` forlder. It contains a `.yml` file for each category.

Every category the following properties:

* `name` (string, required): Human-readable name of the category
* `slug` (string, implicit): Computer-readable name of the category, implict from the file name
* `description` (string, optional): Optional description
* `shards` (sequence, required): List of shard entries

Each shard entry requires exactly one reference to the shards canonical repository.
It is expressed as a mapping from a resolver to an url used for that resolver.
For example `github: shardbox/shardbox-core`
This is the same as defining dependencies in a `shard.yml` file (see [specification](https://github.com/crystal-lang/shards/blob/master/SPEC.md#dependencies)).
All resolvers supported by `shards` are supported, except for `path` (because it's not publicly resolvable).

Optional properties:

* `description` (string, optional): Description of the shard
* `mirror` (sequence, optional): A list of current repository mappings for the same shard
* `legacy` (sequence, optional): A list of discontinued repository mappings for the same shard

`mirror` and `legacy` are a list of repository mappings pointing to alternate sources
for this shard.  `mirror` describes currently valid alternatives and `legacy`
discontinued repo references.

The reason for these properties is that the same shard can be available from different
sources and other shards can use these different repositories as dependencies (including historical releases).
When different repositories reference the *same*  shard, they should show up as one.

Example:
```yaml
- github: kemalcr/kemal
  description: Lightning Fast, Super Simple web framework. Inspired by Sinatra
  legacy:
  - github: sdogruyol/kemal
```
