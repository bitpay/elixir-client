ExUnit.start()

#def an_illegal_claim_code
#  legal_map = [*'A'..'Z'] + [*'a'..'z'] + [*0..9]
#  first_length = rand(6)
#  short_code = (0..first_length).map{legal_map.sample}.join
#  second_length = [*8..25].sample
#  long_code = [*8..25].sample.times.inject([]){|arr| arr << legal_map.sample}.join
#  [nil, short_code, long_code].sample
#end                           
