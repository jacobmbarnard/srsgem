require 'counter_container'
require 'homogeneous_descendant_linking_nestable'

# An intelligent counter which can enumerate headers and a subheader.
# Can be used in a recursive fashion (i.e. singly-linked list of
# parent-child counters.)
#
# As far as the parent-child relationship is concerned, there is a
# theoretically infinite index depth permitted. Indexing starts at 0.
#
# As seen in the `initialize` method, the `count` starts a 0; however
# when using `#replaced_with_numbered_header`, the count is pre-incremented
# by 1 for the next header. Thus, while the count starts at zero, for
# markdown header numbering purposes, it effectively starts at 1.
class SRSHeaderCounter
  include CounterContainer
  include HomogeneousDescendantLinkingNestable

  MD_HEADERS_PREFIX_STRINGS = ['#', '##', '###', '####', '#####']
  MD_HEADERS_REGEXES = [/\A#\s/, /\A##\s/, /\A###\s/, /\A####\s/, /\A#####\s/]

  def self.index_for_markdown_header_matching_hashes_regex(string)
    i = 0
    MD_HEADERS_REGEXES.each do |rgx|
      if rgx =~ string
        return i
      end

      i += 1
    end
    nil
  end

  def initialize
    @counter = 0
    @start_val = 0
  end

  # Increments the header object count at the index specified.
  #
  # @param index [Integer] the 0-based index depth descendant
  #        to have its count incremented
  def increment_header_count_at_index!(index)
    c = descendant_at(index)
    c.inc!
    if !c.child_or_nil.nil?
      c.child_or_nil.reset!
    else
      c.child!
    end
  end

  def reset_header!
    reset!
    cutoff!
  end

  def replaced_with_numbered_header(string)
    index = SRSHeaderCounter.index_for_markdown_header_matching_hashes_regex(string)
    return string if index.nil?

    increment_header_count_at_index!(index)
    hsh_pfx = MD_HEADERS_PREFIX_STRINGS[index].dup
    hashes_prefix = MD_HEADERS_PREFIX_STRINGS[index].dup
    header_number = header_number_for_index(index)
    string.gsub(hsh_pfx, "#{hashes_prefix} #{header_number}")
  end

  def header_number_for_index(index)
    h_num = ''
    (0..index).each do |i|
      c = descendant_at(i)
      h_num << "#{c.count}."
    end
    h_num
  end
end
