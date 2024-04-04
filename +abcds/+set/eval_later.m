% Copyright © 2024 Martin Schonger
% This software is licensed under the GPLv3.


classdef eval_later < abcds.set.set
    properties
        eval_expr string
    end
    methods
        function obj = eval_later(eval_expr)
            % eval_expr can contain variable names that will exist at the time of evaluation
            obj@abcds.set.set(@(x) x, 0);
            obj.eval_expr = eval_expr;
        end

        function str = string(obj)
            str = string@abcds.set.set(obj);
            str = append(str, newline, "eval_expr=", obj.eval_expr);
        end
    end
end