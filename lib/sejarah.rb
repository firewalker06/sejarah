require "sejarah/version"
require "thor"
require "octokit"
require "date"

module Sejarah
  class Error < StandardError; end

  class CLI < Thor
    desc "write", "Group releases from repositories by date"
    def write
      @releases = []

      repos.each do |repo|
        pages.times.each do |page_number|
          merged_issues_from(repo, page_number).each do |issue|
            @releases << {
              closed_at: issue.closed_at,
              url: issue.html_url,
              title: issue.title,
              repo: repo
            }
          end
        end
      end

      write_to_file
    end

    private

      attr_accessor :releases

      def write_to_file
        file = File.new("sejarah.md", "w")
        file.write(markdown_texts)
        file.close
      end

      def markdown_texts
        text = []

        releases_by_date.sort_by { |s| s.first }.reverse.each do |date, releases|
          text << "### #{date.to_s}"

          releases.each do |release|
            text << "- [#{release[:closed_at]}] [#{release[:repo]}] [#{release[:title]}](#{release[:url]})"
          end
        end

        text.join("\n")
      end

      def releases_by_date
        releases.group_by do |release|
          release[:closed_at].to_date
        end
      end

      def client
        @_client ||= Octokit::Client.new(access_token: ENV.fetch("GITHUB_ACCESS_TOKEN"))
      end

      def merged_issues_from(repo, page_number)
        client.get("search/issues?q=repo:#{repo}+is:merged&page=#{page_number}").items
      end

      def repos
        ENV.fetch("REPOS").split(",")
      end

      def pages
        ENV.fetch("PAGES", 3).to_i
      end
  end
end
