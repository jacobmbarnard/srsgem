require "test/unit"
require "fileutils"

require_relative "../lib/file_manager"

class FileManagerTests < Test::Unit::TestCase
  def setup
    @tmp_dir = "tmp_file_manager_proj"
    FileUtils.mkdir_p(@tmp_dir)
    FileUtils.mkdir_p(File.join(@tmp_dir, "markdown"))
    FileUtils.mkdir_p(File.join(@tmp_dir, "diagrams", "nested"))
    FileUtils.mkdir_p(File.join(@tmp_dir, ".srsgem"))
    FileUtils.mkdir_p(File.join(@tmp_dir, "output"))
    FileUtils.touch(File.join(@tmp_dir, "001-root.md"))
    FileUtils.touch(File.join(@tmp_dir, "markdown", "002-nested.md"))
    FileUtils.touch(File.join(@tmp_dir, "diagrams", "nested", "003-deep.puml"))
    FileUtils.touch(File.join(@tmp_dir, ".srsgem", "config.yml"))
  end

  def teardown
    FileUtils.remove_dir(@tmp_dir) if Dir.exist?(@tmp_dir)
  end

  def test_project_files_flat_scan
    Dir.chdir(@tmp_dir) do
      files = FileManager.project_files(search_folder: '.', recursive: false)
      assert_equal(["001-root.md"], files)
    end
  end

  def test_project_files_recursive_scan_in_lex_order
    Dir.chdir(@tmp_dir) do
      files = FileManager.project_files(search_folder: '.', recursive: true)
      assert_equal(
        ["001-root.md", "diagrams/nested/003-deep.puml", "markdown/002-nested.md"],
        files
      )
    end
  end

  def test_project_files_excludes_srsgem_and_output
    Dir.chdir(@tmp_dir) do
      files = FileManager.project_files(search_folder: '.', recursive: true)
      refute_includes(files, ".srsgem/config.yml")
      files.each do |file|
        refute_match(%r{\A\.srsgem/}, file)
        refute_match(%r{\Aoutput/}, file)
      end
    end
  end
end