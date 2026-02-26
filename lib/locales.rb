# frozen_string_literal: true

require 'i18n'
require 'i18n/backend/fallbacks'

# TODO: 25-02-25: This is lifted from https://github.com/RaspberryPiFoundation/aws-lambdas/blob/dca3894a81f8e1a83aa939a91a948b198e6e70a4/projects-build/lib/locales.rb, this should be centralised (perhaps as a gem) and both places updated to utilise it.
class Locales
  class << self
    def load_locales
      I18n::Backend::Simple.include I18n::Backend::Fallbacks
      two_letter_locales = %i[
        en
      ]

      four_letter_locales = %i[
        af-ZA am-ET ar-SA az-AZ bg-BG bn-BD bn-IN ca-ES cs-CZ cy-GB da-DK de-DE el-GR es-ES es-LA et-EE fa-IR fi-FI fil-PH fr-CA
        fr-FR ga-IE gd-GB gu-IN ha-HG he-IL hi-IN hr-HR hu-HU id-ID ig-NG it-IT ja-JP kn-IN ko-KR lv-LV me-ME ml-IN mn-MN mr-IN ms-MY mt-MT my-MM ne-NP nl-NL no-NO pl-PL ps-AF pt-BR
        pt-PT ro-RO ru-RU sh-ZW si-LK sk-SK sl-SI so-SO sq-AL sr-SP sv-SE sw-KE ta-IN te-IN th-TH tr-TR tt-RU uk-UA ur-PK vi-VN vls-BE xh-ZA zh-CN zh-TW
      ]
      I18n.default_locale = :en
      I18n.available_locales = two_letter_locales + four_letter_locales
    end
  end
end
