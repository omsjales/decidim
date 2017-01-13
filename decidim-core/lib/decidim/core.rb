# frozen_string_literal: true
require "decidim/core/engine"
require "decidim/core/version"

# Decidim configuration.
module Decidim
  autoload :TranslatableAttributes, "decidim/translatable_attributes"
  autoload :FormBuilder, "decidim/form_builder"
  autoload :AuthorizationFormBuilder, "decidim/authorization_form_builder"
  autoload :FilterFormBuilder, "decidim/filter_form_builder"
  autoload :DeviseFailureApp, "decidim/devise_failure_app"
  autoload :FeatureManifest, "decidim/feature_manifest"
  autoload :Features, "decidim/features"

  include ActiveSupport::Configurable

  # Loads seeds from all engines.
  def self.seed!
    # Faker needs to have the `:en` locale in order to work properly, so we
    # must enforce it during the seeds.
    original_locale = I18n.available_locales
    I18n.available_locales = original_locale + [:en] unless original_locale.include?(:en)

    railties = Rails.application.railties.to_a.uniq.select do |railtie|
      railtie.respond_to?(:load_seed) && railtie.class.name.include?("Decidim::")
    end

    railties.each do |railtie|
      puts "Creating #{railtie.class.name} seeds..."
      railtie.load_seed
    end

    Decidim.feature_manifests.each do |feature|
      puts "Creating Feature (#{feature.name}) seeds..."
      feature.seed!
    end

    I18n.available_locales = original_locale
  end

  # Exposes a configuration option: The application name String.
  config_accessor :application_name

  # Exposes a configuration option: The email String to use as sender in all
  # the mails.
  config_accessor :mailer_sender

  # Exposes a configuration option: an Array of `cancancan`'s Ability classes
  # that will be automatically included to the base `Decidim::Ability` class.
  config_accessor :abilities do
    []
  end

  # Exposes a configuration option: an Array of classes that can be used as
  # AuthorizaionHandlers so users can be verified against different systems.
  config_accessor :authorization_handlers do
    []
  end

  # Exposes a configuration option: The application name String.
  config_accessor :available_locales do
    %w(en ca es)
  end

  # Public: Registers a feature, usually held in an external library or in a
  # separate folder in the main repository. Exposes a DSL defined by
  # `Decidim::FeatureManifest`.
  #
  # Feature manifests are held in a global registry and are used in all kinds of
  # places to figure out what new components or functionalities the feature provides.
  #
  # name - A Symbol with the feature's unique name.
  #
  # Returns nothing.
  def self.register_feature(name)
    manifest = FeatureManifest.new(name: name.to_sym)
    yield(manifest)
    manifest.validate!
    feature_manifests << manifest
  end

  # Public: Finds all the registered feature manifest's via the
  # `register_feature` method.
  #
  # Returns an Array[FeatureManifest].
  def self.feature_manifests
    @feature_manifests ||= Set.new
  end

  # Public: Finds a feature manifest by the feature's name.
  #
  # name - The name of the FeatureManifest to find.
  #
  # Returns a FeatureManifest if found, nil otherwise.
  def self.find_feature_manifest(name)
    name = name.to_sym
    feature_manifests.find { |manifest| manifest.name == name }
  end
end
