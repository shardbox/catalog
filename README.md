This is the shard catalog for https://shardbox.org

This repository contains a list of categories and the shards in each category.
For shardbox it provides both a taxonomy and a way to recognize new shards.
The shardbox database is regularly synced with the definitions of this catalog.

# Contributing

Pull requests against this repo are welcome.

## How to add a new shard

You can use this catalog to announce a new shard to shardbox.org.

1. Select which category it should go into (`catalog/` folder).
   If it doesn't fit anywhere else, it should go into `Misc.yml`.
2. Add an entry into the shards list in the category file.
   It should be inserted alphabetically, ordered by repository name
   (that's the last component of the URL). For example `github: a/z`
   is sorted after `github: z/a`.
   See [`shard` format](#Shard) for details.
3. The description should explain the purpose of the shard in as few
   words as possible and should be understandable without expert knowledge.
   Please avoid mentioning that it's a Crystal implementation. All shards
   in this catalog are Crystal implementations.

## How to update a shard's location

When a shard is moved to a different location, its canonical repository needs
to be updated. This is for example the case when moving from a user to org
namespace on GitHub.

1. Identify the category and respective YAML file where the shard is registered.
2. Add the new canonical repository location.
   See [`shard` format](#Shard) for details.
3. Move the previous canonical repo to the [`mirrors` section](#Mirror) with
   `role: legacy` property. This is necessary because existing releases of other
   shards still reference the old location. Whether its still available at that
   location or not doesn't matter, but the reference should stay intact.

## Guidelines

A shard is eligible to be listed in this catalog if it fits this description:

* Provides some usefulness and reusable features. It doesn't need to be a
  library or provide a specific API.
* It is meant to be continuously available. There don't need to be any
  guarantee to be updated or maintained, but it should not simply vanish.
* Written in Crystal.
* Depends only on publicly available dependencies.

If a shard is a dependency of a shard already listed in the catalog, it is
automatically discovered by the shardbox database and should be included
in the catalog.

A repository referenced in this catalog must be publicly accessible. Mirrors
may be non-public or non-accessible; they're still useful for documentation
purposes (outdated mirrors should be marked as `role: legacy`).

# Format

The catalog data is contained in the `./catalog` folder.

## Category

Each category is defined in a `.yml` file.

Properties:

* `name` (string, required): Human-readable name of the category.
* `slug` (string, implicit): Computer-readable name of the category, implict from the file name.
* `description` (string, optional): Optional description of the category.
* `shards` (sequence, required): List of shard entries.

## Shard

Each shard entry requires exactly one reference to the shard's canonical repository.
It is expressed as a mapping from a resolver to an url used for that resolver.
For example `github: shardbox/shardbox-core`.
This is the same as defining dependencies in a `shard.yml` file (see [specification](https://github.com/crystal-lang/shards/blob/master/SPEC.md#dependencies)).
All resolvers supported by `shards` are supported, except for `path` (because
it is not publicly resolvable by definition).

Properties:

* resolver (one of the following is required):
  * `git` (string): URL of a git repository (should be publicly available).
  * `github` (string): Path of a repository on GitHub.
  * `gitlab` (string): Path of a repository on Gitlab.
  * `bitbucket` (string): Path of a repository on Bitbucket.
* `description` (string, optional): Description of the shard.
* `mirrors` (sequence, optional): A list of mirror repositories.
* `state` (string, optional):
  * `archived`: Mark this shard as archived

## Mirror

Each mirror entry points to an alternate location for the shard.

Properties:

* resolver (required): Same as for shards
* `role` (string, optional): Role of this mirror. Possible values:
  * `mirror` (default): A mirror of the main repository.
  * `legacy`: A mirror that is no longer available.

The reason for these properties is that the same shard can be available from different
sources and other shards can use these different repositories as dependencies (including historical releases).
When different repositories reference the *same* shard, they should show up as one.

Example:
```yaml
- github: kemalcr/kemal
  description: Lightning Fast, Super Simple web framework. Inspired by Sinatra
  mirrors:
  - github: sdogruyol/kemal
    role: legacy
```
