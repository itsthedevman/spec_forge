# frozen_string_literal: true

module SpecForge
  class Loader
    class StepProcessor
      def initialize(blueprints)
        @blueprints = blueprints
      end

      def run
        # This is important to be done to every blueprint before expanding the includes
        @blueprints.each do |name, blueprint|
          blueprint[:steps] = assign_source(blueprint[:steps], file_name: blueprint[:name])
        end

        @blueprints.each do |name, blueprint|
          blueprint[:steps] = normalize_steps(blueprint[:steps])
            .then { |s| expand_steps(s) }
            .then { |s| tag_steps(s) }
            .then { |s| flatten_steps(s) }
        end

        @blueprints.values
      end

      private

      def assign_source(steps, file_name:)
        steps.each do |step|
          step[:source] = {file_name:, line_number: step.delete(:line_number)}
          step[:steps] = assign_source(step[:steps], file_name:) if step[:steps]
        end
      end

      def normalize_steps(steps, parent: nil)
        steps.map do |step|
          # System data (not included in normalizer)
          source = step.delete(:source)

          # We'll normalize these separately (not included in normalizer)
          sub_steps = step.delete(:steps) || []

          step = Normalizer.normalize!(step, using: :step)
          step = inherit_from_parent(step, parent) if parent

          step[:steps] = normalize_steps(sub_steps, parent: step)
          step[:source] = source

          step
        rescue => e
          raise Error::LoadStepError.new(e, step)
        end
      end

      def inherit_from_parent(step, parent)
        return step if parent[:request].blank?

        step[:request] = parent[:request].deep_merge(step[:request])
        step
      end

      def expand_steps(steps)
        return if steps.blank?

        output_steps = []

        steps.each do |step|
          output_steps <<
            if (names = step.delete(:include)) && names.size > 0
              load_included_steps(step, names)
            else
              step
            end

          step[:steps] = expand_steps(step[:steps])
        end

        output_steps
      end

      def load_included_steps(step, names)
        imported_steps =
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
            steps
          end

        # Count total steps being included
        total_steps = imported_steps.size

        # Change the original step to be a display notice
        step[:description] =
          if names.size == 1
            "-> Including #{names.first}.yml (#{total_steps} steps)"
          else
            files = names.join_map(", ", &:in_quotes)
            "-> Including #{files} (#{total_steps} steps total)"
          end

        step[:steps] += imported_steps
        step
      end

      def assign_included_by(source_step, steps)
        steps.each do |step|
          step[:included_by] = source_step[:source]
          step[:steps] = assign_included_by(source_step, step[:steps]) if step[:steps]
        end
      end

      def tag_steps(steps, parent_tags: [])
        steps.each do |step|
          step[:tags] = (parent_tags + step[:tags]).uniq

          tag_steps(step[:steps], parent_tags: step[:tags]) if step[:steps]
        end
      end

      def flatten_steps(steps)
        steps.flat_map do |step|
          if (sub_steps = step.delete(:steps))
            flatten_steps(sub_steps)
          else
            step
          end
        end
      end
    end
  end
end
