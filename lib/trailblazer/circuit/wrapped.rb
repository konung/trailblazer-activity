class Trailblazer::Circuit
  # Lingo: task_wrap
  module Activity::Wrapped
    # The runner is passed into Circuit#call( runner: Runner ) and is called for every task in the circuit.
    # Its primary job is to actually `call` the task.
    #
    # Here, we extend this, and wrap the task `call` into its own pipeline, so we can add external behavior per task.
    class Runner
      # private flow_options[ :task_wraps ] # DISCUSS: move to separate arg?
      def self.call(task, direction, options, flow_options)
        # TODO: test this decider!
        task_wrap   = flow_options[:task_wraps][task] || flow_options[:task_wraps][nil]
        wrap_config = { task: task }

        # Call the task_wrap circuit:
        #   |-- Start
        #   |-- Trace.capture_args   [optional]
        #   |-- Call (call actual task)
        #   |-- Trace.capture_return [optional]
        #   |-- End
        # Pass empty flow_options to the task_wrap, so it doesn't infinite-loop.
        task_wrap.( task_wrap[:Start], options, {}, wrap_config, flow_options ) # all tasks in Wrap have to implement this signature.
      end
    end # Runner

    # Input  = ->(direction, options, flow_options) { [direction, options, flow_options] }

    def self.call_activity(direction, options, flow_options, wrap_config, original_flow_options)
      task  = wrap_config[:task]

      # Call the actual task we're wrapping here.
      wrap_config[:result_direction], options, flow_options = task.( direction, options, original_flow_options )

      [ direction, options, flow_options, wrap_config, original_flow_options ]
    end

    Call = method(:call_activity)

    # Output = ->(direction, options, flow_options) { [direction, options, flow_options] }

    class End < Trailblazer::Circuit::End
      def call(direction, options, flow_options, wrap_config, *args)
        [ wrap_config[:result_direction], options, flow_options ] # note how we don't return the appended internal args.
      end
    end

    Activity = Trailblazer::Circuit::Activity({ id: "task.wrap" }, end: { default: End.new(:default) }) do |act|
      {
        act[:Start] => { Right => Call },                  # options from outside
        Call        => { Right => act[:End] },
      }
    end # Activity
  end
end
