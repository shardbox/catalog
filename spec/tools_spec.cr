require "spec"
require "shardbox-core/catalog"
require "../src/tools"

describe Catalog::Tools do
  describe ".normalize_category" do
    it "Uncategorized may not have entries" do
      category = Catalog::Category.new("Uncategorized")
      Catalog::Tools.normalize_category(category).should be_empty

      category.shards << Catalog::Entry.new(Repo::Ref.new("git", "foo"))
      Catalog::Tools.normalize_category(category).should eq ["Category 'Uncategorized' must not contain any entries."]
    end

    it "ensures sort order" do
      category = Catalog::Category.new("Foos")
      category.shards << Catalog::Entry.new(Repo::Ref.new("git", "bar"))
      category.shards << Catalog::Entry.new(Repo::Ref.new("git", "foo"))
      Catalog::Tools.normalize_category(category).should be_empty

      category.shards << Catalog::Entry.new(Repo::Ref.new("git", "baz"))
      Catalog::Tools.normalize_category(category).should eq ["Entries are not in sort order."]
      category.shards.map(&.repo_ref.url).should eq %w(bar baz foo)
    end

    describe "remove duplicate entries" do
      it "identical entries" do
        category = Catalog::Category.new("Foos")
        category.shards << Catalog::Entry.new(Repo::Ref.new("git", "bar"))
        category.shards << Catalog::Entry.new(Repo::Ref.new("git", "bar"))
        Catalog::Tools.normalize_category(category).should eq ["Duplicate entry for git:bar."]
        category.shards.size.should eq 1
      end

      it "keeps description" do
        category = Catalog::Category.new("Foos")
        category.shards << Catalog::Entry.new(Repo::Ref.new("git", "bar"))
        category.shards << Catalog::Entry.new(Repo::Ref.new("git", "bar"), "foo")
        Catalog::Tools.normalize_category(category).should eq ["Duplicate entry for git:bar."]
        category.shards.size.should eq 1
        category.shards[0].description.should eq "foo"
      end

      it "keeps mirrors" do
        category = Catalog::Category.new("Foos")
        category.shards << Catalog::Entry.new(Repo::Ref.new("git", "bar"), mirrors: [Catalog::Mirror.new(Repo::Ref.new("git", "bar2"))])
        category.shards << Catalog::Entry.new(Repo::Ref.new("git", "bar"), "foo")
        Catalog::Tools.normalize_category(category).should eq ["Duplicate entry for git:bar."]
        category.shards.size.should eq 2
      end
    end
  end
end
