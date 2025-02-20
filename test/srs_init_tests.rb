require "test/unit"
require "fileutils"

require_relative "../lib/srs_initialization"
require_relative "../lib/srs_builder"

require_relative "srs_header_counter_tests"

class TestAdd < Test::Unit::TestCase
  def test_srs_initialization_create_empty_file_in_dir
    #ensure clean
    init_object = SRSInitialization.new
    assert_false(File.exist?("empty_file.md"))

    #perform primary test
    init_object.create_empty_file_in_srs_dir("empty_file.md")
    assert_true(File.exist?("empty_file.md"))
    contents = File.open("empty_file.md", "r").read
    assert_equal(contents, "")

    #clean up
    FileUtils.remove("empty_file.md")
    assert_false(File.exist?("empty_file.md"))
  end

  def test_populate_file_with_contents
    # REMEMBER! To close File objects, or else
    # reads and such will mess up...

    #ensure clean
    init_object = SRSInitialization.new
    assert_false(File.exist?("tmp.md"))

    #peform primary test
    init_object.create_empty_file_in_srs_dir("tmp.md")
    assert_true(File.exist?("tmp.md"))
    file_reader = File.new("tmp.md", "r")
    file_reader_contents = file_reader.read
    assert_equal(file_reader_contents, "")
    file_reader.close

    content_string = "ABC123"
    init_object.populate_file_with_contents("tmp.md", content_string)
    assert_true(File.exist?("tmp.md"))

    modified_file = File.new("tmp.md", "r")
    modified_file_contents = modified_file.read
    modified_file.close

    result = content_string == modified_file_contents
    assert_true(result)

    #clean up
    FileUtils.remove("tmp.md")
    assert_false(File.exist?("tmp.md"))
  end

  def test_srs_initialization_create_dot_srsgem_directory
    tmp_proj_dir_name = 'tmp_new_srsgem_proj'
    srs_init_obj = SRSInitialization.new
    srs_init_obj.init_bare_srsgem_dir(tmp_proj_dir_name)
    assert_true(Dir.exist?("#{tmp_proj_dir_name}/.srsgem"))
    FileUtils.remove_dir(tmp_proj_dir_name)
  end

  def test_srs_initialization_template_files_copied_to_dot_srsgem_directory
    tmp_proj_dir_name = 'tmp_new_srsgem_proj'
    srs_init_obj = SRSInitialization.new
    srs_init_obj.init_bare_srsgem_dir(tmp_proj_dir_name)
    assert_true(File.exist?("#{tmp_proj_dir_name}/.srsgem/config.yml"))
    assert_true(File.exist?("#{tmp_proj_dir_name}/.srsgem/build-number.yml"))
    assert_true(File.exist?("#{tmp_proj_dir_name}/.srsgem/build.log"))
    FileUtils.remove_dir(tmp_proj_dir_name)
  end

  def test_srs_build_number_functions_in_dotsrsgem_dir
    tmp_proj_dir_name = 'tmp_new_srsgem_proj'
    srs_init_obj = SRSInitialization.new
    srs_init_obj.init_bare_srsgem_dir(tmp_proj_dir_name)
    # FileUtils.cd(tmp_proj_dir_name)
    srs_builder = SRSBuilder.new
    FileUtils.remove_dir(tmp_proj_dir_name)
  end

  def test_srs_build_log_can_log_from_within_dotsrsgem_dir
    # TODO: Finish writing me
    tmp_proj_dir_name = 'tmp_new_srsgem_proj'
    srs_init_obj = SRSInitialization.new
    srs_init_obj.init_bare_srsgem_dir(tmp_proj_dir_name)
    FileUtils.remove_dir(tmp_proj_dir_name)
  end

end
