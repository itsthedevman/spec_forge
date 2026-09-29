# frozen_string_literal: true

require "socket"

module ApiServer
  BOOT_TIMEOUT = 5

  class << self
    #
    # Boots a Sinatra app on a background thread and blocks until it accepts connections
    #
    # @param app [Class<Sinatra::Base>] The fake API to serve
    # @param port [Integer] The port to listen on
    #
    # @return [Thread] The server thread, to be handed to {.stop}
    #
    def start(app, port:)
      thread = Thread.new do
        app.run!(
          port:,
          server: "webrick",
          logging: false,
          quiet: true,
          traps: false,
          server_settings: {
            Logger: WEBrick::Log.new(File::NULL),
            AccessLog: []
          }
        )
      end

      thread.report_on_exception = true

      wait_until_listening(port, thread)
      thread
    end

    #
    # Stops a server started with {.start}, waiting for Sinatra to finish shutting down.
    # Sinatra's `run!` returns early while the app still counts as running, so the next `start` of the same app would
    # silently serve nothing if this did not wait for the killed thread's cleanup.
    #
    # @param thread [Thread, nil] The server thread returned by {.start}
    #
    def stop(thread)
      thread&.kill&.join
    end

    private

    def wait_until_listening(port, thread)
      deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + BOOT_TIMEOUT

      loop do
        raise "API server on port #{port} stopped before it began listening" unless thread.alive?

        TCPSocket.new("localhost", port).close
        return
      rescue Errno::ECONNREFUSED
        if Process.clock_gettime(Process::CLOCK_MONOTONIC) > deadline
          raise "API server did not begin listening on port #{port} within #{BOOT_TIMEOUT}s"
        end

        sleep 0.01
      end
    end
  end
end
