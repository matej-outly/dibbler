# *****************************************************************************
# * Copyright (c) 2019 Matěj Outlý
# *****************************************************************************
# *
# * Railtie for view helpers integration
# *
# * Author: Matěj Outlý
# * Date  : 22. 7. 2015
# *
# *****************************************************************************

module Dibbler
  class Railtie < Rails::Railtie
    initializer "dibbler.helpers" do
      ActionView::Base.send :include, Helpers::UrlHelper
    end
  end
end