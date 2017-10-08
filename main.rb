require "fileutils"
require "redcarpet"
require "erb"

class VimwikiMarkdown < Redcarpet::Render::HTML
  # Include a faster rendering method
  include Redcarpet::Render::SmartyPants

  # TODO: Research what these options mean
  def preprocess(document)
    process_links(document)
  end

  def process_links(document)
    document.gsub(/\[\[([^\]]*)\]\]/) do |link|
      match = Regexp.last_match[1]
      make_link(match, match + ".md.html")
    end
  end

  def make_link(text, href)
    "[#{text}](#{href})"
  end
end

class PageTemplate < ERB
  attr_reader :title, :body

  def self.template
    # TODO: Cache this
    File.read("./page.html.erb")
  end

  def initialize(title, body)
    @title = title
    @body = body
    super(self.class.template)
  end

  def result
    super(binding)
  end
end

class VimwikiConverter
  attr_reader :path

  def initialize(input, output)
    @input = File.expand_path(input)
    @output = File.expand_path(output)
    @markdown = Redcarpet::Markdown.new(VimwikiMarkdown, {})
  end

  def process
    # Create the output dir if it does not exist
    FileUtils.mkdir_p(@output) unless Dir.exist?(@output)
    FileUtils.cp_r("./assets", @output)

    files = Dir.entries(@input).select { |e| File.extname(e) == ".md" }
    files.each { |f| process_file(f) }
  end

  def process_file(path)
    full_path = File.join(@input, path)
    file = File.read(full_path)
    output_path = File.basename(path) + ".html"
    output_path = File.join(@output, output_path)

    File.open(output_path, "w") do |output|
      body = @markdown.render(file)
      page = PageTemplate.new(path, body)
      output.puts(page.result)
    end
  end
end

# puts markdown.render("[[aaa link]] [[bbb]]")

converter = VimwikiConverter.new("~/Documents/vimwiki/", "~/Documents/vimwiki_html/")
converter.process


