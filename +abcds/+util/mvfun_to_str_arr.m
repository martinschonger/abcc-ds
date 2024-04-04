% Copyright © 2024 Martin Schonger
% This software is licensed under the GPLv3.


function [str_arr_vectorized, str_arr, opts] = mvfun_to_str_arr(f, dim, opts)
% multivariate symbolic -> string

arguments
    f
    dim
    opts.idxs = 1:dim
    opts.precision = abcds.util.constants.PRECISION
    opts.variable_name = abcds.util.constants.STATE_VAR
    opts.vectorize = true
end

x = vpa(sym(opts.variable_name, [dim, 1], 'real'), opts.precision);
str_arr = string(vpa(f(x(opts.idxs)), opts.precision));

str_arr_vectorized = str_arr;
if opts.vectorize
    for i = 1:length(str_arr)
        for d = dim:-1:1
            str_arr_vectorized(i) = replace(str_arr_vectorized(i), opts.variable_name+int2str(d), opts.variable_name+"("+int2str(d)+",:)");
        end
        str_arr_vectorized(i) = replace(str_arr_vectorized(i), '*', '.*');
        str_arr_vectorized(i) = replace(str_arr_vectorized(i), '^', '.^');
    end
end

end