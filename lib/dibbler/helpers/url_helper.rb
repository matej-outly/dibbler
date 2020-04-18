# *****************************************************************************
# * Copyright (c) 2019 Matěj Outlý
# *****************************************************************************
# *
# * URL helper
# *
# * Author: Matěj Outlý
# * Date  : 22. 7. 2015
# *
# *****************************************************************************

module Dibbler
  module Helpers
    module UrlHelper

      def localify(path)
        return Dibbler.localify(path)
      end

      def slugify(path)
        return Dibbler.slugify(path)
      end

    end
  end
end
