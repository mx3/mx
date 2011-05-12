class SanitizeMailer < ActionMailer::Base
  default :from => "Sanitize Mailer <error@#{MAIL_SERVER}>"
  def report(old_text, new_text)
    @sent_on        = Time.now
    @body["old"]    = old_text
    @body["new"]    = new_text

    mail(:to => ADMIN_EMAIL_RECIPIENTS,
         :subject => "[Sanitized] text for project #{$proj_id}, user #{$person_id}")
  end



end



