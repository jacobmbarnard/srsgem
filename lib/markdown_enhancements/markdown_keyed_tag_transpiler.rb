class MarkdownKeyedTagTranspiler

  # @param rgx [Regexp] regular expression used to match
  def initialize(content_rgx_str = ".+", ky = "MarkdownKeyedTagTranspiler", pfx = "", sfx = "", tgn = "tagname", clnm = "class-name")
    @content_regex = rgx_str
    @key = ky
    @prefix = pfx
    @suffix = sfx
    @tag_name = tgn
    @class_name = clnm
  end

  def all_matches(string)
    modded_str = "\\[#{@content_regex}\\]\\(#{@key}\\)"
    r = Regexp.new(modded_str)
    string.enum_for(:scan, r).map { Regexp.last_match }
  end

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
