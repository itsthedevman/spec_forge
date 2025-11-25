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
            .then { |s| normalize_steps(s) }
            .then { |s| expand_steps(s) }
            .then { |s| tag_steps(s) }
            .then { |s| flatten_steps(s) }
            .then { |s| normalize_steps(s) }
        end
      end

      private

      def normalize_steps(steps)
        steps.map do |step|
          # We'll normalize these separately
          sub_steps = step.delete(:steps) || []
          step = Normalizer.normalize!(step, using: :step)

          step[:steps] = normalize_steps(sub_steps)
          step
        rescue => e
          raise Error::LoadStepError.new(e, step)
        end
      end

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
        output_steps =
          names.flat_map do |name|
            blueprint = @blueprints[name]

            if blueprint.nil?
              raise Error, <<~STRING
                Blueprint #{name.in_quotes} not found
                Referenced in: #{step[:source][:file_name]}:#{step[:source][:line_number]}

                Available blueprints: #{@blueprints.keys.join_map(", ", &:in_quotes)}
              STRING
            end

            steps = blueprint[:steps].deep_dup
            steps = assign_included_by(step, steps)

            {
              tags: step[:tags],
              steps:
            }
          end

        # Count total steps being included
        total_steps = output_steps.sum { |s| s[:steps].size }

        # Format display message
        display_message =
          if names.size == 1
            "-> Including #{names.first}.yml (#{total_steps} steps)"
          else
            files = names.join_map(", ", &:in_quotes)
            "-> Including #{files} (#{total_steps} steps total)"
          end

        # Insert a message to print before running the included steps
        output_steps.insert(0, {
          display_message:,
          source: step[:source],
          tags: step[:tags]
        })

        output_steps
      end

      def assign_included_by(source_step, steps)
        steps.each do |step|
          step[:included_by] = source_step[:source]
          step[:steps] = assign_included_by(source_step, step[:steps]) if step[:steps]
        end
      end

      def tag_steps(steps, parent_tags: [])
        steps.each do |step|
          step[:tags] = (parent_tags + step[:tags]).uniq if step[:tags]

          tag_steps(step[:steps], parent_tags: step[:tags]) if step[:steps]
        end
      end

      def flatten_steps(steps)
        steps.flat_map do |step|
          if (sub_steps = step[:steps]) && sub_steps.size > 0
            flatten_steps(sub_steps)
          else
            step
          end
        end
      end
    end
  end
end
