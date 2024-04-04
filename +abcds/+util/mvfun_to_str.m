% Copyright © 2024 Martin Schonger
% This software is licensed under the GPLv3.


function [str_repr, str_arr] = mvfun_to_str(mvfun, dim, precision)
% multivariate symbolic -> string

arguments
    mvfun;
    dim;
    precision = 16;
end

str_repr = append(inputname(1), "(xi) = ");
indent_str = blanks(strlength(str_repr));
xi = vpa(sym('xi', [dim, 1], 'real'), precision);
str_arr = string(vpa(mvfun(xi), precision));
for m = 1:length(str_arr)
    if m == 1
        str_repr = append(str_repr, "[", str_arr(m), "]");
    else
        str_repr = append(str_repr, indent_str, "[", str_arr(m), "]");
    end
end

end