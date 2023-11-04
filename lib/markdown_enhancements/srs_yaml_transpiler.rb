class SRSYAMLTranspiler
  def self.yaml_to_markdown(yaml_obj, markdown_string)

    # TODO: condititionals for different types
    
    # The following addresses mapping one anchor tagged element to multiple others.
    # TODO: address uniqueness problem of HTML anchor tags
    # TODO: address punctuation lossy-ness issue
    # TODO: break out into its own method
    md_str = markdown_string
    yaml_obj.each do |k, v|
      val = yaml_obj[k]
      if k.eql? "title"
        md_str += "# #{val}\n"
        md_str += "\n"
      elsif k.eql? "comments"
        md_str += "#{val}\n"
      elsif k.eql? "mapping"
        md_str += "\n"
        val.each do |mapping_obj|
          mapping_obj.each do |map_obj_k, map_obj_v|
            mapping_object_md = "- [#{map_obj_k}](##{map_obj_k.downcase.gsub(" ", "-")})\n"
            md_str += mapping_object_md
            map_obj_v.each do |map_obj_v_elem|
              mapping_object_md = "  - [#{map_obj_v_elem}](##{map_obj_v_elem.downcase.gsub(" ", "-")})\n"
              md_str += mapping_object_md
            end
          end
        end
      end
    end
    md_str
  end
end
