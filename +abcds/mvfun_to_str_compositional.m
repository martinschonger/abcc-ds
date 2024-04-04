% Copyright © 2024 Martin Schonger
% This software is licensed under the GPLv3.


function [str_repr, str_arr] = mvfun_to_str_compositional(mvfun, dim, idxs, precision)
% multivariate symbolic -> string

arguments
    mvfun;
    dim;
    idxs = 1:dim;
    precision = 16;
end

str_repr = append(inputname(1), "(x) = ");
indent_str = blanks(strlength(str_repr));
x = vpa(sym('x', [dim, 1], 'real'), precision);
str_arr = string(vpa(sym(mvfun(x(idxs))), precision));
for m = 1:length(str_arr)
    if m == 1
        str_repr = append(str_repr, "[", str_arr(m), "]");
    else
        str_repr = append(str_repr, indent_str, "[", str_arr(m), "]");
    end

    if m < length(str_arr)
        str_repr = append(str_repr, "\n");
    end
end

end