# encoding: utf-8
module NamespaceHelper
  def namespace_select_tag(object, method)
    select(object, method, Namespace.find(:all, :conditions => {:is_admin_use_only => false}).collect{|n| [n.display_name, n.id]}, {:include_blank => true} ) 
  end
end
