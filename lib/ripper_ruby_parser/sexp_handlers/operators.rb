module RipperRubyParser
  module SexpHandlers
    module Operators
      OPERATOR_MAP = {
        "&&".to_sym => :and,
        "||".to_sym => :or,
        :and => :and,
        :or => :or
      }

      UNARY_OPERATOR_MAP = {
        :"!" => :not,
        :not => :not
      }

      def process_binary exp
        _, left, op, right = exp.shift 4
        mapped = OPERATOR_MAP[op]
        if mapped
          s(mapped, process(left), process(right))
        else
          s(:call, process(left), op, s(:arglist, process(right)))
        end
      end

      def process_unary exp
        _, op, arg = exp.shift 3
        arg = process(arg)
        mapped = UNARY_OPERATOR_MAP[op]
        if mapped
          s(mapped, arg)
        else
          if is_literal? arg
            s(:lit, arg[1].send(op))
          else
            s(:call, arg, op, s(:arglist))
          end
        end
      end

      def process_dot2 exp
        _, left, right = exp.shift 3
        left = process(left)
        right = process(right)
        if is_literal?(left) && is_literal?(right)
          s(:lit, Range.new(left[1], right[1]))
        else
          s(:dot2, left, right)
        end
      end

      def process_ifop exp
        _, cond, truepart, falsepart = exp.shift 4
        s(:if, process(cond), process(truepart), process(falsepart))
      end
    end
  end
end
