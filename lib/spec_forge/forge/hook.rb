# frozen_string_literal: true

module SpecForge
  class Forge
    class Hook
      class << self
        def before_forge(forge)
          hooks = forge.hooks[:before]
          return if hooks.blank?

          context = SpecForge::Forge.context
          run(forge, context, hooks)
        end

        def before_blueprint(forge, blueprint)
          hooks = blueprint.hooks[:before]
          return if hooks.blank?

          context = SpecForge::Forge.context.with(blueprint:)
          run(forge, context, hooks, trailing_newline: true)
        end

        def before_step(forge, step)
          hooks = step.hooks[:before]
          return if hooks.blank?

          context = SpecForge::Forge.context.with(step:)
          run(forge, context, hooks, trailing_newline: true)
        end

        def after_step(forge, step, error: nil)
          hooks = step.hooks[:after]
          return if hooks.blank?

          context = SpecForge::Forge.context.with(step:, error:)
          run(forge, context, hooks, leading_newline: true)
        end

        def after_blueprint(forge, blueprint)
          hooks = blueprint.hooks[:after]
          return if hooks.blank?

          context = SpecForge::Forge.context.with(blueprint:)
          run(forge, context, hooks)
        end

        def after_forge(forge)
          hooks = forge.hooks[:after]
          return if hooks.blank?

          context = SpecForge::Forge.context
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
