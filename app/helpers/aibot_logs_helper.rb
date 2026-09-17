# frozen_string_literal: true

module AibotLogsHelper
  # ANSI équivalent à la couleur
  ANSI_COULEURS = {
    '30' => 'text-slate-500', '31' => 'text-red-400', '32' => 'text-green-400', '33' => 'text-yellow-300',
    '34' => 'text-blue-400', '35' => 'text-fuchsia-400', '36' => 'text-cyan-300', '37' => 'text-slate-100',
    '90' => 'text-slate-400', '91' => 'text-red-300', '92' => 'text-green-300', '93' => 'text-yellow-200',
    '94' => 'text-blue-300', '95' => 'text-fuchsia-300', '96' => 'text-cyan-200', '97' => 'text-white'
  }.freeze

  # Permet de mettre en couleur le log de AIBOT (renvoyé avec des couleurs en ANSI)
  def ansi_en_html(texte)
    styles = {}
    morceaux = texte.to_s.split(/(\e\[[\d;]*m)/).filter_map do |morceau|
      if (codes = morceau[/\A\e\[([\d;]*)m\z/, 1])
        appliquer_codes_ansi(styles, codes)
        nil
      elsif morceau.empty? || styles.empty?
        morceau
      else
        content_tag(:span, morceau, class: styles.values.join(' '))
      end
    end

    safe_join(morceaux)
  end

  private

  def appliquer_codes_ansi(styles, codes)
    (codes.split(';').presence || ['0']).each do |code|
      case code
      when '0' then styles.clear
      when '1' then styles[:gras] = 'font-bold'
      when '22' then styles.delete(:gras)
      when '39' then styles.delete(:couleur)
      else styles[:couleur] = ANSI_COULEURS[code] if ANSI_COULEURS.key?(code)
      end
    end
  end
end
