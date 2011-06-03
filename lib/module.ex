

module Module
  def blank_slate
    {'elixir_slate__, [], []}
  end

  % This module is included temporarily during method
  % definition with the *using* feature.
  module Using
    def __mixins__
      Erlang.elixir_object_methods.mixins(self)
    end  
  end

  module Behavior
    def mixin(module)
      Erlang.elixir_object_methods.mixin(self, module)
    end

    def __name__
      Erlang.elixir_object_methods.name(self)
    end

    % TODO Is this really needed?
    def __parent_name__
      Erlang.elixir_object_methods.parent_name(self)
    end

    % TODO Is this really needed?
    def __parent__
      Erlang.elixir_object_methods.parent(self)
    end

    % Returns a list of atoms representing all mixins for the current object.
    % The mixins chain is retrieved by getting the current object mixins and
    % appending all protos from its parents.
    %
    % ## Example
    %
    % Imagine the following definition:
    %
    %     object Foo
    %       mixin SomeMethods
    %     end
    %
    % The mixins chain for Foo is:
    %
    %     Foo.__mixins__  % => ['SomeMethods, 'Object::Methods]
    %
    % Where `SomeMethods` is a module mixed into `Foo` and the `Object::Methods`
    % is a module added as proto on `Foo` parent, which is the object `Object`:
    %
    %     Foo.__parent__  % => 'Object
    %
    % The mixins for `Foo.new` are these:
    %
    %     Foo.new.__mixins__ %=> ['MoreMethods, 'Object::Methods]
    %
    % Where `MoreMethods` is a module added as proto to `Foo.new` parent (which is `Foo`)
    % and `Object::Methods` is a proto on `Foo.new` grandparent (which is `Object`).
    %
    % If we added a mixin to `Foo.new`, we would have the following result:
    %
    %     Foo.new.mixin(MuchMoreMethods).__mixins__ %=> ['MuchMoreMethods, 'MoreMethods, 'Object::Methods]
    %
    % In other words, calculating the mixins chain is as simple as:
    %
    %     [self.exclusive_mixins, self.parent.exclusive_protos, self.parent.parent.exclusive_protos, ...]
    %
    % Until parent becomes empty (`Object` is the only object that does not have a parent).
    %
    % Notice that we don't have methods called `exclusive_mixins` and `exclusive_protos`,
    % they are mentioned just as examples.
    %
    % == Mixins inside object definitions
    %
    % In Elixir, all methods are carried in modules. Regular objects does not have methods per-se.
    % However, for convenience, Elixir allows you to define methods inside the object definition:
    %
    %     object Foo
    %       def bar
    %         'baz
    %       end
    %     end
    %
    % What happens internally is that Elixir automatically creates a module named `Foo::Proto`
    % and automatically adds it as `Foo` proto. In order for this to work properly, Elixir
    % adds `Module::Methods` as mixin during the object definition, but it is removed from
    % the mixins chain after the object is defined:
    %
    %     object Foo
    %       __mixins__   % => ['Module::Methods, 'Object::Methods]
    %     end
    %
    %     Foo.__mixins__ % => ['Object::Methods]
    %
    % TODO This is defined automatically!!!!
    %
    % def __mixins__
    %   Erlang.elixir_object_methods.mixins(self)
    % end

    def inspect
      name = __name__
      if name
        name.to_s
      else
        "<#{__parent_name__} #{get_ivars.inspect}>"
      end
    end

    def to_s
      self.inspect
    end

    def initialize
      self
    end

    def get_ivar(name)
      Erlang.elixir_object_methods.get_ivar(self, name)
    end

    % Returns a `Dict` with all variable names and values as its key-values.
    %
    % ## Example
    %
    %     object Foo
    %       def initialize
    %         @('bar: 1, 'baz: 2)
    %       end
    %     end
    %
    %     Foo.new.__ivars__ % => { 'bar: 1, 'baz: 2 }
    %
    def get_ivars
      OrderedDict.new Erlang.elixir_object_methods.data(self)
    end

    def set_ivar(name, value)
      Erlang.elixir_object_methods.set_ivar(self, name, value)
    end

    def set_ivars(value)
      Erlang.elixir_object_methods.set_ivars(self, value)
    end

    def update_ivar(name, fun)
      Erlang.elixir_object_methods.update_ivar(self, name, fun)
    end

    def update_ivar(name, initial, fun)
      Erlang.elixir_object_methods.update_ivar(self, name, initial, fun)
    end

    def send(method, args := [])
      Erlang.elixir_dispatch.dispatch(self, method, args)
    end

    % Those methods are related to methods introspection.

    def __mixin_methods__
      Erlang.elixir_methods.mixin_methods(self)
    end

    % Exceptions related methods

    def __stacktrace__
      filter_stacktrace Erlang.get_stacktrace
    end

    def error(reason)
      Erlang.error(reason)
    end

    def throw(reason)
      Erlang.throw(reason)
    end

    def exit(reason)
      Erlang.exit(reason)
    end

    def method_missing(method, args)
      error { 'nomethod, {method, Erlang.length(args), self} }
    end

    % Delegate the given methods to the given expression.
    %
    % ## Examples
    %
    %     module Counter
    %       def one; 1; end
    %       def two; 2; end
    %       def three; 3; end
    %       def sum(a, b) a+b; end
    %     end
    %
    %     module Delegator
    %       delegate ['one/0, 'two/0, 'three/0, 'sum/2], 'to: "Counter"
    %     end
    %
    %     Delegator.one       % => 1
    %     Delegator.sum(1, 2) % => 3
    %
    % Notice that the value given to 'to can be any expression:
    %
    %     module Three
    %       delegate ['abs/0], 'to: "(2-5)"
    %     end
    %
    %     Three.abs  % => 3
    %
    def delegate(pairs, options)
      object = options['to]

      pairs.each do ({name, arity})
        args = arity.times [], do (i, acc)
          ["x#{i}"|acc]
        end

        args_string = args.join(",")

        module_eval __FILE__, __LINE__ + 1, ~~ELIXIR
  def #{name}(#{args_string})
    #{object}.#{name}(#{args_string})
  end
~~
      end
    end

    % Receives a list of names and define a method for each name that
    % reads its respective instance variable.
    %
    % ## Example
    %
    %     module Car
    %       attr_reader ['color]
    %
    %       def initialize(color)
    %         @('color: color)
    %       end
    %     end
    %
    %     car = Car.new 'red
    %     car.color   % => 'red
    %
    def attr_reader(names)
      names.each do (name)
        module_eval __FILE__, __LINE__ + 1, ~~ELIXIR
  def #{name}
    @#{name}
  end
~~
      end
    end

    def attr_writer(names)
      names.each do (name)
        module_eval __FILE__, __LINE__ + 1, ~~ELIXIR
  def #{name}(value)
    @('#{name}, value)
  end
~~
      end
    end

    def attr_accessor(names)
      attr_reader names
      attr_writer names
    end

    % Hook invoked whenever this module is added as a mixin.
    % It receives the target module where the mixin is being added
    % as parameter and must return an module of the same kind.
    %
    % ## Example
    %
    % As an example, let's simply create a module that sets an
    % instance variable on the target object:
    %
    %     module Foo
    %       def __added_as_mixin__(base)
    %         base.set_ivar('baz, 13)
    %       end
    %     end
    %
    %     module Baz
    %       mixin Foo
    %       IO.puts @baz   % => 13
    %     end
    %
    % TODO: Rename to __mixed_in__
    def __added_as_mixin__(base)
      base
    end

    % Returns the current method visibility.
    def __visibility__
      Erlang.elixir_module_methods.get_visibility(self)
    end

    % Mark all methods defined next as public.
    def public
      Erlang.elixir_module_methods.set_visibility(self, 'public)
    end

    % Mark all methods defined next as protected.
    % TODO Remove it after it is on deprecation for awhile
    def protected
      Erlang.elixir_module_methods.set_visibility(self, 'protected)
    end

    % Mark all methods defined next as private.
    def private
      Erlang.elixir_module_methods.set_visibility(self, 'private)
    end

    % Receives a file, line and evaluates the given string in the context
    % of the module. This is good for dynamic method definition:
    %
    % ## Examples
    %
    %     module MyMethods
    %
    %       ["foo", "bar", "baz"].each -> (m)
    %         self.module_eval __FILE__, __LINE__ + 1, ~~ELIXIR
    %       def #{m}
    %         @#{m}
    %       end
    %     ~~
    %       end
    %
    %     end
    % 
    def module_eval(file, line, string)
      Erlang.elixir_module_methods.module_eval(self, string, file, line)
    end

    % Allow to add a method to the module using Erlang's abstract form.
    % The method automatically receives self as first argument.
    def define_erlang_method(file, line, method, arity, clauses)
      Erlang.elixir_module_methods.define_erlang_method(self, file, line, method, arity, clauses)
    end

    % Alias a local method. Aliasing a method defined in another module is done
    % by delegation.
    def alias_local(old, new, arity)
      Erlang.elixir_module_methods.alias_local(self, __FILE__, old, new, arity)
    end

    % Default behavior applied when a module is bound.
    def __bound__
      self
    end

    % Set the following methods to private.
    Erlang.elixir_module_methods.set_visibility(self, 'private)

    def filter_stacktrace(stacktrace)
      filter_stacktrace(stacktrace, [])
    end

    def filter_stacktrace([{raw_module, function, raw_arity}|t], buffer)
      if filtered = filter_stacktrace_module(raw_module.to_char_list)
        module = filtered
        arity = if raw_arity.__parent_name__ == 'Integer
          raw_arity - 1
        else
          raw_arity
        end
      else
        module = raw_module
        arity = raw_arity
      end

      filter_stacktrace t, [{module, function, arity}|buffer]
    end

    def filter_stacktrace([], buffer)
      buffer.reverse
    end

    def filter_stacktrace_module([$e, $x, h|t]) when h >= $A andalso h <= $Z
      Atom.from_char_list [h|t]
    end

    def filter_stacktrace_module(_)
      nil
    end
  end

  % Module::Methods is automatically mixed and proto'd by Elixir
  % runtime so we can bootstrap the module system.
  % mixin Module::Methods
  % proto Module::Methods
end