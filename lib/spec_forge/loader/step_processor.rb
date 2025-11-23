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
        # Each step in each blueprint needs to be tagged, includes expanded, and then steps flattened.
        @blueprints.each do |name, blueprint|
          blueprint[:steps] = expand_steps(blueprint)
          # tag_steps(blueprint[:steps])
        end
      end

      private

      def tag_steps(steps, parent_tags: [])
        steps.each do |step|
          step[:tags] = (parent_tags + step[:tags]).uniq
          tag_steps(step[:steps], parent_tags: step[:tags])
        end
      end

      def expand_steps(blueprint)
        return if blueprint[:steps].blank?

        output_steps = []

        blueprint[:steps].each do |step|
          # Included blueprint steps replace the current step
          if (names = step[:include]) && names.size > 0
            steps = load_included_steps(names)
            output_steps.concat(steps)
          else
            output_steps << step
          end

          expand_steps(step) if step[:steps]
        end

        output_steps
      end

      def normalize_steps(steps)
        steps.map do |step|
          Normalizer.normalize!(step, using: :step)
        rescue => e
          raise Error::LoadStepError.new(e, step)
        end
      end

      def load_included_steps(names)
        names = normalize_included_step_names(
          names,
          label: "TODO - included step: #{names}"
        )

        names.flat_map do |name|
          blueprint = @blueprints[name]

          if blueprint.nil?
            raise "TODO: Failed to find blueprint: #{name.in_quotes}"
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
    end
  end
end
