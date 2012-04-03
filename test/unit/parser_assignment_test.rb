require File.expand_path('../test_helper.rb', File.dirname(__FILE__))

describe RipperRubyParser::Parser do
  describe "#parse" do
    describe "for multiple assignment" do
      specify do
        "foo, * = bar".
          must_be_parsed_as s(:masgn,
                              s(:array, s(:lasgn, :foo), s(:splat)),
                              s(:to_ary, s(:call, nil, :bar, s(:arglist))))
      end

      specify do
        "(foo, *bar) = baz".
          must_be_parsed_as s(:masgn,
                              s(:array,
                                s(:lasgn, :foo),
                                s(:splat, s(:lasgn, :bar))),
                              s(:to_ary, s(:call, nil, :baz, s(:arglist))))
      end
    end

    describe "for assignment to a collection element" do
      it "handles multiple indices" do
        "foo[bar, baz] = qux".
          must_be_parsed_as s(:attrasgn,
                              s(:call, nil, :foo, s(:arglist)),
                              :[]=,
                              s(:arglist,
                                s(:call, nil, :bar, s(:arglist)),
                                s(:call, nil, :baz, s(:arglist)),
                                s(:call, nil, :qux, s(:arglist))))
      end
    end

    describe "for operator assignment" do
      describe "assigning to a collection element" do
        it "handles multiple indices" do
          "foo[bar, baz] += qux".
            must_be_parsed_as s(:op_asgn1,
                                s(:call, nil, :foo, s(:arglist)),
                                s(:arglist,
                                  s(:call, nil, :bar, s(:arglist)),
                                  s(:call, nil, :baz, s(:arglist))),
                                :+,
                                s(:call, nil, :qux, s(:arglist)))
        end
      end
    end

    describe "for multiple assignment" do
      describe "with a right-hand splat" do
        specify do
          "foo, bar = *baz".
            must_be_parsed_as s(:masgn,
                                s(:array, s(:lasgn, :foo), s(:lasgn, :bar)),
                                s(:splat, s(:call, nil, :baz, s(:arglist))))
        end
        specify do
          "foo, bar = baz, *qux".
            must_be_parsed_as s(:masgn,
                                s(:array, s(:lasgn, :foo), s(:lasgn, :bar)),
                                s(:array,
                                  s(:call, nil, :baz, s(:arglist)),
                                  s(:splat, s(:call, nil, :qux, s(:arglist)))))
        end
      end
    end
  end
end