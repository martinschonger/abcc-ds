% Copyright © 2024 Martin Schonger
% This software is licensed under the GPLv3.


classdef set < matlab.mixin.Copyable
    properties
        fh
        dim
    end
    methods
        function obj = set(fh_in, dim)
            obj.fh = fh_in;
            obj.dim = dim;
        end

        function new_obj = get_scaled(obj, factor)
            if size(factor, 1) ~= obj.dim
                warning("Dimensions should agree.");
            end
            new_obj = abcds.set.set(@(x) obj.fh(x(1:obj.dim, :).*factor(1:obj.dim, :)), obj.dim);
        end

        function new_obj = get_shifted(obj, shift)
            if size(shift, 1) ~= obj.dim
                warning("Dimensions should agree.");
            end
            new_obj = abcds.set.set(@(x) obj.fh(x(1:obj.dim, :)+shift(1:obj.dim, :)), obj.dim);
        end
        
        function plt_obj = plot(obj, dim1, dim2, opts)
            arguments
                obj abcds.set.set
                dim1(1, 1) {mustBeInteger} = 1
                dim2(1, 1) {mustBeInteger} = 2
                opts.axlim1 = [-1, 1]
                opts.axlim2 = [-1, 1]
                opts.resolution = 0.01
                opts.level = 0
                opts.other_dims_values
                opts.plt_opts = {}
            end

            if obj.dim > 2
                assert(false, 'Untested');
            end

            [X, Y] = meshgrid(opts.axlim1(1)-opts.resolution:opts.resolution:opts.axlim1(2)+opts.resolution, opts.axlim2(1)-opts.resolution:opts.resolution:opts.axlim2(2)+opts.resolution);
            XY = zeros(obj.dim, size(X(:)', 2));
            XY(dim1, :) = X(:)';
            XY(dim2, :) = Y(:)';

            if isfield(opts, 'other_dims_values')
                cur_idx = 1;
                for i = 1:obj.dim
                    if i == dim1 || i == dim2
                        continue;
                    end
                    XY(i, :) = opts.other_dims_values(cur_idx) * ones(1, size(XY, 2));
                    cur_idx = cur_idx + 1;
                end
            end

            fun_eval = reshape(obj.fh(XY), size(X));

            [~, plt_obj] = contourf(X, Y, fun_eval, [opts.level, opts.level], 'linewidth', 1, 'edgecolor', 'black', 'edgealpha', 1, 'facecolor', 'black', 'facealpha', 0.35, opts.plt_opts{:});
            hold on;
            axis equal;
        end

        function plt_obj = plot3(obj, dim1, dim2, dim3, opts)
            arguments
                obj abcds.set.set
                dim1(1, 1) {mustBeInteger} = 1
                dim2(1, 1) {mustBeInteger} = 2
                dim3(1, 1) {mustBeInteger} = 3
                opts.axlim1 = [-1, 1]
                opts.axlim2 = [-1, 1]
                opts.axlim3 = [-1, 1]
                opts.resolution = 0.021
                opts.level = 0
                opts.plt_opts = {}
            end

            if obj.dim > 3
                assert(false, 'Untested');
            end

            scatter3([], [], [], 'handlevisibility', 'off');

            [X, Y, Z] = meshgrid(opts.axlim1(1)-opts.resolution:opts.resolution:opts.axlim1(2)+opts.resolution, opts.axlim2(1)-opts.resolution:opts.resolution:opts.axlim2(2)+opts.resolution, opts.axlim3(1)-opts.resolution:opts.resolution:opts.axlim3(2)+opts.resolution);
            XYZ = zeros(obj.dim, size(X(:)', 2));
            XYZ(dim1, :) = X(:)';
            XYZ(dim2, :) = Y(:)';
            XYZ(dim3, :) = Z(:)';

            fun_eval = reshape(obj.fh(XYZ), size(X));

            isurf = isosurface(X, Y, Z, fun_eval, opts.level);
            plt_obj = patch(isurf, 'facecolor', 'black', 'facealpha', 0.35, 'edgecolor', 'none', opts.plt_opts{:});
            hold on;
            axis equal;
        end

        function plt_obj = plot1(obj, dim1, opts)
            arguments
                obj abcds.set.set
                dim1(1, 1) {mustBeInteger} = 1 % currently unused
                opts.axlim1 = [-1, 1]
                opts.resolution = 0.001
                opts.level = 0
                opts.other_dims_values
                opts.plot_on_y = false
                opts.plt_opts = {}
            end

            if obj.dim > 1
                assert(false, 'Untested');
            end

            X = opts.axlim1(1)-opts.resolution:opts.resolution:opts.axlim1(2)+opts.resolution;

            fun_eval = reshape(obj.fh(X), size(X));
            fun_gt0_idx = fun_eval >= opts.level;

            if ~opts.plot_on_y
                plt_obj = scatter(X(fun_gt0_idx), zeros(1, sum(fun_gt0_idx)), "square", "filled", "MarkerFaceAlpha", 0.35, "MarkerEdgeColor", "none", opts.plt_opts{:});
            else
                plt_obj = scatter(zeros(1, sum(fun_gt0_idx)), X(fun_gt0_idx), "square", "filled", "MarkerFaceAlpha", 0.35, "MarkerEdgeColor", "none", opts.plt_opts{:});
            end
            hold on;
        end

        function str = string(obj)
            str = append("fh=", abcds.util.mvfun_to_str(obj.fh, obj.dim));
            str = append(str, newline, "dim=", num2str(obj.dim));
        end
    end
end