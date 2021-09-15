require 'test/unit'

require_relative '../lib/srs_header_counter'

class TestAdd < Test::Unit::TestCase
  def test_increment
    header_counter = SRSHeaderCounter.new
    assert_true(header_counter.count == 0)
    header_counter.increment_header_count_at_index!(0)
    assert_true(!header_counter.nil?)
    assert_true(header_counter.count == 1)
    assert_true(!header_counter.nil?)
  end

  def test_increment_child
    header_counter = SRSHeaderCounter.new
    assert_true(header_counter.count == 0)
    header_counter.increment_header_count_at_index!(0)
    header_counter.child!.increment_header_count_at_index!(0)
    assert_true(!header_counter.nil?)
    assert_true(header_counter.count == 1)
    assert_true(header_counter.child_or_nil.count == 1)
    header_counter.increment_header_count_at_index!(0)
    assert_true(header_counter.count == 2)
    assert_true(header_counter.child_or_nil.count == 0)
  end

  def test_reset_after_incrementing
    header_counter = SRSHeaderCounter.new
    5.times { header_counter.increment_header_count_at_index!(0) }
    assert_true(header_counter.count == 5)
    header_counter.reset_header!
    assert_true(header_counter.count == 0)
  end

  def test_index_for_markdown_header_matching_hashes_regex
    h1_markdown_string = '# First title'
    depth = SRSHeaderCounter.index_for_markdown_header_matching_hashes_regex(h1_markdown_string)
    assert_true(depth == 0)
    h4_markdown_string = '#### Another title'
    depth = SRSHeaderCounter.index_for_markdown_header_matching_hashes_regex(h4_markdown_string)
    assert_true(depth == 3)
  end

  def test_simple_replaced_with_numbered_header
    h1_markdown_string = '# First title'
    header_counter = SRSHeaderCounter.new
    replacement_string = header_counter.replaced_with_numbered_header(h1_markdown_string)
    assert_true(replacement_string.eql?('# 1. First title'))
  end

  def test_complex_replaced_with_numbered_header
    a =  '# First title'
    b =  '## First subtitle'
    c =  '# Second title'
    d =  '# Third title'
    e =  '## First subtitle'
    f =  '### First subsubtitle'

    header_counter = SRSHeaderCounter.new

    replacement_string = header_counter.replaced_with_numbered_header(a)
    puts("replacement_string is: #{replacement_string}")
    assert_true(replacement_string.eql?('# 1. First title'))

    replacement_string = header_counter.replaced_with_numbered_header(b)
    puts("replacement_string is: #{replacement_string}")
    assert_true(replacement_string.eql?('## 1.1. First subtitle'))

    replacement_string = header_counter.replaced_with_numbered_header(c)
    puts("replacement_string is: #{replacement_string}")
    assert_true(replacement_string.eql?('# 2. Second title'))

    replacement_string = header_counter.replaced_with_numbered_header(d)
    puts("replacement_string is: #{replacement_string}")
    assert_true(replacement_string.eql?('# 3. Third title'))

    replacement_string = header_counter.replaced_with_numbered_header(e)
    puts("replacement_string is: #{replacement_string}")
    assert_true(replacement_string.eql?('## 3.1. First subtitle'))

    replacement_string = header_counter.replaced_with_numbered_header(f)
    puts("replacement_string is: #{replacement_string}")
    assert_true(replacement_string.eql?('### 3.1.1. First subsubtitle'))
  end
end
