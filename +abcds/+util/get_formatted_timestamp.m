% Copyright © 2024 Martin Schonger
% This software is licensed under the GPLv3.


function [timestamp_str, time] = get_formatted_timestamp(type)

arguments
    type = 'iso';
end

time_now = datetime('now', 'timezone', 'local');

switch type
    case 'iso'
        time = datetime(time_now, 'timezone', 'local', 'format', 'uuuu-MM-dd''T''HH:mm:ss'); % maybe change time_now to 'now'
    case 'isolong'
        time = datetime(time_now, 'timezone', 'local', 'format', 'uuuu-MM-dd''T''HH:mm:ss.SSS');
    case 'file'
        time = datetime(time_now, 'timezone', 'local', 'format', 'uuuuMMdd''T''HHmmssSSS');
    otherwise % just use 'iso'
        time = datetime(time_now, 'timezone', 'local', 'format', 'uuuu-MM-dd''T''HH:mm:ss');
end

timestamp_str = char(time);

end