# frozen_string_literal: true

module MailLogsHelper
  def format_mail_recipients(to_value)
    return '—' if to_value.blank?

    emails = if to_value.is_a?(Array)
               to_value
             elsif to_value.to_s.strip.start_with?('[')
               JSON.parse(to_value.to_s) rescue [to_value]
             else
               to_value.to_s.split(',')
             end

    Array(emails).map(&:strip).reject(&:blank?).join(',<br/>').html_safe
  end
end