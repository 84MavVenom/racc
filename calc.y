
class Calcp

  prechigh
    nonassoc UMINUS
    left '*' '/'
    left '+' '-'
  preclow

  rule
    target: exp .
      .
      |
      .
        result = 0
      .
      ;

    exp: exp '+' exp . result += val[2]
       .
       | exp '-' exp . result -= val[2]
       .
       | exp '*' exp . result *= val[2]
       .
       | exp '/' exp . result /= val[2]
       .
       | '(' exp ')' . result = val[1]
       .
       | '-' NUMBER  = UMINUS . result = -val[1]
       .
       | NUMBER .
       .
       ;
  end

end # class

prepare = code
require 'must'
.

inner = code
  
  def parse( str )
    str.must String
    @tsrc = []
    @vsrc = []

    while str.size > 0 do
      case str
      when /\A\s+/o
      when /\A\d+/o
        @tsrc.push :NUMBER
        @vsrc.push $&.to_i
      when /\A.|\n/o
        s = $&
        @tsrc.push s
        @vsrc.push s
      end
      str = $'
    end
        
    @tsrc.push false
    @tsrc.push false
    @vsrc.push false
    @vsrc.push false

    do_parse
  end

  def next_token
    @tsrc.shift
  end

  def next_value
    @vsrc.shift
  end

  def peep_token
    @tsrc[0]
  end      
.


driver = code

class Nemui < Exception ; end

parser = Calcp.new
count = 0
scnt  = 0

print "\n***********************"
print "\nĶ��ڤ����������2�浡"
print "\n***********************\n\n"
print "���ꤿ���ʤä���Q�򥿥��פ��Ƥ�\n"

while true do
  print "\n"
  print 'ikutu? > '
  str = gets.chop!
  if /\Aq/io === str then break end

  begin
    val = parser.parse( str )
    print 'kotae! = ', val, "\n"
    scnt += 1
    
    case scnt
    when 5
      print "\nƯ����ΤǤ���� 5���׻�������ä���\n\n"
    when 10
      print "\n���äѤ��׻��������͡�\n\n"
    when 15
      print "\n�ͤ����� �⤦�Ĥ��줿���� �⤦�٤⤦�衼\n\n"
    when 20
      print "\n�⤦�ͤ�Τá���\n\n"
      raise Nemui, "�⤦���ᡣ"
    end

  rescue ParseError
    case count
    when 0
      print "\n  �������á�\n"
    when 1
      print "\n  �⤦�á������ä��㤦�衪��\n"
    when 2
      print "\n  �⤦�����Ƥ����ʤ��������á�����\n\n\n"
      sleep(0.5)
      print "           �����á�\n\n"
      sleep(1)
      raise
    end
    count += 1

  rescue
    print "\n  ����ʤ��\n"
    raise

  end

end

print "\n���㤢���ޤ��ͤ�\n\n"
sleep(0.5)

.

