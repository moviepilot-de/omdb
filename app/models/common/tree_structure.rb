module TreeStructure
  
  def all_ordered_children( lang = Locale.base_language )
    objects = []
    self.ordered_children( lang ).each { |child|
      objects << child
      objects << child.all_ordered_children unless child.children.empty?
    }
    objects.flatten
  end
  
  def all_children
    objects = []
    self.children.each { |child|
        objects << child
        objects << child.all_children unless child.children.empty?
    }
    objects.flatten
  end

  def all_children_ids
    all_children.collect { |c| c.id }
  end

  def ordered_children( lang = Locale.base_language )
    self.children
  end
  
  def objects_to_root
    ancestors.reverse << self
  end
  
  def root_id
    self.root.id
  end

end
