class SanitizeMailer < ActionMailer::Base
  
  def report(old_text, new_text)

    content_type "text/html" 

    @recipients         = NOTIFICATION_RECIPIENTS
    @from               = "Sanitize Mailer <error@#{MAIL_SERVER}>"
    @subject            = "[Sanitized] text for project #{$proj_id}, user #{$person_id}" 
    @sent_on            = Time.now
    @body["old"]    = old_text
    @body["new"]     = new_text
  end


end
