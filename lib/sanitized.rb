# encoding: utf-8
module Sanitized
  
  def self.append_features(base)
    base.before_save do |model|
      text_cols = model.class.columns.reject { |col| !col.text? || col.name == model.class.inheritance_column}
      text_cols.each do |c|
        text = model.send(c.name)
        if text and text != (new_text = model.white_list_sanitizer.sanitize(text)) # updated for 2.2
          model.send("#{c.name}=", new_text)
          old_level = model.logger.level
          model.logger.level = Logger::WARN
          model.logger.info "Sanitized input, sending email: [#{text}]"
          SanitizeMailer.report(text, new_text).deliver
          model.logger.level = old_level
        end
      end
    end
  end

end

