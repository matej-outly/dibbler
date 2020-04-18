# *****************************************************************************
# * Copyright (c) 2019 Matěj Outlý
# *****************************************************************************
# *
# * Linear slug generator
# *
# * Author: Matěj Outlý
# * Date  : 21. 7. 2015
# *
# *****************************************************************************

module Dibbler
  module Models
    module SlugGenerator
      extend ActiveSupport::Concern

      included do

        after_save :generate_slugs
        before_destroy :destroy_slugs, prepend: true

      end

      module ClassMethods

        def generate_slugs(options = {})
          self.all.each do |item|
            item.generate_slugs(options)
          end
        end

      end

      def disable_slug_generator
        @disable_slug_generator = true
      end

      def enable_slug_generator
        @disable_slug_generator = false
      end

      # *************************************************************
      # Hooks
      # *************************************************************

      def generate_slugs(options = {})
        return if @disable_slug_generator
        ActiveRecord::Base.transaction do

          # Generate slug in this model
          unless Dibbler.slug_model.nil?
            I18n.available_locales.each do |locale|
              self._destroy_slug_was(Dibbler.slug_model, locale)
              self._generate_slug(Dibbler.slug_model, locale)
            end
          end

        end
      end

      def destroy_slugs(options = {})

        # Destroy slug of this model
        unless Dibbler.slug_model.nil?
          I18n.available_locales.each do |locale|
            self._destroy_slug(Dibbler.slug_model, locale)
          end
        end

      end

      def url_original
        if @url_original.nil?
          @url_original = self._url_original
        end
        @url_original
      end

      def compose_slug_translation(locale)
        self._compose_slug_translation(locale)
      end

      protected

      # *************************************************************
      # Callbacks to be defined in application
      # *************************************************************

      def _url_original
        raise "To be defined in application."
      end

      def _compose_slug_translation(locale)
        raise "To be defined in application."
      end

      def _generate_slug(slug_model, locale)
        raise "To be defined in application."
      end

      def _destroy_slug(slug_model, locale)
        raise "To be defined in application."
      end

      def _destroy_slug_was(slug_model, locale)
        raise "To be defined in application."
      end

    end
  end
end
