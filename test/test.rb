[ '../lib', 'lib' ].each { |d| $:.unshift(d) if File::directory?(d) }
require 'minitest/autorun'
require 'cast-to-yaml'
require 'pp'
require 'yaml'

class CastToYamlTest < Minitest::Test

  def self.generate_test(name, input, output)
    define_method(:"test_#{name}") {
      a = C::Parser::new.parse input
      assert_equal(YAML::load(output), a.extract_declarations)
    }
  end

  TESTS = [
  [ :typedef, <<EOF1, <<EOF2 ],
typedef int * intptr;
typedef float myfloat;
EOF1
typedefs:
- name: intptr
  type:
    kind: pointer
    type:
      kind: int
      name: int
- name: myfloat
  type:
    kind: float
    name: float
EOF2

  [ :pointer, <<EOF1, <<EOF2 ],
int * intptr;
EOF1
declarations:
- name: intptr
  type:
    kind: pointer
    type:
      kind: int
      name: int
EOF2

  [ :static_pointer, <<EOF1, <<EOF2 ],
static int * intptr;
EOF1
declarations:
- name: intptr
  type:
    kind: pointer
    type:
      kind: int
      name: int
  storage: static
EOF2

  [ :array, <<EOF1, <<EOF2 ],
int a[5];
EOF1
declarations:
- name: a
  type:
    kind: array
    type:
      kind: int
      name: int
    length: "5"
EOF2

  [ :function_pointer, <<EOF1, <<EOF2 ],
int (*f)(int a);
EOF1
declarations:
- name: f
  type:
    kind: pointer
    type:
      kind: function
      type:
        kind: int
        name: int
      params:
      - name: a
        type:
          kind: int
          name: int
EOF2

  [ :function, <<EOF1, <<EOF2 ],
int f(int a);
EOF1
functions:
- name: f
  type:
    kind: int
    name: int
  params:
  - name: a
    type:
      kind: int
      name: int
EOF2

  [ :inline_function, <<EOF1, <<EOF2 ],
inline int f(int a);
EOF1
functions:
- name: f
  type:
    kind: int
    name: int
  params:
  - name: a
    type:
      kind: int
      name: int
  inline: true
EOF2

  [ :static_function, <<EOF1, <<EOF2 ],
static int f(int a);
EOF1
functions:
- name: f
  type:
    kind: int
    name: int
  params:
  - name: a
    type:
      kind: int
      name: int
  storage: static
EOF2

  [ :union, <<EOF1, <<EOF2 ],
union u {
  int a;
  float b;
};
EOF1
unions:
- name: u
  members:
  - name: a
    type:
      kind: int
      name: int
  - name: b
    type:
      kind: float
      name: float
EOF2

  [ :typedef_union, <<EOF1, <<EOF2 ],
typedef union u {
  int a;
  float b;
} u_t;
EOF1
typedefs:
- name: u_t
  type:
    name: u
    kind: union
unions:
- name: u
  members:
  - name: a
    type:
      kind: int
      name: int
  - name: b
    type:
      kind: float
      name: float
EOF2

  [ :anonymous_union, <<EOF1, <<EOF2 ],
union {
  int a;
  float b;
} u;
EOF1
declarations:
- name: u
  type:
    kind: union
    members:
    - name: a
      type:
        kind: int
        name: int
    - name: b
      type:
        kind: float
        name: float
EOF2

  [ :anonymous_union_typedef, <<EOF1, <<EOF2 ],
typedef union {
  int a;
  float b;
} u_t;
EOF1
typedefs:
- name: u_t
  type:
    kind: union
    members:
    - name: a
      type:
        kind: int
        name: int
    - name: b
      type:
        kind: float
        name: float
EOF2

  [ :enum, <<EOF1, <<EOF2 ],
enum e {
  ONE = 1,
  TWO
};
EOF1
enums:
- name: e
  members:
  - name: ONE
    val: "1"
  - name: TWO
EOF2

  [ :typedef_enum, <<EOF1, <<EOF2 ],
typedef enum e {
  ONE = 1,
  TWO
} e_t;
EOF1
typedefs:
- name: e_t
  type:
    name: e
    kind: enum
enums:
- name: e
  members:
  - name: ONE
    val: "1"
  - name: TWO
EOF2

  [ :anonymous_enum, <<EOF1, <<EOF2 ],
enum {
  ONE = 1,
  TWO
} e;
EOF1
declarations:
- name: e
  type:
    kind: enum
    members:
    - name: ONE
      val: "1"
    - name: TWO
EOF2

  [ :anonymous_enum_typedef, <<EOF1, <<EOF2 ],
typedef enum {
  ONE = 1,
  TWO
} e_t;
EOF1
typedefs:
- name: e_t
  type:
    kind: enum
    members:
    - name: ONE
      val: "1"
    - name: TWO
EOF2

  [ :struct, <<EOF1, <<EOF2 ],
struct s {
  int a;
  float b;
};
EOF1
structs:
- name: s
  members:
  - name: a
    type:
      kind: int
      name: int
  - name: b
    type:
      kind: float
      name: float
EOF2

  [ :typedef_struct, <<EOF1, <<EOF2 ],
typedef struct s {
  int a;
  float b;
} s_t;
EOF1
typedefs:
- name: s_t
  type:
    name: s
    kind: struct
structs:
- name: s
  members:
  - name: a
    type:
      kind: int
      name: int
  - name: b
    type:
      kind: float
      name: float
EOF2

  [ :anonymous_struct, <<EOF1, <<EOF2 ],
struct {
  int a;
  float b;
} s;
EOF1
declarations:
- name: s
  type:
    kind: struct
    members:
    - name: a
      type:
        kind: int
        name: int
    - name: b
      type:
        kind: float
        name: float
EOF2

  [:function_struct_param, <<EOF1, <<EOF2 ],
int f(struct toto t);
EOF1
functions:
- name: f
  type:
    kind: int
    name: int
  params:
  - name: t
    type:
      kind: struct
      name: toto
EOF2

  [:function_returns_struct_param, <<EOF1, <<EOF2 ],
struct toto f(int a);
EOF1
functions:
- name: f
  type:
    kind: struct
    name: toto
  params:
  - name: a
    type:
      kind: int
      name: int
EOF2

  [ :anonymous_struct_typedef, <<EOF1, <<EOF2 ],
typedef struct {
  int a;
  float b;
} s_t;
EOF1
typedefs:
- name: s_t
  type:
    kind: struct
    members:
    - name: a
      type:
        kind: int
        name: int
    - name: b
      type:
        kind: float
        name: float
EOF2

  [ :init, <<EOF1, <<EOF2 ],
double a = 4.0;
EOF1
declarations:
- name: a
  type:
    kind: float
    name: double
  init: "4.0"
EOF2

  [ :var_args, <<EOF1, <<EOF2 ],
int f(int a, ...);
EOF1
functions:
- name: f
  type:
    kind: int
    name: int
  params:
  - name: a
    type:
      kind: int
      name: int
  var_args: true
EOF2

  [ :var_args_function_pointer, <<EOF1, <<EOF2 ],
int (*f)(int a, ...);
EOF1
declarations:
- name: f
  type:
    kind: pointer
    type:
      kind: function
      type:
        kind: int
        name: int
      params:
      - name: a
        type:
          kind: int
          name: int
      var_args: true
EOF2

  ]

  TESTS.each { |name, input, output|
    generate_test(name, input, output)
  }

end
