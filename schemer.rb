def _eval(exp, env)
  if not list?(exp)
    if immediate_val?(exp)
      exp
    else
      lookup_var(exp, env)
    end
  else
    if special_form?(exp)
      eval_special_form(exp, env)
    else
      fun  = _eval(car(exp), env)
      args = eval_list(cdr(exp), env)
      apply(fun, args)
    end
  end
end

def special_form?(exp)
  lambda?(exp) or
      let?(exp) or
      letrec?(exp) or
      if?(exp)
end

def lambda?(exp)
  exp[0] == :lambda
end

def eval_special_form(exp, env)
  if lambda?(exp)
    eval_lambda(exp, env)
  elsif let?(exp)
    eval_let(exp, env)
  elsif letrec?(exp)
    eval_letrec(exp, env)
  elsif if?(exp)
    eval_if(exp, env)
  end
end

def eval_if(exp, env)
  cond, true_clause, false_clause = if_to_cond_true_false(exp)
  if _eval(cond, env)
    _eval(true_clause, env)
  else
    _eval(false_clause, env)
  end
end

def if_to_cond_true_false(exp)
  [exp[1], exp[2], exp[3]]
end

def if?(exp)
  exp[0] == :if
end

def eval_list(exp, env)
  exp.map { |e| _eval(e, env) }
end

def apply(fun, args)
  if primitive_fun?(fun)
    apply_primitive_fun(fun, args)
  else
    lambda_apply(fun, args)
  end
end

def primitive_fun?(exp)
  exp[0] == :prim
end

def list?(exp)
  exp.is_a?(Array)
end

$primitive_fun_env = {
    :+  => [:prim, lambda { |x, y| x + y }],
    :-  => [:prim, lambda { |x, y| x - y }],
    :*  => [:prim, lambda { |x, y| x * y }],
    :>  => [:prim, lambda { |x, y| x > y }],
    :>= => [:prim, lambda { |x, y| x >= y }],
    :<  => [:prim, lambda { |x, y| x < y }],
    :<= => [:prim, lambda { |x, y| x <= y }],
    :== => [:prim, lambda { |x, y| x == y }],
}

def car(list)
  list[0]
end

def cdr(list)
  list[1..-1]
end

def immediate_val?(exp)
  num?(exp)
end

def num?(exp)
  exp.is_a?(Numeric)
end

def apply_primitive_fun(fun, args)
  fun_val = fun[1]
  fun_val.call(*args)
end

def lookup_var(var, env)
  alist = env.find { |alist| alist.key?(var) }
  if alist == nil
    raise "couldn't find value to variables: '#{var}'"
  end
  alist[var]
end

def extend_env(parameters, args, env)
  alist = parameters.zip(args)
  h     = Hash.new
  alist.each { |k, v| h[k] = v }
  [h] + env
end

def eval_let(exp, env)
  parameters, args, body = let_to_parameters_args_body(exp)
  new_exp                = [[:lambda, parameters, body]] + args
  _eval(new_exp, env)
end

def let_to_parameters_args_body(exp)
  [exp[1].map { |e| e[0] }, exp[1].map { |e| e[1] }, exp[2]]
end

def let?(exp)
  exp[0] == :let
end

def eval_lambda(exp, env)
  make_closure(exp, env)
end

def make_closure(exp, env)
  parameters, body = exp[1], exp[2]
  [:closure, parameters, body, env]
end

def lambda_apply(closure, args)
  parameters, body, env = closure_to_parameters_body_env(closure)
  new_env               = extend_env(parameters, args, env)
  _eval(body, new_env)
end

def closure_to_parameters_body_env(closure)
  [closure[1], closure[2], closure[3]]
end

def eval_letrec(exp, env)
  parameters, args, body = letrec_to_parameters_args_body(exp)
  tmp_env                = Hash.new
  parameters.each do |parameter|
    tmp_env[parameter] = :dummy
  end
  ext_env  = extend_env(tmp_env.keys(), tmp_env.values(), env)
  args_val = eval_list(args, ext_env)
  set_extend_env!(parameters, args_val, ext_env)
  new_exp = [[:lambda, parameters, body]] + args
  _eval(new_exp, ext_env)
end

def set_extend_env!(parameters, args_val, ext_env)
  parameters.zip(args_val).each do |parameter, arg_val|
    ext_env[0][parameter] = arg_val
  end
end

def letrec_to_parameters_args_body(exp)
  let_to_parameters_args_body(exp)
end

def letrec?(exp)
  exp[0] == :letrec
end

def null?(list)
  list == []
end

def cons(a, b)
  if not list?(b)
    raise "sorry, we haven't implemented yet..."
  else
    [a] + b
  end
end

def list(*list)
  list
end

$list_env = {
    :nil   => [],
    :null? => [:prim, lambda { |list| null?(list) }],
    :cons  => [:prim, lambda { |a, b| cons(a, b) }],
    :car   => [:prim, lambda { |list| car(list) }],
    :cdr   => [:prim, lambda { |list| cdr(list) }],
    :list  => [:prim, lambda { |*list| list(*list) }],
}

$boolean_env = {true: true, false: false}
$global_env = [$list_env, $primitive_fun_env, $boolean_env]

exp =
    [:letrec,
     [[:fact,
       [:lambda, [:n], [:if, [:<, :n, 1], 1, [:*, :n, [:fact, [:-, :n, 1]]]]]]],
     [:fact, 5]]
puts _eval(exp, $global_env)
