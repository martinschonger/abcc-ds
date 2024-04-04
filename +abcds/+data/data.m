classdef data < matlab.mixin.Copyable
    % Uniform interface to reference data

    % Copyright © 2024 Martin Schonger
    % This software is licensed under the GPLv3.

    properties
        pos cell
        vel cell
        tvec cell
        target double
        state_maxnorm
        vel_maxnorm
        shift
    end

    methods
        function obj = data(args)
            arguments
                args.?abcds.data.data
            end

            abcds.util.log_msg("Initialize data directly");
            fieldnames_tmp = fieldnames(args);
            for field_idx = 1:length(fieldnames_tmp)
                obj.(fieldnames_tmp{field_idx}) = args.(fieldnames_tmp{field_idx});
            end

            tmp_target = zeros(obj.dim, 1);
            for i = 1:obj.num_traj
                tmp_target = tmp_target + obj.pos{i}(:, end);
            end
            obj.target = tmp_target / obj.num_traj;
            if isfield(args, 'target')
                if ~isequal(args.target, obj.target)
                    warning("target might be incorrect");
                end
                obj.target = args.target;
            end
            obj.state_maxnorm = ones(obj.dim, 1);
            obj.vel_maxnorm = ones(obj.dim, 1);
            obj.shift = zeros(obj.dim, 1);
        end

        function [Data, Pos, Vel, Tvec] = get_concatenated(obj)
            Pos = cat(2, obj.pos{:});
            Vel = cat(2, obj.vel{:});
            Data = [Pos; Vel];
            Tvec = cat(2, obj.tvec{:});
        end

        function d = dim(obj)
            d = size(obj.pos{1}, 1);
        end

        function d = num_traj(obj)
            d = size(obj.pos, 2);
        end

        function num_sam = total_num_samples(obj)
            num_sam = 0;
            for i = 1:obj.num_traj
                num_sam = num_sam + size(obj.pos{i}, 2);
            end
        end

        function obj = scale_me(obj, args)
            arguments
                obj
                args.state_maxnorm
                args.vel_maxnorm
                args.original_version = false
            end
            % Scale workspace and velocities to range/extent [0, 1]:
            [~, Pos, Vel] = get_concatenated(obj);

            if isfield(args, 'state_maxnorm')
                obj.state_maxnorm = args.state_maxnorm;
            else
                if ~args.original_version
                    obj.state_maxnorm = max(sqrt(Pos.^2), [], 2);
                else
                    tmp_state_maxnorm = max(sqrt(sum(Pos.^2, 1)));
                    obj.state_maxnorm = repmat(tmp_state_maxnorm, obj.dim, 1);
                end
            end
            if isfield(args, 'vel_maxnorm')
                obj.vel_maxnorm = args.vel_maxnorm;
            else
                if ~args.original_version
                    obj.vel_maxnorm = obj.state_maxnorm;
                else
                    tmp_vel_maxnorm = max(sqrt(sum(Vel.^2, 1)));
                    obj.vel_maxnorm = repmat(tmp_vel_maxnorm, obj.dim, 1);
                end
            end

            for i = 1:obj.num_traj
                obj.pos{i} = obj.pos{i} ./ obj.state_maxnorm;
                obj.vel{i} = obj.vel{i} ./ obj.vel_maxnorm;
            end

            if isfield(args, 'state_maxnorm')
                obj.state_maxnorm = ones(obj.dim, 1);
            end
            if isfield(args, 'vel_maxnorm')
                obj.vel_maxnorm = ones(obj.dim, 1);
            end

            abcds.util.log_msg("Scale data: state_maxnorm=%s, vel_maxnorm=%s", abcds.util.arr_to_str(obj.state_maxnorm), abcds.util.arr_to_str(obj.vel_maxnorm));
        end

        function obj = shift_me(obj, args)
            arguments
                obj
                args.shift
            end

            if isfield(args, 'shift')
                obj.shift = args.shift;
            else
                % Shift target to origin
                obj.shift = -obj.target;
            end

            for i = 1:obj.num_traj
                obj.pos{i} = obj.pos{i} + obj.shift;
            end
            obj.target = zeros(obj.dim, 1);

            if isfield(args, 'shift')
                obj.shift = zeros(obj.dim, 1);
            end

            abcds.util.log_msg("Shift data: shift=%s", mat2str(obj.shift));
        end

        function obj = select_dims(obj, dims_to_keep)
            arguments
                obj
                dims_to_keep
            end

            for i = 1:obj.num_traj
                obj.pos{i} = obj.pos{i}(dims_to_keep, :);
                obj.vel{i} = obj.vel{i}(dims_to_keep, :);
            end
            obj.target = obj.target(dims_to_keep, :);
            obj.shift = obj.shift(dims_to_keep, :);

            abcds.util.log_msg("Selected dims: %s", mat2str(dims_to_keep));
        end

        function res = x0_mean(obj)
            res = 0;
            for i = 1:obj.num_traj
                res = res + obj.pos{i}(:, 1);
            end
            res = res / obj.num_traj;
        end

        function plt_obj = plot_equilibrium(obj, dim1, dim2, plt_opts)
            arguments
                obj abcds.data.data
                dim1(1, 1) {mustBeInteger} = 1
                dim2(1, 1) {mustBeInteger} = 2
                plt_opts = {}
            end

            plt_obj = scatter(obj.target(dim1), obj.target(dim2), ...
                50, 'o', ...
                'markeredgecolor', abcds.util.constants.EQUILIBRIUM_COLOR, ...
                'markerfacecolor', abcds.util.constants.EQUILIBRIUM_COLOR, ...
                'linewidth', abcds.util.constants.LINEWIDTH, ...
                'displayname', '$' + abcds.util.constants.STATE_VAR_TEX + '^*$', plt_opts{:});
            hold on;
            axis equal;
        end

        function plt_obj = plot_pos(obj, dim1, dim2, plt_opts)
            arguments
                obj abcds.data.data
                dim1(1, 1) {mustBeInteger} = 1
                dim2(1, 1) {mustBeInteger} = 2
                plt_opts = {}
            end

            for i = 1:obj.num_traj
                plt_obj{i} = plot(obj.pos{i}(dim1, :), obj.pos{i}(dim2, :), ...
                    'color', abcds.util.constants.TRAJECTORY_COLOR_BG, ...
                    'linewidth', abcds.util.constants.LINEWIDTH, ...
                    'displayname', '$' + abcds.util.constants.STATE_VAR_TEX + '^{\mathrm{ref}}$', plt_opts{:});
                if i > 1
                    set(plt_obj{i}, 'handlevisibility', 'off');
                end
                hold on;
            end
            axis equal;
        end

        function plt_obj = plot_vel_quiver(obj, dim1, dim2, plt_opts)
            arguments
                obj abcds.data.data
                dim1(1, 1) {mustBeInteger} = 1
                dim2(1, 1) {mustBeInteger} = 2
                plt_opts = {}
            end

            for i = 1:obj.num_traj
                plt_obj{i} = quiver(obj.pos{i}(dim1, :), obj.pos{i}(dim2, :), obj.vel{i}(dim1, :), obj.vel{i}(dim2, :), ...
                    'color', 'black', ...
                    'linewidth', abcds.util.constants.LINEWIDTH_THIN, ...
                    'displayname', '$\dot{' + abcds.util.constants.STATE_VAR_TEX + '}^{\mathrm{ref}}$', ...
                    plt_opts{:});
                if i > 1
                    set(plt_obj{i}, 'handlevisibility', 'off');
                end
                hold on;
            end
            axis equal;
        end

        function plt_obj = plot_equilibrium3(obj, dim1, dim2, dim3, plt_opts)
            arguments
                obj abcds.data.data
                dim1(1, 1) {mustBeInteger} = 1
                dim2(1, 1) {mustBeInteger} = 2
                dim3(1, 1) {mustBeInteger} = 3
                plt_opts = {}
            end

            assert(obj.dim >= 3);
            plt_obj = scatter3(obj.target(dim1), obj.target(dim2), obj.target(dim3), ...
                10, 'o', ...
                'markeredgecolor', abcds.util.constants.EQUILIBRIUM_COLOR, ...
                'markerfacecolor', abcds.util.constants.EQUILIBRIUM_COLOR, ...
                'linewidth', abcds.util.constants.LINEWIDTH, ...
                'displayname', '$' + abcds.util.constants.STATE_VAR_TEX + '^*$', ...
                plt_opts{:});
            hold on;
            axis equal;
        end

        function plt_obj = plot_pos3(obj, dim1, dim2, dim3, plt_opts)
            arguments
                obj abcds.data.data
                dim1(1, 1) {mustBeInteger} = 1
                dim2(1, 1) {mustBeInteger} = 2
                dim3(1, 1) {mustBeInteger} = 3
                plt_opts = {}
            end

            assert(obj.dim >= 3);
            for i = 1:obj.num_traj
                plt_obj{i} = plot3(obj.pos{i}(dim1, :), obj.pos{i}(dim2, :), obj.pos{i}(dim3, :), ...
                    'color', abcds.util.constants.TRAJECTORY_COLOR_BG, ...
                    'linewidth', abcds.util.constants.LINEWIDTH, ...
                    'displayname', '$' + abcds.util.constants.STATE_VAR_TEX + '^{\mathrm{ref}}$', ...
                    plt_opts{:});
                if i > 1
                    set(plt_obj{i}, 'handlevisibility', 'off');
                end
                hold on;
            end
            axis equal;
        end

        function plt_obj = plot_pos_time(obj, dim1, plt_opts)
            arguments
                obj abcds.data.data
                dim1(1, 1) {mustBeInteger} = 1
                plt_opts = {}
            end

            for i = 1:obj.num_traj
                plt_obj{i} = plot(obj.tvec{i}, obj.pos{i}(dim1, :), ...
                    'color', abcds.util.constants.TRAJECTORY_COLOR_BG, ...
                    'linewidth', abcds.util.constants.LINEWIDTH, ...
                    'displayname', '$' + abcds.util.constants.STATE_VAR_TEX + '^{\mathrm{ref}}$', ...
                    plt_opts{:});
                if i > 1
                    set(plt_obj{i}, 'handlevisibility', 'off');
                end
                hold on;
            end
        end

        function plt_obj = plot_vel_time(obj, dim1, plt_opts)
            arguments
                obj abcds.data.data
                dim1(1, 1) {mustBeInteger} = 1
                plt_opts = {}
            end

            for i = 1:obj.num_traj
                plt_obj{i} = plot(obj.tvec{i}, obj.vel{i}(dim1, :), ...
                    'color', abcds.util.constants.TRAJECTORY_COLOR_BG, ...
                    'linewidth', abcds.util.constants.LINEWIDTH, ...
                    'displayname', '$\dot{' + abcds.util.constants.STATE_VAR_TEX + '}^{\mathrm{ref}}$', ...
                    plt_opts{:});
                if i > 1
                    set(plt_obj{i}, 'handlevisibility', 'off');
                end
                hold on;
            end
        end

        function s = to_struct(obj)
            s.pos = obj.pos;
            s.vel = obj.vel;
            s.tvec = obj.tvec;
            s.target = obj.target;
        end

        function str = string(obj)
            str = append("state_maxnorm=[", abcds.util.arr_to_str(obj.state_maxnorm), "]'");
            str = append(str, newline, "vel_maxnorm=[", abcds.util.arr_to_str(obj.vel_maxnorm), "]'");
            str = append(str, newline, "shift=[", abcds.util.arr_to_str(obj.shift), "]'");
        end
    end
end

%#ok<*AGROW>