require "test/unit"
require "fileutils"

require_relative "../lib/srs_initialization"
require_relative "../lib/srs_builder"
require_relative "../lib/srsgem_project"
require_relative "../lib/logit"
require_relative "../lib/srs_id_manager"
require "yaml"
require "json"

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
    assert_true(File.exist?("#{tmp_proj_dir_name}/.srsgem/ids.json"))
    FileUtils.remove_dir(tmp_proj_dir_name)
  end

  def test_srs_build_number_functions_in_dotsrsgem_dir
    tmp_proj_dir_name = 'tmp_build_num_proj'
    SRSInitialization.new.init_bare_srsgem_dir(tmp_proj_dir_name)

    Dir.chdir(tmp_proj_dir_name) do
      build_number_path = SRSGemProject.file_path('build-number.yml')
      initial_number = YAML.load_file(build_number_path)['last_build']['number'].to_i

      SRSBuilder.new.update_build_num_and_timestamp

      updated_number = YAML.load_file(build_number_path)['last_build']['number'].to_i
      assert_equal(initial_number + 1, updated_number)
    end
  ensure
    FileUtils.remove_dir(tmp_proj_dir_name) if Dir.exist?(tmp_proj_dir_name)
  end

  def test_srs_build_log_can_log_from_within_dotsrsgem_dir
    tmp_proj_dir_name = 'tmp_build_log_proj'
    SRSInitialization.new.init_bare_srsgem_dir(tmp_proj_dir_name)

    Dir.chdir(tmp_proj_dir_name) do
      LogIt.log_it('test build log entry')

      log_path = SRSGemProject.file_path('build.log')
      assert_true(File.exist?(log_path))
      assert_match(/test build log entry/, File.read(log_path))
      assert_false(File.exist?('build.log'))
    end
  ensure
    FileUtils.remove_dir(tmp_proj_dir_name) if Dir.exist?(tmp_proj_dir_name)
  end

  def test_srs_initialization_creates_adr_appendix_template
    tmp_proj_dir_name = 'tmp_adr_appendix_proj'
    srs_init_obj = SRSInitialization.new
    srs_init_obj.init_bare_srsgem_dir(tmp_proj_dir_name)

    appendix_path = "#{tmp_proj_dir_name}/018-appendix-C-architectural-decision-records.md"
    references_path = "#{tmp_proj_dir_name}/019-references.md"

    assert_true(File.exist?(appendix_path))
    assert_true(File.exist?(references_path))

    appendix_contents = File.read(appendix_path)
    assert_match(/Appendix C\. Architectural Decision Records/, appendix_contents)
    refute_match(/^# ADR-/m, appendix_contents)

    FileUtils.remove_dir(tmp_proj_dir_name)
  end

  def test_srs_initialization_creates_adr_directory_structure
    tmp_proj_dir_name = 'tmp_adr_dirs_proj'
    srs_init_obj = SRSInitialization.new
    srs_init_obj.init_bare_srsgem_dir(tmp_proj_dir_name)

    SRSInitialization::ADR_STATUS_FOLDERS.each do |status|
      assert_true(Dir.exist?("#{tmp_proj_dir_name}/ADRs/#{status}"))
    end

    starter_adr_path = "#{tmp_proj_dir_name}/ADRs/proposed/#{SRSInitialization::STARTER_ADR_FILENAME}"
    assert_true(File.exist?(starter_adr_path))
    assert_match(/## ADR-001:/, File.read(starter_adr_path))

    FileUtils.remove_dir(tmp_proj_dir_name)
  end

  def test_srs_id_manager_persists_counters_in_dotsrsgem_dir
    tmp_proj_dir_name = 'tmp_id_counters_proj'
    SRSInitialization.new.init_bare_srsgem_dir(tmp_proj_dir_name)

    Dir.chdir(tmp_proj_dir_name) do
      # Fresh project should have 0 for all prefixes
      assert_equal(0, SRSIdManager.last_number("BR"))
      assert_equal(0, SRSIdManager.last_number("ADR"))
      assert_equal(0, SRSIdManager.last_number("DIAG"))

      # next_id should return formatted string and increment
      first_br = SRSIdManager.next_id("BR")
      assert_equal("BR-1", first_br)
      assert_equal(1, SRSIdManager.last_number("BR"))

      second_br = SRSIdManager.next_id("BR")
      assert_equal("BR-2", second_br)
      assert_equal(2, SRSIdManager.last_number("br")) # case insensitive prefix

      # Different prefix
      first_adr = SRSIdManager.next_id("ADR")
      assert_equal("ADR-1", first_adr)

      # Verify file persisted correctly
      ids_path = SRSGemProject.file_path("ids.json")
      loaded = JSON.parse(File.read(ids_path))["last_ids"]
      assert_equal(2, loaded["BR"])
      assert_equal(1, loaded["ADR"])

      # Also test set_last (for future bootstrap use)
      SRSIdManager.set_last("TS", 42)
      assert_equal(42, SRSIdManager.last_number("TS"))
      assert_equal("TS-43", SRSIdManager.next_id("TS"))

      # Test the new verbatim header recording (for linter drift detection)
      # Data is now under headers_by_prefix with sub-dicts containing prefix/full_name/ids array
      ids_path = SRSGemProject.file_path("ids.json")
      data = JSON.parse(File.read(ids_path))
      assert_true(data.key?("headers_by_prefix"))
      hbp = data["headers_by_prefix"]
      assert_true(hbp.key?("BR"))
      assert_equal([], hbp["BR"]["ids"])

      # Record a header binding (as assigner does). Should only record first time.
      SRSIdManager.record_header_for_id("BR-5", "The system shall do something important")
      data = JSON.parse(File.read(ids_path))
      br_group = data["headers_by_prefix"]["BR"]
      br5_entry = br_group["ids"].find { |e| e["id"] == "BR-5" }
      assert_equal("The system shall do something important", br5_entry["header"])
      # last_ids should also have been bumped as side effect
      assert_equal(5, data["last_ids"]["BR"])

      # Calling again with different text must NOT overwrite (preserves original)
      SRSIdManager.record_header_for_id("BR-5", "CHANGED HEADER TEXT - should be ignored")
      data = JSON.parse(File.read(ids_path))
      br_group = data["headers_by_prefix"]["BR"]
      br5_entry = br_group["ids"].find { |e| e["id"] == "BR-5" }
      assert_equal("The system shall do something important", br5_entry["header"])

      # New ID records fine
      SRSIdManager.record_header_for_id("ADR-2", "Use MADR format")
      data = JSON.parse(File.read(ids_path))
      adr_group = data["headers_by_prefix"]["ADR"]
      adr2_entry = adr_group["ids"].find { |e| e["id"] == "ADR-2" }
      assert_equal("Use MADR format", adr2_entry["header"])
    end
  ensure
    FileUtils.remove_dir(tmp_proj_dir_name) if Dir.exist?(tmp_proj_dir_name)
  end

end

