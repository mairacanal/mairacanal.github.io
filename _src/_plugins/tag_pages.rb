# Generates a page at /tag/<slug>/ for every tag used across the site,
# rendered with the `tag.html` layout. Without this, the tag links in the
# post header (and the "All tags" list) would point at pages that don't exist.
module Jekyll
  class TagPageGenerator < Generator
    safe true

    def generate(site)
      site.tags.each_key do |tag|
        site.pages << TagPage.new(site, tag)
      end
    end
  end

  class TagPage < PageWithoutAFile
    def initialize(site, tag)
      @site = site
      @base = site.source
      @dir  = File.join("tag", Utils.slugify(tag))
      @name = "index.html"

      process(@name)
      @data = {}
      data["layout"] = "tag"
      data["tag"]    = tag
      data["title"]  = "Tag ##{tag}"
    end
  end
end
