% Copyright © 2024 Martin Schonger
% This software is licensed under the GPLv3.


classdef ellipsoid < abcds.set.set
    properties
        center
        axes_length
        orientation
    end
    methods
        function obj = ellipsoid(center, axes_length, orientation)
            dim = size(center, 1);
            assert(dim == 2, 'Only 2D ellipsoids are supported at this time');
            obj@abcds.set.set(ellipse_axis_to_eq(center, axes_length, orientation), dim);
            obj.dim = dim;
            obj.center = center;
            obj.axes_length = axes_length;
            obj.orientation = orientation;
        end

        function str = string(obj)
            str = string@abcds.set.set(obj);
            str = append(str, newline, "center=[", abcds.util.arr_to_str(obj.center), "]'");
            str = append(str, newline, "axes_length=[", abcds.util.arr_to_str(obj.axes_length), "]'");
            str = append(str, newline, "orientation=[", abcds.util.arr_to_str(obj.orientation), "]'");
        end
    end
end