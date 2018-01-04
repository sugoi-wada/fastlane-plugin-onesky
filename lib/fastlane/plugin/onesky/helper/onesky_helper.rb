module Fastlane
  module Helper
    class OneskyHelper
      # class methods that you define here become available in your action
      # as `Helper::OneskyHelper.your_method`
      #
      def self.show_message
        UI.message("Hello from the onesky plugin helper!")
      end

      def self.normalize(locale)
        locale.gsub('zh-TW', 'zh-Hant')
      end
    end
  end
end
