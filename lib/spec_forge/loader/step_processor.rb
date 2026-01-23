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

        @global_hooks = SpecForge.configuration.hooks.transform_values do |callbacks|
          Normalizer::Transformers.call(:normalize_callback, callbacks)
        end

        @forge_hooks = {
          before: Set.new(@global_hooks[:before_forge]),
          after: Set.new(@global_hooks[:after_forge])
        }
      end

      #
      # Processes all blueprints and returns the flattened, normalized steps
      #
      # Performs two passes over the blueprints:
      # 1. Preprocessing: normalizes steps and assigns source information
      # 2. Main processing: expands includes, inherits shared config, extracts
      #    hooks, applies tags, and flattens nested step hierarchies
      #
      # @return [Array<Array<Hash>, Hash>] Tuple of processed blueprints and forge hooks
      #
      def run
        # Do a preprocessing pass to ensure all steps are normalized and ready to be referenced
        @blueprints.each do |name, blueprint|
          blueprint[:hooks] = {
            before: Set.new(@global_hooks[:before_blueprint]),
            after: Set.new(@global_hooks[:after_blueprint])
          }

          blueprint[:steps] = assign_source(blueprint[:steps], file_name: blueprint[:name])
            .then { |s| normalize_steps(s) }
        end

        @blueprints.each do |name, blueprint|
          hooks = {
            before: Set.new(@global_hooks[:before_step]),
            after: Set.new(@global_hooks[:after_step])
          }

          blueprint[:steps] = expand_steps(blueprint[:steps])
            .then { |s| inherit_shared(s) }
            .then { |s| extract_and_assign_hooks(s, blueprint, all: hooks) }
            .then { |s| tag_steps(s) }
            .then { |s| flatten_steps(s) }
            .then { |s| remove_empty_steps(s) }
        end

        [@blueprints.values, @forge_hooks]
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

          # Pluralize these to be consistent
          step.rename_key_unordered!(:call, :calls)
          step.rename_key_unordered!(:expect, :expects)

          step
        rescue => e
          raise Error::LoadStepError.new(e, step)
        end
      end

      def extract_and_assign_hooks(steps, blueprint, all:)
        steps.each do |step|
          hooks = step.delete(:hook) || {}
          hooks.default = []

          # Forge
          @forge_hooks[:before].merge(hooks[:before_forge])
          @forge_hooks[:after].merge(hooks[:after_forge])

          # Blueprint
          blueprint[:hooks][:before].merge(hooks[:before_blueprint])
          blueprint[:hooks][:after].merge(hooks[:after_blueprint])

          # Step
          before = all[:before].merge(hooks[:before_step])
          after = all[:after].merge(hooks[:after_step])

          if step[:steps].blank?
            step[:hooks] = {before: before.to_a, after: after.to_a.reverse}
          else
            extract_and_assign_hooks(step[:steps], blueprint, all: all.deep_dup)
          end
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
        step[:steps] +=
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

        step
      end

      def assign_included_by(source_step, steps)
        steps.each do |step|
          step[:included_by] = source_step[:source]
          step[:steps] = assign_included_by(source_step, step[:steps]) if step[:steps]
        end
      end

      def inherit_shared(steps, shared: {})
        steps.each do |step|
          # Apply inherited values to this step
          step[:request] = merge_request(shared[:request], step[:request])
          step[:hook] = merge_hooks(shared[:hook], step[:hook])

          if step[:steps].present?
            step_shared = step.delete(:shared) || {}

            # Combine parent's shared with this step's shared for children
            inherit_shared(
              step[:steps],
              shared: {
                request: merge_request(shared[:request], step_shared[:request]),
                hook: merge_hooks(shared[:hook], step_shared[:hook])
              }
            )
          end
        end
      end

      def merge_request(parent, child)
        return child if parent.blank?
        return parent if child.blank?

        parent.deep_merge(child)
      end

      def merge_hooks(parent, child)
        return child if parent.blank?
        return parent if child.blank?

        parent.merge(child) { |_, a, b| a + b }
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
          step = step.except(:name, :source, :tags, :documentation)
          step.compact_blank!

          step.except(:hooks).present?
        end
      end
    end
  end
end
