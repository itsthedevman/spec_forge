# frozen_string_literal: true

module SpecForge
  class Normalizer
    module Definition
      STRUCTURE = {
        type: {
          type: [String, Array],
          default: nil,
          validator: :present?
        },
        label: {
          type: String,
          default: nil
        },
        default: {
          type: [String, NilClass, Numeric, Array, Hash, TrueClass, FalseClass],
          default: nil
        },
        aliases: {
          type: Array,
          default: [],
          structure: {type: String}
        },
        structure: {
          type: Hash,
          default: {}
        },
        validator: {
          type: String,
          default: nil
        },
        reference: {
          type: String,
          default: nil,
          validator: :present?
        }
      }.freeze

      private

      #
      # @api private
      #
      def define
        @normalizers = load_from_files
        structures = @normalizers.delete(:_shared).stringify_keys

        @normalizers.each do |normalizer_name, structure|
          structure.transform_values!.with_key do |attribute, key|
            case attribute
            when String, Array
              hash = default(structure: STRUCTURE)
              hash[:type] = resolve_type(attribute)
              hash
            when Hash
              # A reference replaces the entire hash
              if (name = attribute.delete(:reference))
                reference = structures[name] || @normalizers[name]

                if reference.nil?
                  structures_names = (structures.keys + @normalizers.keys)
                    .map(&:in_quotes)
                    .to_or_sentence

                  raise Error, "Invalid reference name. Got #{name&.in_quotes}, expected one of #{structures_names}"
                end

                attribute = reference.merge(attribute)
              end

              hash = raise_errors! do
                new(
                  "#{key.in_quotes} in normalizer/#{normalizer_name}.yml",
                  attribute,
                  structure: STRUCTURE
                ).normalize
              end

              hash[:type] = resolve_type(hash[:type])
              hash
            else
              raise ArgumentError,
                "Invalid normalizer attribute. Expected String or Hash, got #{attribute.inspect}"
            end
          end
        end
      end

      def resolve_type(type)
        if type == "boolean"
          [TrueClass, FalseClass]
        elsif type.instance_of?(Array)
          type.map { |t| resolve_type(t) }
        else
          type.classify.constantize
        end
      end

      #
      # @api private
      #
      def load_from_files
        base_path = Pathname.new(File.expand_path("../normalizers", __dir__))
        paths = Dir[base_path.join("**/*.yml")].sort

        paths.each_with_object({}) do |path, hash|
          name = Pathname.new(path).relative_path_from(base_path).basename(".yml").to_s.to_sym
          yaml = YAML.safe_load_file(path, symbolize_names: true)
          raise Error, "Content in #{path} is invalid or empty" if yaml.blank?

          hash[name] = yaml
        end
      end
    end
  end
end
