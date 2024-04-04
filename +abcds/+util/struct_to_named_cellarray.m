% Adapted from Stephen Vavasis' comment at https://www.mathworks.com/matlabcentral/answers/1895140-how-to-pass-keyword-arguments-to-a-function-via-a-struct#comment_2566225

function cellarr = struct_to_named_cellarray(s)
arguments
    s(1, 1) struct
end

field_names = fieldnames(s);
field_values = struct2cell(s);
num_fields = length(field_names);
cellarr = cell(2*num_fields, 1);
cellarr(1:2:end) = field_names;
cellarr(2:2:end) = field_values;

end