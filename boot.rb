#
# boot.rb
#

require 'racc/info'
require 'racc/grammar'
require 'racc/state'
require 'racc/output'


module Racc

  class State

    def sr_conflict( *args )
      raise 'Racc boot script fatal: S/R conflict in build'
    end

    def rr_conflict( *args )
      raise 'Racc boot script fatal: R/R conflict in build'
    end

  end
      

  class Compiler

    attr_reader :ruletable
    attr_reader :symboltable
    attr_reader :statetable

    def filename
      '(boot.rb)'
    end

    def debug_parser() @dflag end
    def convert_line() true end
    def omit_action()  true end
    def result_var()   true end

    def debug()   false end
    def d_parse() false end
    def d_rule()  false end
    def d_token() false end
    def d_state() false end
    def d_la()    false end
    def d_prec()  false end


    def _( rulestr, actstr )
      nonterm, symlist = parse_rule_exp(rulestr)
      lineno = /:(\d+)(?:\z|:)/.match( caller(1)[0] )[1].to_i + 1
      symlist.push UserAction.new(format_action(actstr), lineno)

      @ruletable.register_rule( nonterm, symlist )
    end

    def parse_rule_exp( str )
      tokens = str.strip.scan(/[\:\|]|'.'|\w+/)
      nonterm = (tokens[0] == '|') ? nil : @symboltable.get(tokens.shift.intern)
      tokens.shift   # discard ':' or '|'

      return nonterm,
             tokens.collect {|t|
                 @symboltable.get(
                         (/\A'/ === t) ? eval(%Q<"#{t[1..-2]}">) : t.intern
                 )
             }
    end

    def format_action( str )
      str.sub(/\A */, '').sub(/\s+\z/, '').collect {|line|
              line.sub(/\A {20}/, '')
      }.join('')
    end

    def build( debugflag )
      @dflag = debugflag

      @symboltable = SymbolTable.new( self )
      @ruletable   = RuleTable.new( self )
      @statetable  = StateTable.new( self )


_"  xclass      : XCLASS class params XRULE rules XEND                   ",
                   %{
                        @ruletable.end_register_rule
                    }

_"  class       : rubyconst                                              ",
                   %{
                        @class_name = val[0]
                    }
_"              | rubyconst '<' rubyconst                                ",
                   %{
                        @class_name = val[0]
                        @super_class = val[2]
                    }

_"  rubyconst   : XSYMBOL                                                ",
                   %{
                        result = result.id2name
                    }
_"              | rubyconst ':'':' XSYMBOL                               ",
                   %{
                        result << '::' << val[3].id2name
                    }

_"  params      :                                                        ", ''
_"              | params param_seg                                       ", ''

_"  param_seg   : XCONV convdefs XEND                                    ",
                   %{
                        @symboltable.end_register_conv
                    }
_"              | xprec                                                  ", ''
_"              | XSTART symbol                                          ",
                   %{
                        @ruletable.register_start val[1]
                    }
_"              | XTOKEN symbol_list                                     ",
                   %{
                        @symboltable.register_token val[1]
                    }
_"              | XOPTION bare_symlist                                   ",
                   %{
                        val[1].each do |s|
                          @ruletable.register_option s.to_s
                        end
                    }
_"              | XEXPECT DIGIT                                          ",
                   %{
                        @ruletable.expect val[1]
                    }

_"  convdefs    : symbol STRING                                          ",
                   %{
                        @symboltable.register_conv val[0], val[1]
                    }
_"              | convdefs symbol STRING                                 ",
                   %{
                        @symboltable.register_conv val[1], val[2]
                    }

_"  xprec       : XPRECHIGH preclines XPRECLOW                           ",
                   %{
                        @symboltable.end_register_prec true
                    }
_"              | XPRECLOW preclines XPRECHIGH                           ",
                   %{
                        @symboltable.end_register_prec false
                    }

_"  preclines   : precline                                               ", ''
_"              | preclines precline                                     ", ''

_"  precline    : XLEFT symbol_list                                      ",
                   %{
                        @symboltable.register_prec :Left, val[1]
                    }
_"              | XRIGHT symbol_list                                     ",
                   %{
                        @symboltable.register_prec :Right, val[1]
                    }
_"              | XNONASSOC symbol_list                                  ",
                   %{
                        @symboltable.register_prec :Nonassoc, val[1]
                    }

_"  symbol_list : symbol                                                 ",
                   %{
                        result = val
                    }
_"              | symbol_list symbol                                     ",
                   %{
                        result.push val[1]
                    }
_"              | symbol_list '|'                                        ", ''

_"  symbol      : XSYMBOL                                                ",
                   %{
                        result = @symboltable.get(result)
                    }
_"              | STRING                                                 ",
                   %{
                        result = @symboltable.get(eval(%Q<"\#{result}">))
                    }

_"  rules       : rules_core                                             ",
                   %{
                        unless result.empty? then
                          @ruletable.register_rule_from_array result
                        end
                    }
_"              |                                                        ", ''

_"  rules_core  : symbol                                                 ",
                   %{
                        result = val
                    }
_"              | rules_core rule_item                                   ",
                   %{
                        result.push val[1]
                    }
_"              | rules_core ';'                                         ",
                   %{
                        unless result.empty? then
                          @ruletable.register_rule_from_array result
                        end
                        result.clear
                    }
_"              | rules_core ':'                                         ",
                   %{
                        pre = result.pop
                        unless result.empty? then
                          @ruletable.register_rule_from_array result
                        end
                        result = [pre]
                    }

_"  rule_item   : symbol                                                 ", ''
_"              | '|'                                                    ",
                   %{
                        result = OrMark.new( @scanner.lineno )
                    }
_"              | '=' symbol                                             ",
                   %{
                        result = Prec.new( val[1], @scanner.lineno )
                    }
_"              | ACTION                                                 ",
                   %{
                        result = UserAction.new( *result )
                    }

_"  bare_symlist: XSYMBOL                                                ",
                   %{
                        result = [ result.id2name ]
                    }
_"              | bare_symlist XSYMBOL                                   ",
                   %{
                        result.push val[1].id2name
                    }


      @ruletable.init
      @statetable.init
      @statetable.determine

      File.open( 'raccp.rb', 'w' ) {|f|
      File.foreach( 'in.raccp.rb' ) do |line|
        if /STATE_TRANSITION_TABLE/ === line then
          CodeGenerator.new(self).output f
        else
          f.print line
        end
      end
      }
      File.open( 'b.output', 'w' ) {|f|
          VerboseOutputter.new(self).output f
      }
    end

  end

end   # module Racc


Racc::Compiler.new.build ARGV.index('-g')
