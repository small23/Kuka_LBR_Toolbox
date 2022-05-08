function SendDataJava(obj,cmd)
%SENDDATAJAVA Summary of this function goes here
%   Detailed explanation goes here
if ~isa(cmd, "uint8")
    if isa(cmd,"string")
        cmd=uint8(char(cmd));
    else
        ME = MException('socketIO:IOExeption', ...
            'Incorrect data type!');
        throw(ME)
    end
end
obj.lbr.out.write(cmd);
end

