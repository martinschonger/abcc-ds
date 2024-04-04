% Copyright © 2024 Martin Schonger
% This software is licensed under the GPLv3.


classdef robot_rec < abcds.data.data
    properties
        data_path string
        dims_to_keep
        num_samples_per_trajectory
        type string % "cartesian", "joint", "6d"
    end

    methods
        function obj = robot_rec(data_path, args, preprocess_args)
            arguments
                data_path string
                args.dims_to_keep = 1:2
                args.num_samples_per_trajectory = 100
                args.type string = "cartesian"
                preprocess_args.preprocess_args struct = struct()
            end

            abcds.util.log_msg("Initialize data from robot recording");

            exp_list_cellarr = fileread(data_path);
            exp_list_cellarr = regexp(exp_list_cellarr, '\r\n|\r|\n', 'split');
            preprocess_args.preprocess_args.type = args.type;
            [Data, Target, indivTrajStartIndices, timestamps] = abcds.data.recorded_trajectories_to_refdata(exp_list_cellarr, num_samples_per_trajectory=args.num_samples_per_trajectory, preprocess_args=preprocess_args.preprocess_args);
            dim = size(Target, 1);
            pos = {};
            vel = {};
            tvec = {};
            for i = 1:length(indivTrajStartIndices) - 1
                pos{i} = Data(args.dims_to_keep, indivTrajStartIndices(i):indivTrajStartIndices(i+1)-1);
                vel{i} = Data(dim+args.dims_to_keep, indivTrajStartIndices(i):indivTrajStartIndices(i+1)-1);
                tvec{i} = timestamps{i};
            end
            target = Target(args.dims_to_keep);

            obj@abcds.data.data(pos = pos, vel = vel, tvec = tvec, target = target);
            if ~strcmp(args.type, "6d")
                obj.shift_me();
                obj.scale_me(original_version=true);
            end

            obj.data_path = data_path;
            obj.dims_to_keep = args.dims_to_keep;
            obj.num_samples_per_trajectory = args.num_samples_per_trajectory;
            obj.type = args.type;
        end

        function str = string(obj)
            str = string@abcds.data.data(obj);
            str = append(str, newline, "data_path=", strrep(obj.data_path, '\', '\\'));
            str = append(str, newline, "dims_to_keep=[", abcds.util.arr_to_str(obj.dims_to_keep), "]");
            str = append(str, newline, "type=", string(obj.type));
        end
    end
end