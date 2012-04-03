module RipperRubyParser
  module SexpHandlers
    module Loops
      def process_until exp
        _, cond, block = exp.shift 3

        cond = process(cond)
        block = handle_statement_list(block)

        if cond.sexp_type == :not
          s(:while, cond[1], block, true)
        else
          s(:until, cond, block, true)
        end
      end

      def process_until_mod exp
        _, cond, block = exp.shift 3

        check_at_start = block.sexp_type != :begin

        s(:until, process(cond), process(block), check_at_start)
      end

      def process_while exp
        _, cond, block = exp.shift 3

        cond = process(cond)
        block = handle_statement_list(block)

        if cond.sexp_type == :not
          s(:until, cond[1], block, true)
        else
          s(:while, cond, block, true)
        end
      end

      def process_for exp
        _, var, coll, block = exp.shift 4
        s(:for, process(coll),
          s(:lasgn, process(var)[1]),
          handle_statement_list(block))
      end
    end
  end
end

