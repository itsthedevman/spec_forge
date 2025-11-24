# frozen_string_literal: true

module SpecForge
  class Loader
    class StepProcessor
      def initialize(blueprints, tags: [], skip_tags: [])
        @blueprints = blueprints
        @tags = tags
        @skip_tags = skip_tags
      end

      def run
        @blueprints.each do |name, blueprint|
          blueprint[:steps] = prepare_steps(blueprint)
            .then { |s| expand_steps(s) }
          # .then { |s| tag_steps(s) }
          # .then { |s| normalize_steps(s) }
        end
      end

      private

      def prepare_steps(blueprint)
        blueprint[:steps].map do |step|
          step[:source] = {file_name: blueprint[:name], line_number: step.delete(:line_number)}
          step
        end
      end

      def expand_steps(steps)
        return if steps.blank?

        output_steps = []

        steps.each do |step|
          # Included blueprint steps replace the current step
          if (names = step[:include]) && names.size > 0
            output_steps += load_included_steps(step, names)
          else
            output_steps << step
          end

          step[:steps] = expand_steps(step[:steps]) if step[:steps]
        end

        output_steps
      end

      def load_included_steps(step, names)
        names = normalize_included_step_names(
          names,
          label: "\"include\" in #{step[:source][:file_name]}:#{step[:source][:line_number]}"
        )

        names.flat_map do |name|
          blueprint = @blueprints[name]

          if blueprint.nil?
            raise Error, <<~STRING
              Blueprint #{name.in_quotes} not found
              Referenced in: #{step[:source][:file_name]}:#{step[:source][:line_number]}

              Available blueprints: #{@blueprints.keys.join_map(", ", &:in_quotes)}
            STRING
          end

          blueprint[:steps]
        end
      end

      def normalize_included_step_names(names, label:)
        Normalizer.normalize!(
          {include: names},
          label:,
          using: {
            include: {
              type: [String, Array],
              default: [],
              modifier: proc do |value|
                Array(value).map! { |name| name.delete_suffix(".yml").delete_suffix(".yaml") }
              end
            }
          }
        )[:include]
      end

      def tag_steps(steps, parent_tags: [])
        steps.each do |step|
          step[:tags] = (parent_tags + step[:tags]).uniq

          tag_steps(step[:steps], parent_tags: step[:tags])
        end
      end

      def normalize_steps(steps)
        steps.map do |step|
          Normalizer.normalize!(step, using: :step)
        rescue => e
          raise Error::LoadStepError.new(e, step)
        end
      end
    end
  end
end
