[ '../lib', 'lib' ].each { |d| $:.unshift(d) if File::directory?(d) }
require 'minitest/autorun'
require 'cast-to-yaml'
require 'yaml'
require 'pp'

class CastToYamlFromHTest < Minitest::Test

  def self.generate_test(name, input)
    define_method(:"test_#{name}") {
      a = C::Parser::new.parse input
      assert_equal(a, C.from_h(a.to_h))
    }
  end

  TESTS = [
    [ :typedef, <<EOF1 ],
typedef int * intptr;
typedef float myfloat;
EOF1

  [ :var_args, <<EOF1 ],
int f(int a, ...);
EOF1

  [ :blocks, <<EOF1 ],
int f(int a) {
  for (int i = 0; i < 5; i++) a++;
  return a;
}
EOF1

  [ :void_func, <<EOF1 ],
int f();
EOF1

  ]

  TESTS.each { |name, input|
    generate_test(name, input)
  }

end
