# *****************************************************************************
# * Copyright (c) 2019 Matěj Outlý
# *****************************************************************************
# *
# * Slug
# *
# * Author: Matěj Outlý
# * Date  : 21. 7. 2015
# *
# *****************************************************************************

module Dibbler
  module Models
    module Slug
      extend ActiveSupport::Concern

      module ClassMethods

        # Clear slug cache. Must be done if data changed in DB
        def clear_cache
          @o2t = nil
          @t2o = nil
        end

        # Load specific locale to cache
        def load_cache(locale)

          # Initialize cache structures
          @o2t = {} if @o2t.nil?
          @t2o = {} if @t2o.nil?

          # Fill cache if empty
          if @o2t[locale.to_sym].nil? || @t2o[locale.to_sym].nil?

            # Preset
            @o2t[locale.to_sym] = {}
            @t2o[locale.to_sym] = {}

            # Static data from config
            if Dibbler.static_slugs
              Dibbler.static_slugs.each do |item|
                if item[:locale].to_s == locale.to_s
                  translation_as_key = item[:translation]
                  translation_as_key = translation_as_key.downcase if Dibbler.downcase_translations == true
                  if Dibbler.use_filter
                    if Dibbler.current_app_filter.to_s == item[:filter] # Slug belongs to current application
                      @o2t[locale.to_sym][item[:original]] = item[:translation]
                      @t2o[locale.to_sym][translation_as_key] = item[:original]
                    elsif !item[:filter].blank? # Slug belongs to other application
                      url = Dibbler.available_filter_urls[item[:filter].to_sym]
                      @o2t[locale.to_sym][item[:original]] = url.trim("/") + item[:translation] unless url.blank?
                    end
                  else
                    @o2t[locale.to_sym][item[:original]] = item[:translation]
                    @t2o[locale.to_sym][translation_as_key] = item[:original]
                  end
                end
              end
            end

            # Dynamic data from DB
            data = where(locale: locale.to_s)
            data.each do |item|
              translation_as_key = item.translation
              translation_as_key = translation_as_key.downcase if Dibbler.downcase_translations == true
              if Dibbler.use_filter
                if Dibbler.current_app_filter.to_s == item.filter # Slug belongs to current application
                  @o2t[locale.to_sym][item.original] = item.translation
                  @t2o[locale.to_sym][translation_as_key] = item.original
                elsif !item.filter.blank? # Slug belongs to other application
                  url = Dibbler.available_filter_urls[item.filter.to_sym]
                  @o2t[locale.to_sym][item.original] = url.trim("/") + item.translation unless url.blank?
                end
              else
                @o2t[locale.to_sym][item.original] = item.translation
                @t2o[locale.to_sym][translation_as_key] = item.original
              end
            end

          end

        end

        # Get translation according to original
        def original_to_translation(locale, original)
          return nil if original.nil?
          load_cache(locale)

          # First priority translation (without IDs)
          result = @o2t[locale.to_sym][original.to_s]
          if result.nil?

            # Ensure single "/" on right
            original = original.rtrim("/") + "/"

            # Create array of all matched IDs alongside with string ":id" (i.e. [["1", ":id"], ["2", ":id"]])
            # Substitute all numeric IDs in original to string ":id"
            matched_ids = []
            product_1 = []
            original = original.gsub(/\/[0-9]+\//) do |matched|
              matched_id = matched[1..-2]
              matched_ids << matched_id
              product_1 << [matched_id, ":id"]
              "/:id/"
            end

            unless product_1.empty?

              # Create product of matched IDs (i.e. [["1", "2"], ["1", ":id"], [":id", "2"], [":id", ":id"]])
              product_2 = product_1.first.product(*product_1[1..-1])

              # Try to find some result for all combinations (except first one, which is already tried and failed)
              result_ids = nil
              product_2[1..-1].each do |combined_ids|

                # IDs missing in this combination
                result_ids = []

                # Generate original according to current combination (i.e. "/nodes/1/photos/:id" or "/nodes/:id/photos/:id")
                index = 0
                product_original = original.gsub(/\/:id\//) do
                  result_ids << matched_ids[index] if combined_ids.first == ":id"
                  index += 1
                  "/#{combined_ids.shift.to_s}/"
                end

                # Remove "/" on right
                product_original = product_original.rtrim("/")

                # Try to translate current combination and break if match found
                result = @o2t[locale.to_sym][product_original.to_s]
                break unless result.nil?

              end

              # Correct result if any
              unless result.nil?

                # Ensure single "/" on right
                result = result.rtrim("/") + "/"

                # Substitute :id to numeric IDS matched from translation
                result = result.gsub(/\/:id\//) do
                  "/#{result_ids.shift.to_s}/"
                end

                # Remove "/" on right
                result = result.rtrim("/")

              end

            end

          end

          result
        end

        # Get original according to translation
        def translation_to_original(locale, translation)
          return nil if translation.nil?
          load_cache(locale)

          # Downcase if necessary
          translation = translation.downcase if Dibbler.downcase_translations

          # First priority translation (without IDs)
          result = @t2o[locale.to_sym][translation.to_s]
          if result.nil?

            # Ensure single "/" on right
            translation = translation.rtrim("/") + "/"

            # Substitute numeric parts to :id
            matched_ids = []
            translation = translation.gsub(/\/[0-9]+\//) do |matched|
              matched_ids << matched[1..-2]
              "/:id/"
            end

            # Remove "/" on right
            translation = translation.rtrim("/")

            # Second priority translation (width IDs)
            result = @t2o[locale.to_sym][translation.to_s]
            unless result.nil?

              # Ensure single "/" on right
              result = result.rtrim("/") + "/"

              # Substitute :id to numeric IDS matched from translation
              result = result.gsub(/\/:id\//) do
                "/#{matched_ids.shift.to_s}/"
              end

              # Remove "/" on right
              result = result.rtrim("/")

            end
          end

          result
        end

        # Add new slug or edit existing
        def add_slug(locale, original, translation, filter = nil, uniquer = "")

          # Do not process blank
          return if original.blank? # || translation.blank? blank translation means that original translates to root

          # Prepare
          locale = locale.to_s
          original = "/" + original.to_s.trim("/")
          translation = "/" + translation.to_s.trim("/")
          not_uniq_translation = "/" + translation.gsub(":uniquer", "").to_s.trim("/")
          if uniquer
            uniq_translation = "/" + translation.gsub(":uniquer", uniquer).to_s.trim("/")
          else
            uniq_translation = not_uniq_translation
          end

          # Root is not slugged
          return if original == "/"

          # Find occupations, if found some, translation must be uniqued with token
          occupations = all
          occupations = occupations.where.not(original: original)
          occupations = occupations.where(locale: locale, translation: not_uniq_translation)
          occupations = occupations.where(filter: filter) if Dibbler.use_filter
          if occupations.count > 0
            translation = uniq_translation
          else
            translation = not_uniq_translation
          end

          # Try to find existing record
          slug = where(locale: locale, original: original).first
          if slug.nil?
            slug = new
          end

          # TODO duplicate translations

          # Save
          slug.locale = locale
          slug.filter = filter if Dibbler.use_filter
          slug.original = original
          slug.translation = translation
          slug.save

          # Clear cache
          clear_cache

        end

        # Remove existing slug if exists
        def remove_slug(locale, original)

          # Prepare
          locale = locale.to_s
          original = "/" + original.to_s.trim("/")

          # Try to find existing record
          slug = where(locale: locale, original: original).first
          unless slug.nil?
            slug.destroy
          end

          # Clear cache
          clear_cache

        end

        # Compose translation from various models
        # Obsolete, please define own translation composition method
        def compose_translation(locale, models)

          # Convert to array
          unless models.is_a? Array
            models = [models]
          end

          # Result
          result = ""
          last_model = nil
          last_model_is_category = false

          models.each do |section_options|

            # Input check
            unless section_options.is_a? Hash
              raise "Incorrect input, expecting hash with :label and :models or :model items."
            end
            if section_options[:models].nil? && !section_options[:model].nil?
              section_options[:models] = [section_options[:model]]
            end
            if section_options[:models].nil? || section_options[:label].nil?
              raise "Incorrect input, expecting hash with :label and :models or :model items."
            end

            # "Is category" option
            last_model_is_category = section_options[:is_category] == true

            section_options[:models].each do |model|

              # Get part
              if model.respond_to?("#{section_options[:label].to_s}_#{locale.to_s}".to_sym)
                part = model.send("#{section_options[:label].to_s}_#{locale.to_s}".to_sym)
              elsif model.respond_to?(section_options[:label].to_sym)
                part = model.send(section_options[:label].to_sym)
              else
                part = nil
              end

              # Add part to result
              result += "/" + part.to_url if part

              # Save last model
              last_model = model

            end

          end

          # Truncate correctly
          unless result.blank?
            if last_model_is_category || (last_model.hierarchically_ordered? && !last_model.leaf?)
              result += "/"
            else
              #result += ".html"
              result += ""
            end
          end

          result
        end

        # *********************************************************
        # Columns
        # *********************************************************

        def permitted_columns
          [
              :locale,
              :original,
              :translation,
              :filter,
          ]
        end

        def filter_columns
          [
              :locale,
              :original,
              :translation,
              :filter,
          ]
        end

        # *********************************************************
        # Scopes
        # *********************************************************

        def filter(params = {})

          # Preset
          result = all

          # Locale
          unless params[:locale].blank?
            if Dibbler.disable_unaccent
              result = result.where("lower(locale) LIKE ('%' || lower(trim(?)) || '%')", params[:locale].to_s)
            else
              result = result.where("lower(unaccent(locale)) LIKE ('%' || lower(unaccent(trim(?))) || '%')", params[:locale].to_s)
            end
          end

          # Original
          unless params[:original].blank?
            if Dibbler.disable_unaccent
              result = result.where("lower(original) LIKE ('%' || lower(trim(?)) || '%')", params[:original].to_s)
            else
              result = result.where("lower(unaccent(original)) LIKE ('%' || lower(unaccent(trim(?))) || '%')", params[:original].to_s)
            end
          end

          # Translation
          unless params[:translation].blank?
            if Dibbler.disable_unaccent
              result = result.where("lower(translation) LIKE ('%' || lower(trim(?)) || '%')", params[:translation].to_s)
            else
              result = result.where("lower(unaccent(translation)) LIKE ('%' || lower(unaccent(trim(?))) || '%')", params[:translation].to_s)
            end
          end

          # Filter
          if Dibbler.use_filter == true
            unless params[:filter].blank?
              if Dibbler.disable_unaccent
                result = result.where("lower(filter) LIKE ('%' || lower(trim(?)) || '%')", params[:filter].to_s)
              else
                result = result.where("lower(unaccent(filter)) LIKE ('%' || lower(unaccent(trim(?))) || '%')", params[:filter].to_s)
              end
            end
          end

          result
        end

      end

    end
  end
end
