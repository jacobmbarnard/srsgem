# Takes a string in the mould of the familiar Markdown link syntax
# (i.e. `[link text](URI)`) and transpiles it into HTML in a very
# specific way. Instead of the usual URI, a key string is placed
# within the parentheses. The key is a string stored in `@key`, and
# is used for verbatim character matching as part of the overall
# regular expression matching process. The link text remains the
# same after transpiling, but it is also duplicated and converted
# into an anchor link string during transpiling. The anchor link
# is used as the value for `href` in the anchor tag. The value of
# the `href` string is downcased, and spaces are converted to dashes.
#
# Only a Markdown link with the appropriate key URI and content
# conforming to the `@content_regex` will be transpiled into a valid
# HTML anchor tag.
#
# Optionally, a prefix and/or suffix may be specified which will be
# prepended or appended to the transpiled anchor tag `href` value.
#
# **Example:**
#
# With `@content_regex = "(.)+(.|\s)*"`, `@key = 'foo'`, `@prefix = 'foo_'`
# and `@suffix = ''`, a Markdown link `'[Abc 123 Xyz](foo)'` would
# be transpiled into `<a href="#foo_abc-123-xyz">Abc 123 Xyz</a>`.
class MarkdownKeyedAnchorLinkTranspiler

  # @param [Regexp] content_rgx_str expression used to match
  def initialize(content_rgx_str = ".+", ky = "MarkdownKeyedAnchorLink", pfx = "", sfx = "")
    @content_regex = rgx_str
    @key = ky
    @prefix = pfx
    @suffix = sfx
  end

  # Finds substrings that match `@context_regex`.
  #
  # @param [String] string the String in which regex matches are to be found
  # @return an array containing all regex matches in the provided string
  def all_matches(string)
    modded_str = "\\[#{@content_regex}\\]\\(#{@key}\\)"
    r = Regexp.new(modded_str)
    string.enum_for(:scan, r).map { Regexp.last_match }
  end

  # Transpiles the provided Markdown string into HTML based on 
  # values of attributes of `self`. Only substrings of the provided
  # string that match `@contant_regex` will be transpiled.
  #
  # @param [String] string containing the Markdown to be transpiled
  # @return transpiled string
  def transpile(string)
    modded_match = string.dup
    modded_match.gsub!("[", "")
    modded_match.gsub!("]", "")
    modded_match.gsub!("(#{@key})", "")
    match_content = modded_match.dup
    modded_match.gsub!(/\s/, "-")
    modded_match = "<a href=\"\##{@prefix}#{modded_match.downcase}#{@suffix}\">#{match_content}</a>"
    modded_match
  end

  def transpile_matches_in(string)
    str = string.dup
    all_matches(str).each do |m|
      modded_match = transpile(m[0])
      str.gsub!(m[0].dup, modded_match)
    end
    str
  end
end
