# *****************************************************************************
# * Copyright (c) 2019 Matěj Outlý
# *****************************************************************************
# *
# * Enum definition
# *
# * Author: Matěj Outlý
# * Date  : 7. 1. 2015
# *
# *****************************************************************************

require "active_record"

module Dibbler
  module Utils
    module Enum
      extend ActiveSupport::Concern

      module ClassMethods

        # Add new enum column
        def enum_column(new_column, spec, options = {})

          # Prepare internal structure
          if @enums.nil?
            @enums = {}
          end
          @enums[new_column] = {}

          # Fill out internal structure
          spec.each do |item|

            # Value check
            if item.is_a?(OpenStruct)
              item = item.to_h
            elsif item.is_a? Hash
              # OK
            else
              item = {value: item}
            end
            unless item[:value]
              raise "Enum definition cannot be empty."
            end

            # Identify special type
            item[:special_type] = :integer if item[:value].is_a?(Integer)

            # Retype to string
            item[:value] = item[:value].to_s

            # Label
            unless item[:label]
              item[:label] = I18n.t("activerecord.attributes.#{model_name.i18n_key}.#{new_column.to_s}_values.#{item[:special_type] ? item[:special_type].to_s + "_" : ""}#{item[:value]}")
            end

            # Other attributes
            if options[:attributes]
              options[:attributes].each do |attribute|
                singular_attribute_name = attribute.to_s.singularize
                plural_attribute_name = attribute.to_s.pluralize
                if item[singular_attribute_name.to_sym].nil?
                  item[singular_attribute_name.to_sym] = I18n.t("activerecord.attributes.#{model_name.i18n_key}.#{new_column.to_s}_#{plural_attribute_name}.#{item[:special_type] ? item[:special_type].to_s + "_" : ""}#{item[:value]}")
                end
              end
            end

            # Store
            @enums[new_column][item[:value].to_s] = OpenStruct.new(item)
          end

          # Obj method
          define_method((new_column.to_s + "_obj").to_sym) do
            column = new_column

            # Get map Value => Object
            enums = self.class.enums[column]

            # Get possible special type
            special_type = enums.values.first.special_type if enums.first && enums.values.first.special_type

            # Get value and modify it according to special type
            value = self.send(column)
            value = value.to_i if special_type == :integer

            return self.class.enums[column][value.to_s]
          end

          # All method
          define_singleton_method(("available_" + new_column.to_s.pluralize).to_sym) do
            column = new_column
            return @enums[column].values
          end

          # All values method
          define_singleton_method(("available_" + new_column.to_s + "_values").to_sym) do
            column = new_column
            return @enums[column].values.map { |o| o.value.to_sym }
          end

          # Label method
          define_singleton_method((new_column.to_s + "_label").to_sym) do |value|
            column = new_column
            return @enums[column].values.select { |o| o.value.to_s == value.to_s }.map { |o| o.label }.first
          end

          # Default value
          if options[:default]
            before_validation do
              column = new_column
              default = options[:default]
              if self.send(column).nil?
                self.send(column.to_s + "=", default.to_s)
              end
            end
          end

        end

        # Get all defined enums
        def enums
          @enums
        end

        # Check if given column is enum defined on this model
        def has_enum?(column)
          !@enums.nil? && !@enums[column].nil?
        end

      end

    end
  end
end
