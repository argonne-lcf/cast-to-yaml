module C

  class Declarator
    def to_h(declaration)
      res = {}
      res["name"] = name.dup
      res["type"] = if indirect_type
          indirect_type.to_h(declaration)
        else
          declaration.type.to_h
        end
      if init
        res["init"] = init.to_s
      end
      if num_bits
        res["num_bits"] = num_bits.to_s
      end
      res
    end
  end

  class Declaration

    def to_a
      declarators.collect { |d|
        res = d.to_h(self)
        res["storage"] = storage.to_s if storage
        res["inline"] = true if inline?
        res
      }
    end

    def extract(res = Hash::new { |h, k| h[k] = [] })
      if typedef?
        declarators.each { |d|
          res["typedefs"].push d.to_h(self)
        }
      else
        declarators.each { |d|
          if d.indirect_type && d.indirect_type.kind_of?(Function)
            f = {}
            f["name"] = d.name
            if d.indirect_type.type
              f["type"] = d.indirect_type.type.to_h(self)
            else
              f["type"] = type.to_h(self)
            end
            if d.indirect_type.params
              f["params"] = d.indirect_type.params.collect { |p| p.to_h }
            end
            if d.indirect_type.var_args?
              f["var_args"] = true
            end
            if inline?
              f["inline"] = true
            end
            if storage
              f["storage"] = storage.to_s
            end
            
            res["functions"].push f
          else
            r = d.to_h(self)
            r["storage"] = storage.to_s if storage
            r["inline"] = true if inline?
            res["declarations"].push r
          end
        }
      end
      if type.kind_of?(Struct) && type.members && type.name
        s = {}
        s["name"] = type.name
        m = []
        type.members.each { |mem|
          m += mem.to_a
        }
        s["members"] = m
        res["structs"].push s
      elsif type.kind_of?(Enum) && type.members && type.name
        s = {}
        s["name"] = type.name
        m = []
        type.members.each { |mem|
          m.push mem.to_h
        }
        s["members"] = m
        res["enums"].push s
      elsif type.kind_of?(Union) && type.members && type.name
        s = {}
        s["name"] = type.name
        m = []
        type.members.each { |mem|
          m += mem.to_a
        }
        s["members"] = m
        res["unions"].push s
      end
      res
    end
  end

  class TranslationUnit
    def extract_declarations(res = Hash::new { |h, k| h[k] = [] })
      entities.select { |e|
        e.kind_of? Declaration
      }.each { |e|
        e.extract(res)
      }
      res
    end
  end

  int_longnesses   = ['short ', '', 'long ', 'long long ']
  float_longnesses = ['float', 'double', 'long double']
  ## DirectTypes
  class Struct
    def to_h
      res = {}
      res["kind"] = "struct"
      if name
        res["name"] = name
      else
        m = []
        members.each { |mem|
          m += mem.to_a
        }
        res["members"] = m
      end
      res["const"] = true if const?
      res["restrict"] = true if restrict?
      res["volatile"] = true if volatile?
      res
    end
  end

  class Union
    def to_h
      res = {}
      res["kind"] = "union"
      if name
        res["name"] = name
      else
        m = []
        members.each { |mem|
          m += mem.to_a
        }
        res["members"] = m
      end
      res["const"] = true if const?
      res["restrict"] = true if restrict?
      res["volatile"] = true if volatile?
      res
    end
  end

  class Enum
    def to_h
      res = {}
      res["kind"] = "enum"
      if name
        res["name"] = name
      else
        m = []
        members.each { |mem|
          m.push mem.to_h
        }
        res["members"] = m
      end
      res["const"] = true if const?
      res["restrict"] = true if restrict?
      res["volatile"] = true if volatile?
      res
    end
  end

  class Enumerator
    def to_h
      res = {}
      res["name"] = name
      if val
        res["val"] = val.to_s
      end
      res
    end
  end

  [
    [CustomType, proc{name.dup    }],
    [Void      , proc{'void'      }],
    [Int       , proc do
        longness_str = int_longnesses[longness+1].dup
        "#{unsigned? ? 'unsigned ' : ''}#{longness_str}int"
      end],
    [Float     , proc{float_longnesses[longness].dup}],
    [Char      , proc{"#{unsigned? ? 'unsigned ' : signed? ? 'signed ' : ''}char"}],
    [Bool      , proc{"_Bool"     }],
    [Complex   , proc{"_Complex #{float_longnesses[longness]}"}],
    [Imaginary , proc{"_Imaginary #{float_longnesses[longness]}"}]
  ].each do |c, x|
    c.send(:define_method, :to_h) do |_ = nil|
      res = {}
      if self.kind_of? CustomType
        res["kind"] = "custom_type"
      else
        res["kind"] = "#{self.class.name.split('::').last}".downcase
      end
      res["name"] = instance_eval(&x)
      res["const"] = true if const?
      res["restrict"] = true if restrict?
      res["volatile"] = true if volatile?
      res
    end
  end

  ## IndirectTypes
  class Pointer
    def to_h(declaration = nil)
      res = {}
      res["kind"] = "pointer"
      res["const"] = true if const?
      res["restrict"] = true if restrict?
      res["volatile"] = true if volatile?
      if type
        if declaration
          res["type"] = type.to_h(declaration)
        else
          res["type"] = type.to_h
        end
      else
        res["type"] = declaration.type.to_h
      end
      res
    end
  end
  class Array
    def to_h(declaration = nil)
      res = {}
      res["kind"] = "array"
      if type
        if declaration
          res["type"] = type.to_h(declaration)
        else
          res["type"] = type.to_h
        end
      else
        res["type"] = declaration.type.to_h
      end
      if length
        res["length"] = length.to_s
      end
      res
    end
  end
  class Function
    def to_h(declaration, no_types=false)
      res = {}
      res["kind"] = "function"
      if type
        res["type"] = type.to_h(declaration)
      else
        res["type"] = declaration.type.to_h
      end
      if !params.nil?
        res["params"] = if no_types
            params.collect{|p| p.name }
          else
            params.collect{|p| p.to_h }
          end
      end
      if var_args?
        res["var_args"] = true
      end
      res
    end
  end
  class Parameter
    def to_h
      res = {}
      res["name"] = name.to_s if name.to_s != ''
      res["type"] = type.to_h
      res["register"] = true if register?
      res
    end
  end

end
