require 'sexp_processor'
require 'ripper_ruby_parser/sexp_handlers'
require 'ripper_ruby_parser/sexp_ext'

module RipperRubyParser
  # Processes the sexp created by Ripper to what RubyParser would produce.
  class SexpProcessor < ::SexpProcessor
    def initialize
      super
      # TODO: Find these automatically
      @processors[:@int] = :process_at_int
      @processors[:@const] = :process_at_const
      @processors[:@ident] = :process_at_ident
      @processors[:@gvar] = :process_at_gvar
      @processors[:@ivar] = :process_at_ivar
      @processors[:@kw] = :process_at_kw
      @processors[:@backref] = :process_at_backref

      @processors[:@tstring_content] = :process_at_tstring_content
    end

    def process exp
      return nil if exp.nil?
      exp.fix_empty_type

      super
    end

    include SexpHandlers

    def process_program exp
      _, content = exp.shift 2

      if content.length == 1
        process(content.first)
      else
        statements = content.map { |sub_exp| process(sub_exp) }
        s(:block, *statements)
      end
    end

    def process_module exp
      _, const_ref, body = exp.shift 3
      const = const_node_to_symbol const_ref[1]
      s(:module, const, class_or_module_body(body))
    end

    def process_class exp
      _, const_ref, parent, body = exp.shift 4
      const = const_node_to_symbol const_ref[1]
      parent = process(parent)
      s(:class, const, parent, class_or_module_body(body))
    end

    def process_bodystmt exp
      _, body, _, _, _ = exp.shift 5
      body = body.
        map { |sub_exp| process(sub_exp) }.
        reject { |sub_exp| sub_exp.sexp_type == :void_stmt }
      s(:scope, s(:block, *body))
    end

    def process_var_ref exp
      _, contents = exp.shift 2
      process(contents)
    end

    def process_var_field exp
      _, contents = exp.shift 2
      process(contents)
    end

    def process_const_path_ref exp
      _, left, right = exp.shift 3
      s(:colon2, process(left), const_node_to_symbol(right))
    end

    def process_top_const_ref exp
      _, ref = exp.shift 2
      s(:colon3, const_node_to_symbol(ref))
    end

    OPERATOR_MAP = {
      "&&".to_sym => :and,
      "||".to_sym => :or
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

    def process_paren exp
      _, body = exp.shift 2
      process(body)
    end

    def process_at_int exp
      _, val, _ = exp.shift 3
      s(:lit, val.to_i)
    end

    # symbol-like sexps
    def process_at_const exp
      s(:const, extract_node_symbol(exp))
    end

    def process_at_gvar exp
      s(:gvar, extract_node_symbol(exp))
    end

    def process_at_ivar exp
      s(:ivar, extract_node_symbol(exp))
    end

    def process_at_ident exp
      s(:lvar, extract_node_symbol(exp))
    end

    def process_at_kw exp
      sym = extract_node_symbol(exp)
      if sym == :__FILE__
        s(:str, "(string)")
      else
        s(sym)
      end
    end

    def process_at_backref exp
      _, str, _ = exp.shift 3
      s(:nth_ref, str[1..-1].to_i)
    end

    private

    def const_node_to_symbol exp
      assert_type exp, :@const
      _, ident, _ = exp.shift 3

      ident.to_sym
    end

    def extract_node_symbol exp
      _, ident, _ = exp.shift 3

      ident.to_sym
    end

    def class_or_module_body exp
      scope = process exp
      block = scope[1]
      block.shift
      if block.length <= 1
        s(:scope, *block)
      else
        s(:scope, s(:block, *block))
      end
    end
  end
end
