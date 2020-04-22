module C

  class Node

    #
    # Serialize a node to a Hash representation.
    #
    def to_h
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
                value.collect { |n| n.to_h }
              else
                value.to_h
              end
            else
              value
            end
        end
      end
      return res
    end

    private

    def self.kind
      @kind ||= name.split('::').last.
        gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2').
        gsub(/([a-z])([A-Z])/, '\1_\2').downcase
    end

    #
    # Deserialize a node from a given Hash representation.
    #
    def self.from_h(h)
      params = {}
      fields.each do |f|
        name = f.init_key
        value = h[name.to_s]
        if value
          params[name] =
            if f.child?
              default = f.make_default
              if default.kind_of?(C::NodeList) || value.kind_of?(::Array)
                raise ArgumentError, "node is not a list" unless value.kind_of? ::Array
                default = C::NodeArray.new unless default
                default.push(*(value.collect { |c| C.from_h(c) }))
              else
                C.from_h(value)
              end
            else
              value
            end
        end
      end
      return self.new(params)
    end

  end

  #
  # Deserialize an AST from a given Hash representation.
  #
  def self.from_h(h)
    kind = h["kind"]
    raise ArgumentError, "missing node kind" unless kind
    klass = C.const_get(class_name_from_kind(kind))
    raise ArgumentError, "unknown node" unless klass
    return klass.send(:from_h, h)
  end

  private

  def self.class_name_from_kind(kind)
    kind.split("_").collect(&:capitalize).join
  end

end
