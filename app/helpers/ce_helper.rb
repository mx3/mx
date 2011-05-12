# encoding: utf-8
module CeHelper
  def ce_tag(ce)
    s = ''
    s = [ce.geography, ce.locality, ce.lat_long, ce.elevation, ce.date_range, ce.collectors, ce.mthd, ce.display_name(:type => :trip_code), "mx id:#{ce.id}"].reject(&:blank?).join("<br />")
    s = ('<span style="color: red;">' + verbatim_label + '</span>') if s.blank?
    s
  end
end



