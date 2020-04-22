[ '../lib', 'lib' ].each { |d| $:.unshift(d) if File::directory?(d) }
require 'minitest/autorun'
require 'cast-to-yaml'
require 'yaml'
require 'pp'

class CastToYamlToHTest < Minitest::Test

  def self.generate_test(name, input, output)
    define_method(:"test_#{name}") {
      a = C::Parser::new.parse input
      assert_equal(YAML::load(output), a.to_h)
    }
  end

  TESTS = [
    [ :typedef, <<EOF1, <<EOF2 ],
typedef int * intptr;
typedef float myfloat;
EOF1
kind: translation_unit
entities:
- kind: declaration
  storage: :typedef
  type:
    kind: int
  declarators:
  - kind: declarator
    indirect_type:
      kind: pointer
    name: intptr
- kind: declaration
  storage: :typedef
  type:
    kind: float
  declarators:
  - kind: declarator
    name: myfloat
EOF2

  [ :var_args, <<EOF1, <<EOF2 ],
int f(int a, ...);
EOF1
kind: translation_unit
entities:
- kind: declaration
  type:
    kind: int
  declarators:
  - kind: declarator
    indirect_type:
      kind: function
      params:
      - kind: parameter
        type:
          kind: int
        name: a
      var_args: true
    name: f
EOF2

  [ :blocks, <<EOF1, <<EOF2 ],
int f(int a) {
  for (int i = 0; i < 5; i++) a++;
  return a;
}
EOF1
kind: translation_unit
entities:
- kind: function_def
  type:
    kind: function
    type:
      kind: int
    params:
    - kind: parameter
      type:
        kind: int
      name: a
  name: f
  def:
    kind: block
    stmts:
    - kind: for
      init:
        kind: declaration
        type:
          kind: int
        declarators:
        - kind: declarator
          name: i
          init:
            kind: int_literal
            val: 0
      cond:
        kind: less
        expr1:
          kind: variable
          name: i
        expr2:
          kind: int_literal
          val: 5
      iter:
        kind: post_inc
        expr:
          kind: variable
          name: i
      stmt:
        kind: expression_statement
        expr:
          kind: post_inc
          expr:
            kind: variable
            name: a
    - kind: return
      expr:
        kind: variable
        name: a
EOF2

  [ :void_func, <<EOF1, <<EOF2 ],
int f();
EOF1
kind: translation_unit
entities:
- kind: declaration
  type:
    kind: int
  declarators:
  - kind: declarator
    indirect_type:
      kind: function
    name: f
EOF2

  ]

  TESTS.each { |name, input, output|
    generate_test(name, input, output)
  }

end
