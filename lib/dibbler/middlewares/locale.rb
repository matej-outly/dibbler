# *****************************************************************************
# * Copyright (c) 2019 Matěj Outlý
# *****************************************************************************
# *
# * Recognize locale based on request
# *
# * Author: Matěj Outlý
# * Date  : 22. 7. 2015
# *
# *****************************************************************************

module Dibbler
  module Middlewares
    class Locale

      def initialize(app)
        @app = app
      end

      def call(env)
        if filter(env)
          @app.call(env)
        else

          # Match locale from path
          path_locale, path = Dibbler.disassemble(env["PATH_INFO"])
          path_locale = nil unless I18n.available_locales.include?(path_locale)

          # Match locale from browser
          if !Dibbler.disable_browser_locale && env['HTTP_ACCEPT_LANGUAGE']
            browser_locale = env['HTTP_ACCEPT_LANGUAGE'].scan(/^[a-z]{2}/).first
            if browser_locale
              browser_locale = browser_locale.to_sym
              browser_locale = nil unless I18n.available_locales.include?(browser_locale)
            else
              browser_locale = nil
            end
          else
            browser_locale = nil
          end

          # Set as default locale (for paths without locale spec)
          I18n.default_locale = browser_locale if browser_locale

          # Set correct locale and define default locale for URLs
          I18n.locale = path_locale || I18n.default_locale
          Rails.application.routes.default_url_options[:locale] = (I18n.default_locale == I18n.locale ? nil : I18n.locale)

          @app.call(env)
        end
      end

      protected

      def filter(env)
        return true if env["PATH_INFO"].start_with?("/assets/")
        false
      end

    end
  end
end