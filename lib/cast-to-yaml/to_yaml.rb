module C

  class Node

    def to_h_split
      res = {}
      kind = self.class.kind
      res["kind"] = kind
      fields.each do |f|
        name = f.init_key.to_s
        value = self.send(f.reader)
        if value && !(value == f.make_default)
          res[name] =
            if f.child?
              if value.kind_of? C::NodeList
                value.collect { |n| n.to_h_split }
              else
                value.to_h_split
              end
            else
              value
            end
        end
      end
      return res
    end

  end

  class Declarator
    def to_h_split(declaration)
      res = {}
      res["name"] = name.dup
      res["type"] = if indirect_type
          indirect_type.to_h_split(declaration)
        else
          declaration.type.to_h_split
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
      # Anonymous nested composites
      if declarators.empty?
        if (type.kind_of?(Struct) || type.kind_of?(Union)) && type.members && !type.name
          [{"type" => self.type.to_h_split}]
        end
      else
        declarators.collect { |d|
          res = d.to_h_split(self)
          res["storage"] = storage.to_s if storage
          res["inline"] = true if inline?
          res
        }
      end
    end

    def extract(res = Hash::new { |h, k| h[k] = [] }, declarations: true)
      if typedef?
        declarators.each { |d|
          res["typedefs"].push d.to_h_split(self)
        }
      else
        declarators.each { |d|
          if d.indirect_type && d.indirect_type.kind_of?(Function)
            f = {}
            f["name"] = d.name
            if d.indirect_type.type
              f["type"] = d.indirect_type.type.to_h_split(self)
            else
              f["type"] = type.to_h_split(self)
            end
            if d.indirect_type.params
              f["params"] = d.indirect_type.params.collect { |p| p.to_h_split }
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
          elsif declarations
            r = d.to_h_split(self)
            r["storage"] = storage.to_s if storage
            r["inline"] = true if inline?
            res["declarations"].push r
          end
        }
      end
      if type.kind_of?(Struct) && type.members
        m = []
        type.members.each { |mem|
          mem.extract(res, declarations: false)
          m += mem.to_a
        }
        if type.name
          s = {}
          s["name"] = type.name
          s["members"] = m
          res["structs"].push s
        end
      elsif type.kind_of?(Enum) && type.members && (type.name || (declarators.empty? && declarations))
        s = {}
        s["name"] = type.name if type.name
        m = []
        type.members.each { |mem|
          m.push mem.to_h_split
        }
        s["members"] = m
        res["enums"].push s
      elsif type.kind_of?(Union) && type.members
        m = []
        type.members.each { |mem|
          mem.extract(res, declarations: false)
          m += mem.to_a
        }
        if type.name
          s = {}
          s["name"] = type.name
          s["members"] = m
          res["unions"].push s
        end
      end
      res
    end
  end

  class TranslationUnit
    def extract_declarations(res = Hash::new { |h, k| h[k] = [] })
      entities.select { |e|
        e.kind_of? Declaration
      }.each { |e|
        e.extract(res, declarations: true)
      }
      res
    end
  end

  int_longnesses   = ['short ', '', 'long ', 'long long ']
  float_longnesses = ['float', 'double', 'long double']
  ## DirectTypes
  class Struct
    def to_h_split(_ = nil)
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
    def to_h_split(_ = nil)
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
    def to_h_split
      res = {}
      res["kind"] = "enum"
      if name
        res["name"] = name
      else
        m = []
        members.each { |mem|
          m.push mem.to_h_split
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
    def to_h_split
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
    c.send(:define_method, :to_h_split) do |_ = nil|
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
    def to_h_split(declaration = nil)
      res = {}
      res["kind"] = "pointer"
      res["const"] = true if const?
      res["restrict"] = true if restrict?
      res["volatile"] = true if volatile?
      if type
        if declaration
          res["type"] = type.to_h_split(declaration)
        else
          res["type"] = type.to_h_split
        end
      else
        res["type"] = declaration.type.to_h_split
      end
      res
    end
  end

  class Array
    def to_h_split(declaration = nil)
      res = {}
      res["kind"] = "array"
      if type
        if declaration
          res["type"] = type.to_h_split(declaration)
        else
          res["type"] = type.to_h_split
        end
      else
        res["type"] = declaration.type.to_h_split
      end
      if length
        res["length"] = length.to_s
      end
      res
    end
  end

  class Function
    def to_h_split(declaration, no_types=false)
      res = {}
      res["kind"] = "function"
      if type
        res["type"] = type.to_h_split(declaration)
      else
        res["type"] = declaration.type.to_h_split
      end
      if !params.nil?
        res["params"] = if no_types
            params.collect{|p| p.name }
          else
            params.collect{|p| p.to_h_split }
          end
      end
      if var_args?
        res["var_args"] = true
      end
      res
    end
  end

  class Parameter
    def to_h_split
      res = {}
      res["name"] = name.to_s if name.to_s != ''
      res["type"] = type.to_h_split
      res["register"] = true if register?
      res
    end
  end

end
