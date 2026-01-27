# frozen_string_literal: true

module SpecForge
  class Forge
    #
    # Executes lifecycle hooks at various points during forge execution
    #
    # Provides class methods for triggering before/after hooks at the
    # forge, blueprint, and step levels.
    #
    class Hooks
      class << self
        #
        # Executes before-forge hooks
        #
        # @param forge [Forge] The forge instance
        #
        # @return [void]
        #
        def before_forge(forge)
          hooks = forge.hooks[:before]
          return if hooks.blank?

          context = SpecForge::Forge.context.with(forge:)
          run(forge, context, hooks)
        end

        #
        # Executes before-blueprint hooks
        #
        # @param forge [Forge] The forge instance
        # @param blueprint [Blueprint] The blueprint about to execute
        #
        # @return [void]
        #
        def before_blueprint(forge, blueprint)
          hooks = blueprint.hooks[:before]
          return if hooks.blank?

          context = SpecForge::Forge.context.with(forge:, blueprint:)
          run(forge, context, hooks, trailing_newline: true)
        end

        #
        # Executes before-step hooks
        #
        # @param forge [Forge] The forge instance
        # @param step [Step] The step about to execute
        #
        # @return [void]
        #
        def before_step(forge, blueprint, step)
          hooks = step.hooks[:before]
          return if hooks.blank?

          context = SpecForge::Forge.context.with(forge:, blueprint:, step:)
          run(forge, context, hooks, trailing_newline: true)
        end

        #
        # Executes after-step hooks
        #
        # @param forge [Forge] The forge instance
        # @param step [Step] The step that finished
        # @param error [Exception, nil] Any error that occurred
        #
        # @return [void]
        #
        def after_step(forge, blueprint, step, error: nil)
          hooks = step.hooks[:after]
          return if hooks.blank?

          context = SpecForge::Forge.context.with(forge:, blueprint:, step:, error:)
          run(forge, context, hooks, leading_newline: true)
        end

        #
        # Executes after-blueprint hooks
        #
        # @param forge [Forge] The forge instance
        # @param blueprint [Blueprint] The blueprint that finished
        #
        # @return [void]
        #
        def after_blueprint(forge, blueprint)
          hooks = blueprint.hooks[:after]
          return if hooks.blank?

          context = SpecForge::Forge.context.with(forge:, blueprint:)
          run(forge, context, hooks)
        end

        #
        # Executes after-forge hooks
        #
        # @param forge [Forge] The forge instance
        #
        # @return [void]
        #
        def after_forge(forge)
          hooks = forge.hooks[:after]
          return if hooks.blank?

          context = SpecForge::Forge.context.with(forge:)
          run(forge, context, hooks)
        end

        private

        def run(forge, context, calls, leading_newline: false, trailing_newline: false)
          forge.display.empty_line if leading_newline

          calls.each do |call|
            callback_name = call.callback_name
            arguments = call.arguments

            forge.display.action(
              "Call #{callback_name}",
              message_styles: :dim,
              symbol: :checkmark, symbol_styles: :dim
            )

            forge.callbacks.run(callback_name, context, arguments)
          end

          forge.display.empty_line if trailing_newline
        end
      end
    end
  end
end
