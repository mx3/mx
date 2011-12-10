class ContentType::HislHosts < ContentType

 # THIS IS DEPRECATED AND ONLY INCLUDED HERE AS A STOPGAP

  def self.description
    'Hosts data from customized tables (DEPREACTED)'
  end

  # the partial to render, required for custom types
  def partial
    "/otus/page/hisl_hosts"
  end

  def self.display_name
    'Hosts (deprecated, HISL only)'
  end

  def display_name
    'Hosts (deprecated, HISL only)'
  end

end
