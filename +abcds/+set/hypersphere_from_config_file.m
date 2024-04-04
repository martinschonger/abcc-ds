% Copyright © 2024 Martin Schonger
% This software is licensed under the GPLv3.


classdef hypersphere_from_config_file < abcds.set.hypersphere
    properties
        data_path
        obj_name
        include_orientation
        pass_selected_dims_to_hs
    end
    methods
        function obj = hypersphere_from_config_file(data_path, obj_name, args)
            arguments
                data_path
                obj_name
                args.radius
                args.include_orientation = false
                args.select_dims
                args.pass_selected_dims_to_hs = false
            end
            
            center = 0;
            radius = 0;

            config_json_raw = fileread(data_path);
            config = jsondecode(config_json_raw);
            config2_json_raw = fileread(config.config_file);
            config2 = jsondecode(config2_json_raw);
            for i = 1:length(config2.objs)
                if strcmp(config2.objs(i).name, obj_name)
                    if ~args.include_orientation
                        center = [config2.objs(i).position];
                    else
                        center = [config2.objs(i).position; config2.objs(i).eulerAngles];
                    end
                    radius = mean(config2.objs(i).scale) * 0.5;
                    break;
                end
            end
            
            center2 = center;
            if isfield(args, 'select_dims')
                center2 = center2(args.select_dims);
            end

            if isfield(args, 'radius')
                radius = args.radius;
            end

            if args.pass_selected_dims_to_hs
                select_dims_hs = args.select_dims;
                center2 = center;
            else
                select_dims_hs = 1:size(center2, 1);
            end
            obj@abcds.set.hypersphere(center2, radius, select_dims=select_dims_hs);
            obj.data_path = data_path;
            obj.obj_name = obj_name;
            obj.include_orientation = args.include_orientation;
            obj.pass_selected_dims_to_hs = args.pass_selected_dims_to_hs;
        end

        function str = string(obj)
            str = string@abcds.set.hypersphere(obj);
            str = append(str, newline, "data_path=", strrep(obj.data_path, '\', '\\'));
            str = append(str, newline, "obj_name=", string(obj.obj_name));
            str = append(str, newline, "include_orientation=", string(obj.include_orientation));
            str = append(str, newline, "pass_selected_dims_to_hs=", string(obj.pass_selected_dims_to_hs));
        end
    end
end