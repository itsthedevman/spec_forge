# frozen_string_literal: true

module SpecForge
  class CLI
    class Command
      include CLI::Actions

      class << self
        attr_writer(*%i[
          command_name
          syntax
          description
          summary
          options
        ])

        #
        # The command's name
        #
        # @param name [String] The name of the command
        #
        def command_name(name)
          self.command_name = name
        end

        #
        # The command's syntax
        #
        # @param syntax [String]
        #
        def syntax(syntax)
          self.syntax = syntax
        end

        #
        # The command's description, long form
        #
        # @param description [String]
        #
        def description(description)
          self.description = description
        end

        #
        # The command's summary, short form
        #
        # @param summary [String]
        #
        def summary(summary)
          self.summary = summary
        end

        #
        # Defines an example on how to use the command
        #
        # @param command [String] The example
        # @param description [String] Description of the example
        #
        def example(command, description)
          @examples ||= []

          # Commander wants it backwards
          @examples << [description, command]
        end

        #
        # Defines a command flag (-f, --force)
        #
        def option(*args, &block)
          @options ||= []

          @options << [args, block]
        end

        #
        # Defines any aliases for this command
        #
        # @param *aliases [Array<String>]
        #
        def aliases(*aliases)
          @aliases ||= []

          @aliases += aliases
        end

        #
        # Registers the command with Commander
        #
        # @param context [Commander::Command]
        #
        # @private
        #
        def register(context)
          raise "Missing command name" if @command_name.nil?

          context.command(@command_name) do |c|
            c.syntax = @syntax
            c.summary = @summary
            c.description = @description
            c.examples = @examples if @examples

            @options&.each do |opts, block|
              c.option(*opts, &block)
            end

            c.action { |args, opts| new(args, opts).call }
          end

          @aliases&.each do |alii|
            context.alias_command(alii, @command_name)
          end
        end
      end

      attr_reader :arguments, :options

      #
      # @param arguments [Array] Any positional arguments
      # @param options [Hash] Any flag arguments
      #
      def initialize(arguments, options)
        @arguments = arguments
        @options = options
      end
    end
  end
end
