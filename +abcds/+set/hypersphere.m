% Copyright © 2024 Martin Schonger
% This software is licensed under the GPLv3.


classdef hypersphere < abcds.set.set
    properties
        center
        radius
        select_dims
    end
    methods
        function obj = hypersphere(center, radius, args)
            arguments
                center
                radius
                args.select_dims = 1:size(center, 1)
            end
            obj@abcds.set.set(@(x) radius*radius-sum((x(args.select_dims, :) - center(args.select_dims)).^2, 1), size(center, 1));
            obj.center = center;
            obj.radius = radius;
            obj.select_dims = args.select_dims;
        end

        function str = string(obj)
            str = string@abcds.set.set(obj);
            str = append(str, newline, "center=[", abcds.util.arr_to_str(obj.center), "]'");
            str = append(str, newline, "radius=", num2str(obj.radius));
            str = append(str, newline, "select_dims=[", abcds.util.arr_to_str(obj.select_dims), "]'");
        end
    end
end