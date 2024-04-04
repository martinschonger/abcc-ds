% Copyright © 2024 Martin Schonger
% This software is licensed under the GPLv3.


function str = str_arr_to_lambda(str_arr, opts)

arguments
    str_arr
    opts.variable_name = abcds.util.constants.STATE_VAR
end

dim = length(str_arr);

left_side = "@(" + opts.variable_name + ") [";
str = "";
for d = 1:dim
    cur_str = "";
    if d == 1
        cur_str = append(cur_str, left_side);
    end
    cur_str = append(cur_str, str_arr(d));
    if d < dim
        cur_str = append(cur_str, "; ");
    else
        cur_str = append(cur_str, "]");
    end
    str = append(str, cur_str);
end

end