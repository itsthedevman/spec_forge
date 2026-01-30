# frozen_string_literal: true

RSpec.describe SpecForge::Loader::Filter do
  let(:blueprints) do
    [
      {
        name: "auth/login",
        file_path: fixtures_path.join("blueprints", "auth", "login.yml"),
        file_name: "login.yml",
        steps: [
          {name: "Login step 1", tags: ["auth", "login"]},
          {name: "Login step 2", tags: ["auth", "login", "api"]}
        ]
      },
      {
        name: "auth/logout",
        file_path: fixtures_path.join("blueprints", "auth", "logout.yml"),
        file_name: "logout.yml",
        steps: [
          {name: "Logout step 1", tags: ["auth", "logout"]},
          {name: "Logout step 2", tags: ["auth", "logout", "cleanup"]}
        ]
      },
      {
        name: "api/users",
        file_path: fixtures_path.join("blueprints", "api", "users.yml"),
        file_name: "users.yml",
        steps: [
          {name: "Create user", tags: ["api", "users", "crud", "write"]},
          {name: "Get user", tags: ["api", "users", "crud", "read"]},
          {name: "Delete user", tags: ["api", "users", "crud", "write"]}
        ]
      },
      {
        name: "api/posts",
        file_path: fixtures_path.join("blueprints", "api", "posts.yml"),
        file_name: "posts.yml",
        steps: [
          {name: "Create post", tags: ["api", "posts", "crud", "write"]},
          {name: "Get post", tags: ["api", "posts", "crud", "read"]}
        ]
      },
      {
        name: "setup",
        file_path: fixtures_path.join("blueprints", "setup.yml"),
        file_name: "setup.yml",
        steps: [
          {name: "Database setup", tags: ["setup", "database"]},
          {name: "Cache setup", tags: ["setup", "cache"]}
        ]
      }
    ]
  end

  let(:path) { nil }
  let(:tags) { [] }
  let(:skip_tags) { [] }

  subject(:filtered) { described_class.new(blueprints).run(path:, tags:, skip_tags:) }

  before do
    allow(SpecForge).to receive(:blueprints_path).and_return(fixtures_path.join("blueprints"))
  end

  context "when a path is provided" do
    context "and path matches a directory" do
      let(:path) { fixtures_path.join("blueprints", "auth") }

      it "is expected to filter blueprints to only those in the directory" do
        expect(filtered.size).to eq(2)
        expect(filtered.map { |b| b[:name] }).to eq(["auth/login", "auth/logout"])
      end
    end

    context "and path matches a specific file" do
      let(:path) { fixtures_path.join("blueprints", "api", "users.yml") }

      it "is expected to filter blueprints to only the specific file" do
        expect(filtered.size).to eq(1)
        expect(filtered[0][:name]).to eq("api/users")
      end
    end

    context "and path matches a partial directory" do
      let(:path) { fixtures_path.join("blueprints", "api") }

      it "is expected to filter blueprints to only those in that directory" do
        expect(filtered.size).to eq(2)
        expect(filtered.map { |b| b[:name] }).to eq(["api/users", "api/posts"])
      end
    end

    context "and path does not match any blueprints" do
      let(:path) { fixtures_path.join("blueprints", "nonexistent") }

      it "is expected to return an empty array" do
        expect(filtered).to be_empty
      end
    end

    context "and path has .yml extension" do
      let(:path) { fixtures_path.join("blueprints", "setup.yml") }

      it "is expected to strip the extension and match correctly" do
        expect(filtered.size).to eq(1)
        expect(filtered[0][:name]).to eq("setup")
      end
    end

    context "and path has .yaml extension" do
      let(:path) { fixtures_path.join("blueprints", "setup.yaml") }

      it "is expected to strip the extension and match correctly" do
        expect(filtered.size).to eq(1)
        expect(filtered[0][:name]).to eq("setup")
      end
    end
  end

  context "when tags are provided" do
    context "with a single tag" do
      let(:tags) { ["auth"] }

      it "is expected to filter steps to only those with the tag" do
        auth_login = filtered.find { |b| b[:name] == "auth/login" }
        auth_logout = filtered.find { |b| b[:name] == "auth/logout" }

        expect(auth_login[:steps].size).to eq(2)
        expect(auth_logout[:steps].size).to eq(2)
        expect(auth_login[:steps].all? { |s| s[:tags].include?("auth") }).to be true
      end

      it "is expected to keep all blueprints that have matching steps" do
        expect(filtered.size).to eq(2)
        expect(filtered.map { |b| b[:name] }).to contain_exactly("auth/login", "auth/logout")
      end
    end

    context "with multiple tags (OR logic)" do
      let(:tags) { ["login", "logout"] }

      it "is expected to filter steps that match any of the tags" do
        auth_login = filtered.find { |b| b[:name] == "auth/login" }
        auth_logout = filtered.find { |b| b[:name] == "auth/logout" }

        expect(auth_login[:steps].size).to eq(2)
        expect(auth_logout[:steps].size).to eq(2)
        expect(filtered.size).to eq(2)
      end
    end

    context "with a tag that matches no steps" do
      let(:tags) { ["nonexistent"] }

      it "is expected to return no blueprints" do
        expect(filtered).to be_empty
      end
    end

    context "with tags that match some blueprints" do
      let(:tags) { ["crud"] }

      it "is expected to only include blueprints with matching steps" do
        expect(filtered.size).to eq(2)
        expect(filtered.map { |b| b[:name] }).to contain_exactly("api/users", "api/posts")
      end

      it "is expected to remove blueprints with no matching steps" do
        expect(filtered.none? { |b| b[:name] == "auth/login" }).to be true
        expect(filtered.none? { |b| b[:name] == "auth/logout" }).to be true
        expect(filtered.none? { |b| b[:name] == "setup" }).to be true
      end
    end
  end

  context "when skip_tags are provided" do
    context "with a single skip tag" do
      let(:skip_tags) { ["login"] }

      it "is expected to remove steps with the skip tag" do
        auth_login = filtered.find { |b| b[:name] == "auth/login" }

        expect(auth_login).to be_nil
      end

      it "is expected to keep steps without the skip tag" do
        auth_logout = filtered.find { |b| b[:name] == "auth/logout" }
        api_users = filtered.find { |b| b[:name] == "api/users" }

        expect(auth_logout[:steps].size).to eq(2)
        expect(api_users[:steps].size).to eq(3)
      end
    end

    context "with multiple skip tags" do
      let(:skip_tags) { ["login", "logout"] }

      it "is expected to remove steps matching any skip tag" do
        expect(filtered.none? { |b| b[:name] == "auth/login" }).to be true
        expect(filtered.none? { |b| b[:name] == "auth/logout" }).to be true
        expect(filtered.size).to eq(3)
      end
    end

    context "with a skip tag that removes all steps from a blueprint" do
      let(:skip_tags) { ["setup"] }

      it "is expected to remove the entire blueprint" do
        expect(filtered.none? { |b| b[:name] == "setup" }).to be true
        expect(filtered.size).to eq(4)
      end
    end

    context "with skip tags that partially affect blueprints" do
      let(:skip_tags) { ["write"] }

      it "is expected to keep blueprints with remaining steps" do
        api_users = filtered.find { |b| b[:name] == "api/users" }
        api_posts = filtered.find { |b| b[:name] == "api/posts" }

        expect(api_users).not_to be_nil
        expect(api_posts).not_to be_nil
      end

      it "is expected to remove only the matching steps" do
        api_users = filtered.find { |b| b[:name] == "api/users" }
        api_posts = filtered.find { |b| b[:name] == "api/posts" }

        expect(api_users[:steps].size).to eq(1)
        expect(api_users[:steps][0][:name]).to eq("Get user")
        expect(api_posts[:steps].size).to eq(1)
        expect(api_posts[:steps][0][:name]).to eq("Get post")
      end
    end
  end

  context "when both tags and skip_tags are provided" do
    context "with tags to include and skip_tags to exclude" do
      let(:tags) { ["crud"] }
      let(:skip_tags) { ["write"] }

      it "is expected to first filter by tags, then exclude by skip_tags" do
        # Only api/users and api/posts have "crud" tag
        # Then "write" steps are removed
        expect(filtered.size).to eq(2)
        expect(filtered.map { |b| b[:name] }).to contain_exactly("api/users", "api/posts")
      end

      it "is expected to keep only steps that match tags and don't match skip_tags" do
        api_users = filtered.find { |b| b[:name] == "api/users" }
        api_posts = filtered.find { |b| b[:name] == "api/posts" }

        # Only "Get user" and "Get post" remain (have crud, don't have write)
        expect(api_users[:steps].size).to eq(1)
        expect(api_users[:steps][0][:name]).to eq("Get user")
        expect(api_posts[:steps].size).to eq(1)
        expect(api_posts[:steps][0][:name]).to eq("Get post")
      end
    end

    context "when skip_tags would remove everything after tag filtering" do
      let(:tags) { ["login"] }
      let(:skip_tags) { ["login"] }

      it "is expected to return no blueprints" do
        expect(filtered).to be_empty
      end
    end

    context "with overlapping tag and skip_tag criteria" do
      let(:tags) { ["api"] }
      let(:skip_tags) { ["read"] }

      it "is expected to apply skip_tags after tag filtering" do
        api_users = filtered.find { |b| b[:name] == "api/users" }
        api_posts = filtered.find { |b| b[:name] == "api/posts" }

        # All api steps matched, then read steps removed
        expect(api_users[:steps].size).to eq(2)
        expect(api_users[:steps].map { |s| s[:name] }).to contain_exactly("Create user", "Delete user")
        expect(api_posts[:steps].size).to eq(1)
        expect(api_posts[:steps][0][:name]).to eq("Create post")
      end
    end
  end

  context "when all three filters are provided" do
    context "with path, tags, and skip_tags all active" do
      let(:path) { fixtures_path.join("blueprints", "api") }
      let(:tags) { ["crud"] }
      let(:skip_tags) { ["write"] }

      it "is expected to apply path filter first" do
        # Only api blueprints remain
        expect(filtered.all? { |b| b[:name].start_with?("api/") }).to be true
      end

      it "is expected to apply tags filter second" do
        # All remaining steps have crud tag
        filtered.each do |blueprint|
          expect(blueprint[:steps].all? { |s| s[:tags].include?("crud") }).to be true
        end
      end

      it "is expected to apply skip_tags filter third" do
        # No steps with write tag remain
        filtered.each do |blueprint|
          expect(blueprint[:steps].none? { |s| s[:tags].include?("write") }).to be true
        end
      end

      it "is expected to remove empty blueprints after all filters" do
        # Only blueprints with remaining steps
        expect(filtered.size).to eq(2)
        expect(filtered.all? { |b| b[:steps].any? }).to be true
      end
    end

    context "with filters that result in no matches" do
      let(:path) { fixtures_path.join("blueprints", "auth") }
      let(:tags) { ["crud"] }
      let(:skip_tags) { ["api"] }

      it "is expected to return an empty array" do
        # auth blueprints don't have crud tags
        expect(filtered).to be_empty
      end
    end

    context "with filters that match a subset" do
      let(:path) { fixtures_path.join("blueprints", "api", "users.yml") }
      let(:tags) { ["crud"] }
      let(:skip_tags) { ["write"] }

      it "is expected to return only the matching subset" do
        expect(filtered.size).to eq(1)
        expect(filtered[0][:name]).to eq("api/users")
        expect(filtered[0][:steps].size).to eq(1)
        expect(filtered[0][:steps][0][:name]).to eq("Get user")
      end
    end
  end

  context "when no filters are provided" do
    it "is expected to return all blueprints unchanged" do
      expect(filtered.size).to eq(5)
    end

    it "is expected to keep all steps in all blueprints" do
      expect(filtered[0][:steps].size).to eq(2)
      expect(filtered[1][:steps].size).to eq(2)
      expect(filtered[2][:steps].size).to eq(3)
      expect(filtered[3][:steps].size).to eq(2)
      expect(filtered[4][:steps].size).to eq(2)
    end
  end

  context "when empty blueprints exist after filtering" do
    let(:tags) { ["nonexistent"] }

    it "is expected to remove blueprints with no remaining steps" do
      expect(filtered).to be_empty
    end
  end
end
