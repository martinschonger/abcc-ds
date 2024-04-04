% Copyright © 2024 Martin Schonger
% This software is licensed under the GPLv3.


function [func_handle] = sdpvar_to_fun_compositional(sdpexpr, x)

func_handle = sdisplay(sdpexpr, abcds.util.constants.PRECISION);
func_handle = func_handle{1};
func_handle = replace(func_handle, '*', '.*');
func_handle = replace(func_handle, '^', '.^');

for i = 1:length(x)
    func_handle = replace(func_handle, strcat("x(", int2str(i), ")"), strcat("x(", int2str(i), ",:)"));
end

func_handle = eval(['@(x)', func_handle]);

end