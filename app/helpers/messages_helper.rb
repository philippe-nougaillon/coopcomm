module MessagesHelper
  def format_message_date(date)
    if date.today?
      "Aujourd'hui"
    elsif date.yesterday?
      "Hier"
    elsif date > 7.days.ago
      l(date, format: "%A") # Ej: "Lundi"
    elsif date.year == Date.current.year
      l(date, format: "%a %d %b")                # "mer. 19 août"
    else
      l(date, format: "%a %d %b %Y")             # "sam. 16 janv. 2026"
    end
  end
end