require_relative "markdown_keyed_anchor_link_transpiler"

class SRSBusinessGlossaryMarkdownTag < MarkdownKeyedAnchorLinkTranspiler
  def initialize
    @content_regex = "([a-z]|[A-Z]|[0-9]|[-]|_)+([a-z]|[A-Z]|[0-9]|[-]|[_]|\s)*"
    @key = "srs:bterm"
    @prefix = "def_biz_"
    @suffix = ""
  end
end
