# frozen_string_literal: true

module SpecForge
  class CLI
    #
    # Base class for CLI commands that provides common functionality and
    # defines the DSL for declaring command properties.
    #
    # @example Defining a simple command
    #   class MyCommand < Command
    #     command_name "my_command"
    #     syntax "my_command [options]"
    #     summary "Does something awesome"
    #     description "A longer description of what this command does"
    #
    #     option "-f", "--force", "Force the operation"
    #
    #     def call
    #       # Command implementation
    #     end
    #   end
    #
    class Command
      include CLI::Actions

      class << self
        #
        # Sets the command's name
        #
        attr_writer :command_name

        #
        # Sets the command's syntax string
        #
        attr_writer :syntax

        #
        # Sets the command's detailed description
        #
        attr_writer :description

        #
        # Sets a brief summary of the command
        #
        attr_writer :summary

        #
        # Sets the command's available options
        #
        attr_writer :options

        #
        # Sets the command's name
        #
        # @param name [String] The name of the command
        #
        def command_name(name)
          self.command_name = name
        end

        #
        # Sets the command's syntax
        #
        # @param syntax [String] The command syntax to display in help
        #
        def syntax(syntax)
          self.syntax = syntax
        end

        #
        # Sets the command's description, displayed in detailed help
        #
        # @param description [String] The detailed command description
        #
        def description(description)
          self.description = description
        end

        #
        # Sets the command's summary, displayed in command list
        #
        # @param summary [String] The short command summary
        #
        def summary(summary)
          self.summary = summary
        end

        #
        # Adds an example of how to use the command
        #
        # @param command [String] The example command
        # @param description [String] Description of what the example does
        #
        def example(command, description)
          @examples ||= []

          # Commander wants it backwards
          @examples << [description, command]
        end

        #
        # Adds a command line option
        #
        # @param args [Array<String>] The option flags (e.g., "-f", "--force")
        # @yield [value] Block to handle the option value
        #
        def option(*args, &block)
          @options ||= []

          @options << [args, block]
        end

        #
        # Adds command aliases
        #
        # @param aliases [Array<String>] Alias names for this command
        #
        def aliases(*aliases)
          @aliases ||= []

          @aliases += aliases
        end

        #
        # Registers the command with Commander
        #
        # @param context [Commander::Command] The Commander context
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

      #
      # Command arguments passed from the command line
      #
      # @return [Array] The positional arguments
      #
      attr_reader :arguments

      #
      # Command options passed from the command line
      #
      # @return [Hash] The flag arguments
      #
      attr_reader :options

      #
      # Creates a new command instance
      #
      # @param arguments [Array] Any positional arguments from the command line
      # @param options [Hash] Any flag arguments from the command line
      #
      # @return [Command] A new command instance
      #
      def initialize(arguments, options)
        @arguments = arguments
        @options = options
      end
    end
  end
end
