require "formalist/element"
require "formalist/types"
require "formalist/validation/collection_rules_compiler"
require "formalist/validation/value_rules_compiler"
require "formalist/validation/predicate_list_compiler"

module Formalist
  class Elements
    class Attr < Element
      permitted_children :all

      attribute :name, Types::ElementName

      attr_reader :value_rules, :value_predicates, :collection_rules, :child_errors

      def initialize(attributes, children, input, rules, errors)
        super

        value_rules_compiler = Validation::ValueRulesCompiler.new(attributes[:name])
        value_predicates_compiler = Validation::PredicateListCompiler.new
        collection_rules_compiler = Validation::CollectionRulesCompiler.new(attributes[:name])

        @input = input.fetch(attributes[:name], {})
        @value_rules = value_rules_compiler.(rules)
        @value_predicates = value_predicates_compiler.(value_rules)
        @collection_rules = collection_rules_compiler.(rules)
        @errors = errors.fetch(attributes[:name], [])[0] || []
        @child_errors = errors[0].is_a?(Hash) ? errors[0] : {}
      end

      def build_child(definition)
        definition.(input, collection_rules, child_errors)
      end

      # Converts the attribute into an array format for including in a
      # form's abstract syntax tree.
      #
      # The array takes the following format:
      #
      # ```
      # [:attr, [params]]
      # ```
      #
      # With the following parameters:
      #
      # 1. Attribute name
      # 1. Validation rules (if any)
      # 1. Validation error messages (if any)
      # 1. Child form elements
      #
      # @example "metadata" attr
      #   attr.to_ast # =>
      #   # [:attr, [
      #   #   :metadata,
      #   #   [
      #   #     [:predicate, [:hash?, []]],
      #   #   ],
      #   #   ["metadata is missing"],
      #   #   [
      #   #     ...child elements...
      #   #   ]
      #   # ]]
      #
      # @return [Array] the attribute as an array.
      def to_ast
        # Errors, if the attr hash is present and its members have errors:
        # {:meta=>[[{:pages=>[["pages is missing"], nil]}], {}]}

        # Errors, if the attr hash hasn't been provided
        # {:meta=>[["meta is missing"], nil]}

        attributes = self.attributes.dup
        name = attributes.delete(:name)

        local_errors = errors[0].is_a?(Hash) ? [] : errors

        [:attr, [
          name,
          type,
          value_predicates,
          local_errors,
          Element::Attributes.new(attributes).to_ast,
          children.map(&:to_ast),
        ]]
      end
    end
  end
end