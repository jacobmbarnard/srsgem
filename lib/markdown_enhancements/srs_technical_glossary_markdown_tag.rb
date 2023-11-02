require_relative "markdown_keyed_anchor_link_transpiler"

class SRSTechnicalGlossaryMarkdownTag < MarkdownKeyedAnchorLinkTranspiler
  def initialize
    @content_regex = "([a-z]|[A-Z]|[0-9]|[-]|_)+([a-z]|[A-Z]|[0-9]|[-]|[_]|\s)*"
    @key = "srs:tterm"
    @prefix = "def_tech_"
    @suffix = ""
  end
end
