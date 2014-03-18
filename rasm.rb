#coding: utf-8
class Rasm
  @@VERSION="1.0.319"
  @@op=nil
  def initialize
    @rgs=Hash.new
    @inst=[]
    @jmp_table=Hash.new
    @line=0
    @@op or init_instruct
  end
  def init_instruct
    @@op=Hash.new
    @@op[:movc]=->(rgs,klass){
      @rgs[rgs]=Kernel.const_get(klass)
    }
    @@op[:movr]=->(rgs_dst,rgs_src){
      @rgs[rgs_dst]=@rgs[rgs_src]
    }
    @@op[:movi]=->(rgs,value){
      @rgs[rgs]=value
    }
    
    @@op[:save]=->(rgs,key,src){
      @rgs[rgs][key]=@rgs[src]
    }
    @@op[:call]=->(rgs,to,fun,*arg){
      @rgs[to]=@rgs[rgs].method(fun).call(*arg)
    }
    
    @@op[:puts]=->(rgs){
      puts @rgs[rgs]
    }
    @@op[:dbp]=->(rgs){
      p @rgs[rgs]
    }
    @@op[:prt]=->(rgs){
      print @rgs[rgs]
    }
    
    @@op[:je]=->(a,b,dst){
      if @rgs[a]==@rgs[b]
        @line=@jmp_table[dst]
      end
    }
    @@op[:jne]=->(a,b,dst){
      if @rgs[a]!=@rgs[b]
        @line=@jmp_table[dst]
      end
    }
    @@op[:jmp]=->(dst){
      @line=@jmp_table[dst]
    }    
  end
  def run
    begin
      while @line<@inst.size
        op,*arg=@inst[@line]
        @@op[op].call(*arg)
        @line+=1
      end
    rescue =>e
      p e
      print "error inst: "
      puts @inst[@line]
      return
    end
  end
  def load(string)
    string.each_line{|line|
      line.chomp!
      line.lstrip!
      line.size==0 and next
      word=''
      ary=[]
      in_string=false
      line.each_char{|char|
        if char!=','
          if char=='"'
              in_string=!in_string
          end
          word<<char
        else
          if in_string
            word<<char
          else
            ary<<word
            word=''
          end
        end
      }
      ary<<word
      if ary.size==1
        @jmp_table[ary[0].match(/#(.*)/)[1].to_sym]=@inst.size-1
      elsif ary.size==0
        next
      else
        inst=[]
        ary.each{|val|
          if val.size==0
            next
          elsif val[0]==':'
            inst<<val.match(/:(.*)/)[1].to_sym
          elsif val.to_i!=0
            inst<<val.to_i
          elsif val[0]=='"'&&val[-1]=='"'
            inst<<val[1,val.size-2]
          elsif val[0]=='#'
            inst<<val[1,val.size-1].to_sym
          else
            inst<<val
          end
        }
        @inst<<inst
      end
    }
  end
  def marshal_load(ary)
    data=ary[0]
    @inst=data[:inst]
    @jmp_table=data[:jmp_table]
    @line=data[:line]
    @rgs=data[:rgs]
    
    @@op or init_instruct
  end
  def marshal_dump
    [{inst: @inst,jmp_table:@jmp_table,line: @line,rgs: @rgs}]
  end
end