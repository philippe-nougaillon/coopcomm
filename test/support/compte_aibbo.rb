# frozen_string_literal: true

# Désigne à l'application le compte d'AÏBBO des fixtures (UUID_AIBOT), et restaure la variable :
# héritée de l'environnement du poste, elle marcherait en local et casserait en CI.
module CompteAibbo
  def self.included(base)
    base.setup do
      @uuid_aibot_avant = ENV.fetch('UUID_AIBOT', nil)
      ENV['UUID_AIBOT'] = users(:AIBBO).id.to_s
    end

    base.teardown do
      ENV['UUID_AIBOT'] = @uuid_aibot_avant
    end
  end
end
