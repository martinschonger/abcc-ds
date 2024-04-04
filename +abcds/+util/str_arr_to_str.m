% Copyright © 2024 Martin Schonger
% This software is licensed under the GPLv3.


function str = str_arr_to_str(str_arr, opts)

arguments
    str_arr
    opts.function_name = abcds.util.constants.F_VAR
    opts.variable_name = abcds.util.constants.STATE_VAR
end

dim = length(str_arr);

left_side = opts.function_name + "(" + opts.variable_name + ") = [";
indent_str = "" + blanks(strlength(left_side));
str = "";
for d = 1:dim
    cur_str = "";
    if d == 1
        cur_str = append(cur_str, left_side);
    else
        cur_str = append(cur_str, indent_str);
    end
    cur_str = append(cur_str, str_arr(d));
    if d < dim
        cur_str = append(cur_str, ";\n");
    else
        cur_str = append(cur_str, "]");
    end
    str = append(str, cur_str);
end

end