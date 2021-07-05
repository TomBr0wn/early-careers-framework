# frozen_string_literal: true

module ApiDocs
  class PropertyListComponent < ViewComponent::Base
    include ApiDocsHelper
    include MarkdownHelper

    attr_reader :properties

    def initialize(properties)
      super

      @properties = properties
    end
  end
end
