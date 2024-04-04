% Copyright © 2024 Martin Schonger
% This software is licensed under the GPLv3.


classdef unity_rec < abcds.data.data
    properties
        data_path string
        num_samples_per_trajectory
    end

    methods
        function obj = unity_rec(data_path, args)
            arguments
                data_path string
                args.num_samples_per_trajectory = 100
            end

            abcds.util.log_msg("Initialize data from unity recording");

            config_json_raw = fileread(data_path);
            config = jsondecode(config_json_raw);
            input_fullpaths = regexp(config.trajectory_files, '\r\n|\r|\n', 'split');

            Data = [];
            indivTrajStartIndices = [1];
            timestamps = {};
            for i = 1:length(input_fullpaths)
                res_tmp = abcds.data.process_recorded_trajectory_unity(input_fullpaths{i});
                res_tmp = res_tmp';
                if args.num_samples_per_trajectory > 0
                    idx = 1:size(res_tmp, 2);
                    didx = linspace(min(idx), max(idx), args.num_samples_per_trajectory);
                    res = zeros(size(res_tmp, 1), args.num_samples_per_trajectory);
                    for j = 1:size(res_tmp, 1)
                        res(j, :) = interp1(idx, res_tmp(j, :), didx);
                    end
                else
                    res = res_tmp;
                end
            
                Data = [Data, [res(2:end, :)]];
                indivTrajStartIndices = [indivTrajStartIndices, 1 + size(Data, 2)];
                timestamps{end+1} = res(1, :);
            end
            
            M = size(Data, 1) / 2;
            Target = mean(Data(1:M, [indivTrajStartIndices(2:end) - 1]), 2);
            
            dim = size(Target, 1);
            pos = {};
            vel = {};
            tvec = {};
            for i = 1:length(indivTrajStartIndices) - 1
                pos{i} = Data(1:dim, indivTrajStartIndices(i):indivTrajStartIndices(i+1)-1);
                vel{i} = Data(dim+(1:dim), indivTrajStartIndices(i):indivTrajStartIndices(i+1)-1);
                tvec{i} = timestamps{i};
            end
            target = Target(1:dim);

            obj@abcds.data.data(pos = pos, vel = vel, tvec = tvec, target = target);
            % obj.shift_me();
            % obj.scale_me();
            warning("Check if need shifting/scaling");

            obj.data_path = data_path;
            obj.num_samples_per_trajectory = args.num_samples_per_trajectory;
        end

        function str = string(obj)
            str = string@abcds.data.data(obj);
            str = append(str, newline, "data_path=", strrep(obj.data_path, '\', '\\'));
            str = append(str, newline, "num_samples_per_trajectory=", num2str(obj.num_samples_per_trajectory));
        end
    end
end

%#ok<*AGROW>