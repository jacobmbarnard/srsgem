require "test/unit"
require "fileutils"

require_relative "../lib/srs_initialization"

require_relative "srs_header_counter_tests"

class TestAdd < Test::Unit::TestCase
  def test_srs_initialization_create_empty_file_in_dir
    #ensure clean
    init_object = SRSInitialization.new
    assert_false(File.exists?("empty_file.md"))

    #perform primary test
    init_object.create_empty_file_in_srs_dir("empty_file.md")
    assert_true(File.exists?("empty_file.md"))
    contents = File.open("empty_file.md", "r").read
    assert_equal(contents, "")

    #clean up
    FileUtils.remove("empty_file.md")
    assert_false(File.exists?("empty_file.md"))
  end

  def test_populate_file_with_contents
    # REMEMBER! To close File objects, or else
    # reads and such will mess up...

    #ensure clean
    init_object = SRSInitialization.new
    assert_false(File.exists?("tmp.md"))

    #peform primary test
    init_object.create_empty_file_in_srs_dir("tmp.md")
    assert_true(File.exists?("tmp.md"))
    file_reader = File.new("tmp.md", "r")
    file_reader_contents = file_reader.read
    assert_equal(file_reader_contents, "")
    file_reader.close

    content_string = "ABC123"
    init_object.populate_file_with_contents("tmp.md", content_string)
    assert_true(File.exists?("tmp.md"))

    modified_file = File.new("tmp.md", "r")
    modified_file_contents = modified_file.read
    modified_file.close

    result = content_string == modified_file_contents
    assert_true(result)

    #clean up
    FileUtils.remove("tmp.md")
    assert_false(File.exists?("tmp.md"))
  end
end
