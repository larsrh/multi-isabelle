theory Multi_Isabelle_Test
imports Multi_Isabelle
begin

ML\<open>
fun test p t = @{assert} (ML_Cond.raw_match (String.explode p, String.explode t));
fun test_neg p t = @{assert} (not (ML_Cond.raw_match (String.explode p, String.explode t)));

test "abc" "abc";
test_neg "abc" "ab";
test_neg "ab" "abc";
test "ab*d" "abcd";
test "ab*d" "abd";
test "ab*d" "abccd";
test_neg "ab*d" "abc";
\<close>

ML \<open>val r = Unsynchronized.ref 0\<close>

ML_cond ("*") \<open>r := 1\<close>

ML \<open>@{assert} (!r = 1)\<close>

ML_cond (~ "*") \<open>@{assert} false\<close>

ML_cond (~ "*", "*") \<open>r := 2\<close>

ML \<open>@{assert} (!r = 2)\<close>

end