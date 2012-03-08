class AccountMailer < ActionMailer::Base
  default :from => "mx_admin@#{HOME_SERVER}"
  def password_reset(person, token_url)
    @url = token_url
    mail(:to => "#{person.display_name} <#{person.email}>", :subject => "Password reset for mx @ #{HOME_SERVER}")
  end
  def password_reminder(person)
    @password = person.password
    @change_password_url = "http://#{HOME_SERVER}/account/change_password"
    mail(:to => "#{person.display_name} <#{person.email}>", :subject => "Password reminder for mx @ #{HOME_SERVER}")
  end
end
