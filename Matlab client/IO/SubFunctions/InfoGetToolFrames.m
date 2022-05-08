function [status, message, res] = InfoGetToolFrames(obj)
%INFOGETTOOLFRAMES Summary of this function goes here
%   Detailed explanation goes here
dataSize=IReceiveData(obj, 1, "int32");
res=struct([]);
for i=1:dataSize
    namesize=IReceiveData(obj, 1, "int32");
    name = IReceiveData(obj, namesize, "char");
    coords = IReceiveData(obj, 6, "double");
    res(end+1).name = string(name);
    res(end).coord=coords(1:3);
    res(end).orient=coords(4:6);
end
status=0;
message = "OK";
end

