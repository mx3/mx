# The IptRecordController class primarily calls methods in /lib/ipt.rb.
# IptRecords are intended to be write-rarely read-often.
class IptRecordsController < ApplicationController

  def serialize_by_otu
    @otu = Otu.find(params[:id])
    @result = Ipt::Batch.serialize_array(@otu.lots + @otu.specimens)
    flash[:notice] = "Generated #{@result[:valid_count]} records, (#{@result[:invalid_objects].size} failed to be fully parsed- see wiki help for possible reasons why)."
    redirect_to :back
  end

  def serialize_by_ce
    @ce = Ce.find(params[:id])
    @result = Ipt::Batch.serialize_array(@ce.lots + @ce.specimens)
    flash[:notice] = "Generated #{@result[:valid_count]} records, (#{@result[:invalid_objects].size} failed to be fully parsed- see wiki help for possible reasons why)."
    redirect_to :back
  end

  def serialize_by_taxon_name
    @taxon_name = TaxonName.find(params[:id])
    lots = Lot.by_proj(@proj.id).member_of_taxon(@taxon_name)
    specimens = Specimen.by_proj(@proj).with_current_determination_and_member_of_taxon(@taxon_name)
    @result = Ipt::Batch.serialize_array( lots + specimens )
    flash[:notice] = "Generated #{@result[:valid_count]} records, (#{@result[:invalid_objects].size} failed to be fully parsed- see wiki help for possible reasons why)."
    redirect_to :back
  end

  def download_by_taxon_name
    @taxon_name = TaxonName.find(params[:id])
    ids = ([@taxon_name.id] + @taxon_name.children.collect{|t| t.id}).join(",") 
    f = IptRecord.table_csv_string(:conditions => "taxon_name_id in (#{ids})") # conditions is a String, no Hashes
    filename = "TaxonName_#{@taxon_name.id}_occurrence_records.tab"
    send_data(f, :filename => filename, :type => "application/rtf", :disposition => "attachment")
  end

  def download_by_otu
    @otu = Otu.find(params[:id])
    f = IptRecord.table_csv_string(:conditions => "otu_id = #{@otu.id}") # conditions is a String, no Hashes
    filename = "OTU_#{@otu.id}_occurrence_records.tab"
    send_data(f, :filename => filename, :type => "application/rtf", :disposition => "attachment")
  end

  def download_by_ce
    @ce = Ce.find(params[:id])
    f = IptRecord.table_csv_string(:conditions => "ce_id = #{@ce.id}") # conditions is a String, no Hashes
    filename = "CollectinEvent_#{@ce.id}_occurrence_records.tab"
    send_data(f, :filename => filename, :type => "application/rtf", :disposition => "attachment")
  end

end

