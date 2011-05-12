# http://railscasts.com/episodes/206-action-mailer-in-rails-3

ActionMailer::Base.smtp_settings = {
  :address => 'smtp.gmail.com',
  :port => 587,
  :domain => 'phenomix.org',
  :user_name => 'diapriid',
  :password => 'secret',
  :enable_starttls_auto => true
}

# ActionMailer::Base.password_reminder_options[:host] => "localhost:3000"

