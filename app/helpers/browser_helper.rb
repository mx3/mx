module BrowserHelper
  def is_ie?
    UserAgent.parse(request.user_agent).browser =~ /explorer/i
  end
  def is_chrome?
    UserAgent.parse(request.user_agent).browser =~ /chrome/i
  end
  def is_ffx?
    UserAgent.parse(request.user_agent).browser =~ /firefox/i
  end
end
