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

        def command_name(name)
          self.command_name = name
        end

        def syntax(syntax)
          self.syntax = syntax
        end

        def description(description)
          self.description = description
        end

        def summary(summary)
          self.summary = summary
        end

        def example(command, description)
          @examples ||= []

          # Commander wants it backwards
          @examples << [description, command]
        end

        def option(*args, &block)
          @options ||= []

          @options << [args, block]
        end

        def register(context)
          raise "Missing command name" if @command_name.nil?

          context.command(@command_name) do |c|
            c.syntax = @syntax
            c.summary = @summary
            c.description = @description
            c.examples = @examples if @examples

            @options.each do |opts, block|
              c.option(*opts, &block)
            end

            c.action { |args, opts| new(args, opts).call }
          end
        end
      end

      attr_reader :args, :options

      def initialize(args, options)
        @args = args
        @options = options
      end
    end
  end
end
