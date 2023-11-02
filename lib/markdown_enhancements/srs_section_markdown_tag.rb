require_relative "markdown_keyed_anchor_link_transpiler"

class SRSSectionMarkdownTag < MarkdownKeyedAnchorLinkTranspiler
  def initialize
    @content_regex = "([a-z]|[A-Z]|[0-9]|[-]|_)+([a-z]|[A-Z]|[0-9]|[-]|[_]|\s)*"
    @key = "srs:sctn"
    @prefix = ""
    @suffix = ""
  end
end
