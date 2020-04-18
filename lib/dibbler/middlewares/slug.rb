# *****************************************************************************
# * Copyright (c) 2019 Matěj Outlý
# *****************************************************************************
# *
# * Request translation based on DB slugs
# *
# * Author: Matěj Outlý
# * Date  : 21. 7. 2015
# *
# *****************************************************************************

module Dibbler
  module Middlewares
    class Slug

      def initialize(app)
        @app = app
      end

      def call(env)
        if filter(env)
          @app.call(env)
        else

          # Match locale from path
          locale, translation = Dibbler.disassemble(env["PATH_INFO"])

          # Translate to original and modify request
          original = Dibbler.slug_model.translation_to_original(I18n.locale, translation) # Previously matched locale used
          unless original.nil?
            original = Dibbler.assemble(locale, original)
            env["REQUEST_PATH"] = original
            env["PATH_INFO"] = original
            env["REQUEST_URI"] = original + "?" + env["QUERY_STRING"]
          end
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