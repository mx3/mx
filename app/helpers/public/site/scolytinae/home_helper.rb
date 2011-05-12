module Public::Site::Scolytinae::HomeHelper
  # don't change the case of values that are already all caps
  def capitalize_conservatively(value)
    value == value.upcase ? value : value.capitalize
  end
  
  def geog_name(geog)
    geog.geog_type_id == 197 ? "#{geog.name} Ocean Islands" : geog.name
  end
end