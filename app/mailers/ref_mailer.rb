class RefMailer < ActionMailer::Base
  default :from => "ref_notifier@#{HOME_SERVER}"

  def update_notice(ref, diff_hash, recipient, project)    
    @account = recipient.email

    @diff_hash = diff_hash
    @ref = ref
    @recipient_person = recipient
    @project = project

    mail(:to => "#{person.display_name} <#{person.email}>", :subject => "Reference '#{ref.short_citation}' was updated by #{Person.find($person_id).full_name}")
  end

  def taxon_name_notice(new_ref, old_ref, recipient)
    @account = recipient.email
    @new_ref = new_ref
    @old_ref = old_ref
    @recipient_person = recipient
    @updator = Person.find($person_id)

    if new_ref
      subject    "Please verify duplicate reference '#{old_ref.short_citation}'"
    else
      subject    "Please verify deletion of reference '#{old_ref.short_citation}'"
    end

    mail(:to => "#{recipient.display_name} <#{recipient.email}>", :subject => subject)
  end

end
