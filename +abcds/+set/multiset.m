% Copyright © 2024 Martin Schonger
% This software is licensed under the GPLv3.


classdef multiset < matlab.mixin.Copyable
    properties
        sets cell
    end
    methods
        function obj = multiset(set_in)
            arguments (Repeating)
                set_in abcds.set.set
            end
            obj.sets = set_in;
        end

        function res = isempty(obj)
            res = isempty(obj.sets);
        end

        function sets_cell = to_cell(obj)
            sets_cell = {};
            for i = 1:length(obj.sets)
                sets_cell{end+1} = obj.sets{i}.fh;
            end
        end

        function obj = scale_me(obj, factor)
            for i = 1:length(obj.sets)
                obj.sets{i} = obj.sets{i}.get_scaled(factor);
            end
        end

        function obj = shift_me(obj, shift)
            for i = 1:length(obj.sets)
                obj.sets{i} = obj.sets{i}.get_shifted(shift);
            end
        end

        function plt_obj = plot(obj, dim1, dim2, opts)
            arguments
                obj abcds.set.multiset
                dim1(1, 1) {mustBeInteger} = 1
                dim2(1, 1) {mustBeInteger} = 2
                opts.axlim1 = [-1, 1]
                opts.axlim2 = [-1, 1]
                opts.resolution = 0.01
                opts.level = 0
                opts.other_dims_values
                opts.plt_opts = {}
            end

            opts_cell = abcds.util.struct_to_named_cellarray(opts);
            for i = 1:length(obj.sets)
                plt_obj{i} = obj.sets{i}.plot(dim1, dim2, opts_cell{:});
            end
        end

        function plt_obj = plot3(obj, dim1, dim2, dim3, opts)
            arguments
                obj abcds.set.multiset
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

            if isempty(obj.sets)
                plt_obj = [];
                return;
            end
            
            for i = 1:length(obj.sets)
                if obj.sets{i}.dim > 3
                    assert(false, 'Untested');
                end
            end

            scatter3([], [], [], 'handlevisibility', 'off');

            [X, Y, Z] = meshgrid(opts.axlim1(1)-opts.resolution:opts.resolution:opts.axlim1(2)+opts.resolution, opts.axlim2(1)-opts.resolution:opts.resolution:opts.axlim2(2)+opts.resolution, opts.axlim3(1)-opts.resolution:opts.resolution:opts.axlim3(2)+opts.resolution);
            XYZ = zeros(obj.sets{1}.dim, size(X(:)', 2));
            XYZ(dim1, :) = X(:)';
            XYZ(dim2, :) = Y(:)';
            XYZ(dim3, :) = Z(:)';

            tmp = obj.sets{1}.fh(XYZ);
            for i = 2:length(obj.sets)
                tmp = min(tmp, obj.sets{i}.fh(XYZ));
            end
            fun_eval = reshape(tmp, size(X));

            isurf = isosurface(X, Y, Z, fun_eval, opts.level);
            plt_obj = patch(isurf, 'facecolor', 'black', 'facealpha', 0.35, 'edgecolor', 'none', opts.plt_opts{:});
            hold on;
            axis equal;
        end

        function plt_obj = plot1(obj, dim1, opts)
            arguments
                obj abcds.set.multiset
                dim1(1, 1) {mustBeInteger} = 1
                opts.axlim1 = [-1, 1]
                opts.resolution = 0.001
                opts.level = 0
                opts.other_dims_values
                opts.plot_on_y = false
                opts.plt_opts = {}
            end

            opts_cell = abcds.util.struct_to_named_cellarray(opts);
            for i = 1:length(obj.sets)
                plt_obj{i} = obj.sets{i}.plot1(dim1, opts_cell{:});
            end
        end

        function str = string(obj)
            tmp_str = string(obj.sets);
            str = join(tmp_str', newline);
        end
    end
end

%#ok<*AGROW>