require "test/unit"
require "fileutils"

require_relative "../lib/markdown_enhancements/srs_section_markdown_tag"

class TestAdd < Test::Unit::TestCase
  # def test_match_multiple_complex
  #   section_markdown_tag = SRSSectionMarkdownTag.new
  #   arr_of_indices = section_markdown_tag.indices_for_srs_section_markdown_tag_regex("A B C  [[]](srs:sctn) 123 [ ](srs:sctn)")
  #   assert_true(arr_of_indices.length == 0)
  # end

  # def test_match_multiple_complex_get_indices
  #   section_markdown_tag = SRSSectionMarkdownTag.new
  #   arr_of_indices = section_markdown_tag.indices_for_srs_section_markdown_tag_regex("A B C  [jae g](srs:sctn) 123 [a-g as](srs:sctn) &amp;")
  #   assert_true(arr_of_indices.length == 2)
  #   assert_true(arr_of_indices[0] == 7)
  #   assert_true(arr_of_indices[1] == 29)
  # end
  
  def test_match_multiple_complex_get_substrings
    section_markdown_tag = SRSSectionMarkdownTag.new
    results = section_markdown_tag.all_matches("A B C  [jae g](srs:sctn) 123 [a-g as](srs:sctn) &amp;")
    puts "results: #{results}"
    assert_true(results.length == 2)
    assert_true(results[0][0].eql? "[jae g](srs:sctn)")
    assert_true(results[1][0].eql? "[a-g as](srs:sctn)")
  end

  def test_match_single_and_convert
    section_markdown_tag = SRSSectionMarkdownTag.new
    results = section_markdown_tag.transpile_matches_in("[abc](srs:sctn)")
    puts "results: #{results}"
    assert_true(results.eql? "<a href=\"\#abc\">abc</a>")
  end

  def test_match_multiple_complex_and_convert
    section_markdown_tag = SRSSectionMarkdownTag.new
    results = section_markdown_tag.transpile_matches_in("A B C  [jae g](srs:sctn) 123 [a-g as](srs:sctn) &amp;")
    puts "results: #{results}"
    assert_true(results.eql? "A B C  <a href=\"\#jae-g\">jae g</a> 123 <a href=\"\#a-g-as\">a-g as</a> &amp;")
  end
end
