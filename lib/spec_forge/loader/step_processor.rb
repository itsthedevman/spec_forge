# frozen_string_literal: true

module SpecForge
  class Loader
    #
    # Processes raw step hashes into normalized, flattened step arrays
    #
    # Handles the heavy lifting of load-time processing: normalizing step
    # structures, expanding includes, inheriting configuration from parents,
    # applying tags, and flattening nested hierarchies.
    #
    class StepProcessor
      #
      # Creates a new step processor for the given blueprints
      #
      # @param blueprints [Hash<String, Hash>] Blueprints indexed by name
      #
      # @return [StepProcessor] A new step processor instance
      #
      def initialize(blueprints)
        @blueprints = blueprints
        @forge_hooks = {before: [], after: []}
      end

      # TODO: Documentation
      def run
        @blueprints.each do |name, blueprint|
          blueprint[:hooks] = {before: [], after: []}

          # This is important to be done to every blueprint before expanding the includes
          blueprint[:steps] = assign_source(blueprint[:steps], file_name: blueprint[:name])
        end

        @blueprints.each do |name, blueprint|
          blueprint[:steps] = normalize_steps(blueprint[:steps])
            .then { |s| expand_steps(s) }
            .then { |s| inherit_request(s) }
            .then { |s| extract_and_assign_hooks(s, blueprint) }
            .then { |s| tag_steps(s) }
            .then { |s| flatten_steps(s) }
            .then { |s| remove_empty_steps(s) }
        end

        File.write("steps.json", JSON.pretty_generate(@blueprints["hooks"][:steps]))
        [@blueprints.values, {hooks: @forge_hooks}]
      end

      private

      def assign_source(steps, file_name:)
        steps.each do |step|
          step[:source] = {file_name:, line_number: step.delete(:line_number)}
          step[:steps] = assign_source(step[:steps], file_name:) if step[:steps]
        end
      end

      def normalize_steps(steps)
        return steps if steps.blank?

        steps.map do |step|
          # System data (not included in normalizer)
          source = step.delete(:source)

          # We'll normalize these separately (not included in normalizer)
          sub_steps = step.delete(:steps) || []

          begin
            step = Normalizer.normalize!(step, using: :step, label: "")
            step[:steps] = normalize_steps(sub_steps)
          ensure
            step[:source] = source
          end

          step
        rescue => e
          raise Error::LoadStepError.new(e, step)
        end
      end

      def extract_and_assign_hooks(steps, blueprint, parent: nil, before_step: [], after_step: [])
        steps.each do |step|
          @forge_hooks[:before] += step.dig(:hook, :before_forge) || []
          @forge_hooks[:after] += step.dig(:hook, :after_forge) || []

          blueprint[:hooks][:before] += step.dig(:hook, :before_blueprint) || []
          blueprint[:hooks][:after] += step.dig(:hook, :after_blueprint) || []

          before_step += step.dig(:hook, :before_step) || []
          after_step += step.dig(:hook, :after_step) || []

          step[:hooks] =
            if parent
              {
                before: parent.dig(:hooks, :before) + before_step,
                after: parent.dig(:hooks, :after) + after_step
              }
            else
              {before: before_step, after: after_step}
            end

          step[:hooks][:before].uniq!
          step[:hooks][:after].uniq!

          if step[:steps].present?
            extract_and_assign_hooks(
              step[:steps], blueprint,
              parent: step,
              before_step:, after_step:
            )

            # Don't allow steps with substeps to have hooks - otherwise hooks will run twice
            step.delete(:hooks)
          end

          # Remove the original hook attribute since we've renamed it
          step.delete(:hook)
        end

        steps
      end

      def inherit_request(steps, parent_request: nil)
        steps.each do |step|
          step[:request] = parent_request.deep_merge(step[:request] || {}) if parent_request.present?

          inherit_request(step[:steps], parent_request: step[:request]) if step[:steps].present?
        end
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
          step[:tags] = (parent_tags + (step[:tags] || [])).uniq

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

      def remove_empty_steps(steps)
        steps.select do |step|
          step = step.except(:source)
          step[:hooks]&.compact_blank!
          step.compact_blank!

          step.present?
        end
      end
    end
  end
end
