# *****************************************************************************
# * Copyright (c) 2019 Matěj Outlý
# *****************************************************************************
# *
# * Slug
# *
# * Author: Matěj Outlý
# * Date  : 21. 1. 2016
# *
# *****************************************************************************

module Dibbler
  class Slug < ActiveRecord::Base
    include Dibbler::Utils::Enum
    include Dibbler::Models::Slug
  end
end
