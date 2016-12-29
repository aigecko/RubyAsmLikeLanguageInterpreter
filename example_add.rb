#coding: utf-8
require_relative 'rasm'
r=Rasm.new
r.load(
 'movi $a,0.3010
  movi $b,5
  call $a,$c,:+,$b
  puts $c')
r.run